//
//  AttentionTracker.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//

import Combine
import Foundation

final class AttentionTracker {
    struct Output {
        let id: Int
        let viewingTime: TimeInterval // how long the id was visible
    }

    private struct Batch {
        let ids: Set<Int>
        let date: Date
    }

    private typealias HelperDict = [Int: (Date, Date)]  // dates that represent when we met this id first and last time

    private let queue = DispatchQueue(label: "attention tracking")  // serial queue where we will process our data
    private let throttleTime = 0.5
    private let collectTime = 3.0
    private let batchSubject: PassthroughSubject<Batch, Never> = .init()
    private let outputSubject: PassthroughSubject<[Output], Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()

    var outputPublisher: AnyPublisher<[Output], Never> {
        outputSubject.eraseToAnyPublisher()
    }

    init() {
        setupSubscriptions()
    }

    private func processNewBatch(_ batch: Batch, outputs: inout [Output], helperDict: inout HelperDict) {
        print("We are on thread \(Thread.current)")
        // check ids that disappeared from the helper dict
        let disappearedIds = helperDict.keys.filter {
            !batch.ids.contains($0)
        }

        // if we found something that disappeared - create an Output and remove from helperDict
        for disappearedId in disappearedIds {
            guard let dates = helperDict[disappearedId] else {
                continue
            }

            //calculate viewingTime as the difference between first and last dates
            let viewingTime = dates.1.timeIntervalSince(dates.0)
            let outputItem: Output = .init(
                id: disappearedId,
                viewingTime: viewingTime
            )
            outputs.append(outputItem)
            helperDict.removeValue(forKey: disappearedId)
        }

        // now processing new ids: see what's new, and what we have already met
        for id in batch.ids {
            if let dates = helperDict[id] {
                // we met this id before, and we are meeting it now - we should update last met date
                helperDict[id] = (dates.0, batch.date)
            } else {
                // if it is a new id, then just put equal dates to the dictionary
                helperDict[id] = (batch.date, batch.date)
            }
        }
    }

    private func setupSubscriptions() {
        var helperDict: HelperDict = .init()

        batchSubject
        // slowing down to not have too many values
            .throttle(
                for: .seconds(throttleTime),
                scheduler: queue,
                latest: true
            )
            .compactMap { [weak self] batch in
                var outputs: [Output] = .init()
                self?.processNewBatch(
                    batch,
                    outputs: &outputs,
                    helperDict: &helperDict
                )
                return outputs
            }
            .collect(.byTime(queue, .seconds(collectTime))) // collecting outputs to send them by batching
            .map { outputs in
                // since we receive array of arrays after collecting, we flatten it
                outputs.flatMap { $0 }
            }
            .receive(on: DispatchQueue.main)
            .subscribe(outputSubject)   // send the result into outputSubject
            .store(in: &cancellables)
    }

    func trackIds(
        _ ids: [Int],
        date: Date = Date()
    ) {
        if !ids.isEmpty {
            let batch = Batch(ids: Set(ids), date: date)
            batchSubject.send(batch)
        }
    }
}
