//
//  AttentionTracker.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//

import Combine
import Foundation

extension AttentionTracking {
    final class Tracker {
        private let queue = DispatchQueue(label: "attention tracking")  // serial queue where we will process our data
        // send all batches into this subject
        private let batchSubject: PassthroughSubject<Batch, Never> = .init()
        // send all batches into this subject
        private let outputSubject: PassthroughSubject<[Output], Never> = .init()
        private var cancellables: Set<AnyCancellable> = .init()

        enum Constants {
            static let minimumViewingTime = 5.0
            static let collectTime = 30.0
        }

        init() {
            setupSubscriptions()
        }

        private func setupSubscriptions() {
            // creating helperDict which we will update with new batches
            var helperDict: HelperDict = .init()

            batchSubject
                .receive(on: queue) // receive event and continue on the serial queue
                .compactMap { batch -> [Output]? in
                    var outputs: [Output] = .init()
                    // processing new batch, the result will be in outputs array
                    processBatch(
                        batch: batch,
                        minimumViewingTime: Constants.minimumViewingTime,
                        outputs: &outputs,
                        helperDict: &helperDict
                    )
                    return outputs.isEmpty ? nil : outputs  // proceed only if there are outputs
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

        // MARK: - Internal
        func trackVisibleIds(_ visibleIds: Set<Int>, date: Date = .init()) {
            guard !visibleIds.isEmpty else {
                return
            }
            let batch: Batch = .init(visibleIds: visibleIds, date: date)
            batchSubject.send(batch)
        }

        // returning output from Combine subject as a Concurrency's output sequence
        var outputSequence: any AsyncSequence<[Output], Never> {
            outputSubject.values
        }
    }
}
