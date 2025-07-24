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
        // send all visible ids into this subject
        private let inputSubject: PassthroughSubject<[Int], Never> = .init()
        // subject to receive output models
        private let outputSubject: PassthroughSubject<[Output], Never> = .init()
        // storing our subscritions here
        private var cancellables: Set<AnyCancellable> = .init()

        private enum Constants {
            static let minimumViewingTime = 2.0
            static let collectTime = 10.0
        }

        init() {
            setupSubscriptions()
        }

        private func setupSubscriptions() {
            // creating helperDict which will be used during the process
            var helperDict: HelperDict = .init()

            inputSubject
                // convert visible ids to outputs and filter nil results
                .compactMap {
                    let outputs = getOutputsFromVisibleIds(
                        $0,
                        helperDict: &helperDict,
                        minimumViewingTime: Constants.minimumViewingTime
                    )
                    return outputs.isEmpty ? nil : outputs
                }
                // collecting outputs to send them in batches
                .collect(
                    .byTime(DispatchQueue.main, .seconds(Constants.collectTime))
                )
                .map { allOutputs in
                    // we receive array of arrays of outputs after collecting.
                    // To convert it to a single array, we flatten it
                    allOutputs.flatMap { $0 }
                }
                // subscribing on values
                .sink(receiveValue: { [weak self] outputs in
                    // sending each array of outputs to the output subject
                    self?.outputSubject.send(outputs)
                })
                .store(in: &cancellables)
        }

        // MARK: - Internal
        func trackVisibleIds(_ visibleIds: [Int]) {
            guard !visibleIds.isEmpty else {
                return
            }
            // sending ids to the visible ids subject
            inputSubject.send(visibleIds)
        }

        // returning output from Combine subject as a Concurrency's output sequence
        var outputSequence: any AsyncSequence<[Output], Never> {
            outputSubject.values
        }
    }
}
