////
////  AttentionTracker2.swift
////  AttentionTracking
////
////  Created by Evgenii Kononenko on 06.07.25.
////

//
//  AttentionTracker.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//

import Foundation
import Combine

final class AttentionTracker2 {
    struct OutputModel {
        let id: Int
        let viewingTime: TimeInterval // how long the id was visible
    }

    // ids visible at a specific time
    private struct Batch {
        let visibleIds: Set<Int>
        let date: Date
    }

    private typealias HelperDict = [Int: (Date, Date)]  // id and its first and last date of appearance in batches

    private enum Constants {
        static let collectTime = 20.0
        static let minimumViewingTime = 4.0
        static let throttleTime = 0.3
    }

    private let queue = DispatchQueue(label: "attention tracking")  // serial queue where we will process our data
    private let batchSubject: PassthroughSubject<Batch, Never> = .init()
    private let outputSubject: PassthroughSubject<[OutputModel], Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()

    init() {
        setupSubscriptions()
    }

    // MARK: - Private
    private func setupSubscriptions() {
        var helperDict: HelperDict = .init()

        batchSubject
            .receive(on: queue) // receive on the serial queue, the further work will be done in background
            .compactMap { batch -> [OutputModel]? in
                var outputModels: [OutputModel] = .init()
                // processing new batch, the result will be in
                Self.processBatch(
                    batch: batch,
                    outputs: &outputModels,
                    helperDict: &helperDict
                )
                return outputModels.isEmpty ? nil : outputModels
            }
            .collect(.byTime(queue, .seconds(Constants.collectTime))) // collecting outputs to send them in batches
            .map { outputs in
                // since we receive array of arrays after collecting, we flatten it into a single array
                outputs.flatMap { $0 }
            }
            .receive(on: DispatchQueue.main)    // go back to the main queue
            .sink(receiveValue: { [weak self] outputs in
                self?.outputSubject.send(outputs)
            })
            .store(in: &cancellables)
    }
    
    private static func processBatch(
        batch: Batch,
        outputs: inout [OutputModel],
        helperDict: inout HelperDict
    ) {
        // check what disappeared from the helper dict (not in the batch)
        let disappearedIdsAndDates: [(Int, (Date, Date))] = helperDict.filter {
            !batch.visibleIds.contains($0.key)
        }

        for (id, dates) in disappearedIdsAndDates {
            // remove from the helperDict since it disappeared
            helperDict.removeValue(forKey: id)

            // viewing time is the difference betwen dates of first and last appearance
            let viewingTime = dates.1.timeIntervalSince(dates.0)

            if viewingTime >= Constants.minimumViewingTime {
                // create an Output
                let outputItem: OutputModel = .init(
                    id: id,
                    viewingTime: viewingTime
                )
                outputs.append(outputItem)
            }
        }

        // processing new batch and updating helperDict with the new elements
        for id in batch.visibleIds {
            if let dates = helperDict[id] {
                // if we have already seen this id before - we update the last seen date
                helperDict[id] = (dates.0, batch.date)
            } else {
                // for new ids first and last seen dates are equal
                helperDict[id] = (batch.date, batch.date)
            }
        }
    }

    func track(visibleIds: Set<Int>, date: Date = .init()) {
        guard !visibleIds.isEmpty else {
            return
        }
        let batch: Batch = .init(visibleIds: visibleIds, date: date)
        batchSubject.send(batch)
    }

    // returning output from Combine subject as a Concurrency's output sequence
    var outputSequence: any AsyncSequence<[OutputModel], Never> {
        outputSubject.values
    }
}
