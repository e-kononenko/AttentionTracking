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

    private enum Constants {
        static let throttleTime = 0.5
        static let collectTime = 6.0
        static let minimumViewingTime = 2.0
    }

    private typealias HelperDict = [Int: Date]  // id and when it appeared first time

    private let queue = DispatchQueue(label: "attention tracking")  // serial queue where we will process our data
    private let batchSubject: PassthroughSubject<Batch, Never> = .init()
    private let outputSubject: PassthroughSubject<[Output], Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()

    init() {
        setupSubscriptions()
    }

    // MARK: - Private
    private func setupSubscriptions() {
        var helperDict: HelperDict = .init()

        batchSubject
        // slowing down to not have too many values
            .throttle(
                for: .seconds(Constants.throttleTime),
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
            .collect(.byTime(queue, .seconds(Constants.collectTime))) // collecting outputs to send them in batches
            .compactMap { outputs in
                // since we receive array of arrays after collecting, we flatten it
                let flattenedOutputs = outputs.flatMap {
                    // filter if viewing time was too short
                    $0.filter { $0.viewingTime > Constants.minimumViewingTime }
                }
                return !flattenedOutputs.isEmpty ? flattenedOutputs : nil
            }
            .subscribe(outputSubject)   // send the result into outputSubject
            .store(in: &cancellables)
    }

    private func processNewBatch(_ batch: Batch, outputs: inout [Output], helperDict: inout HelperDict) {
        // check ids that disappeared from the helper dict
        let disappearedIds = helperDict.keys.filter {
            !batch.ids.contains($0)
        }

        // if we found something that disappeared - create an Output and remove from helperDict
        for disappearedId in disappearedIds {
            guard let dateOfAppearance = helperDict[disappearedId] else {
                continue
            }

            //calculate viewingTime as the difference between first and last dates
            let viewingTime = batch.date.timeIntervalSince(dateOfAppearance)
            let outputItem: Output = .init(
                id: disappearedId,
                viewingTime: viewingTime
            )
            outputs.append(outputItem)
            helperDict.removeValue(forKey: disappearedId)
        }

        // now processing batch ids and see what's new
        for id in batch.ids {
            //if we haven't met this id before, we add it to helperDict
            if helperDict[id] == nil {
                helperDict[id] = batch.date
            }
        }
    }

    // MARK: - Internal
    func trackIdFrames(
        _ idFrames: [Int: CGRect],
        parentBounds: CGRect,
        date: Date = .init()
    ) {
        // check only ids that are visible within their parent's bounds
        let visibleIds = idFrames
            .compactMap { (id, frame) in
                let isVisible = VisibilityHelper.isFrameVisible(
                    frame,
                    inParentBounds: parentBounds
                )

                return isVisible ? id : nil
            }

        if !visibleIds.isEmpty {
            let batch = Batch(ids: Set(visibleIds), date: date)
            batchSubject.send(batch)
        }
    }

    var outputPublisher: AnyPublisher<[Output], Never> {
        outputSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
