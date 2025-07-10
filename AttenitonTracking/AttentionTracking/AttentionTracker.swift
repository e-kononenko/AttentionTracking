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
        // send all visible ids into this subject
        private let visibleIdsSubject: PassthroughSubject<[Int], Never> = .init()
        // subject to receive output models
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
            // creating helperDict which we will use during the process
            var helperDict: HelperDict = .init()

            visibleIdsSubject
                .receive(on: queue) // receive event and continue on the serial queue
                .compactMap {
                    getOutputsFromVisibleIds($0, minimumViewingTime: Constants.minimumViewingTime, helperDict: &helperDict)
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
        func trackVisibleIds(_ visibleIds: [Int], date: Date = .init()) {
            guard !visibleIds.isEmpty else {
                return
            }
            visibleIdsSubject.send(visibleIds)
        }

        // returning output from Combine subject as a Concurrency's output sequence
        var outputSequence: any AsyncSequence<[Output], Never> {
            outputSubject.values
        }
    }
}
