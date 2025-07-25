//
//  TrackItemCollector.swift
//  AttentionTracking
//
//  Created by Evgenii Kononenko on 24.07.25.
//

import Foundation
import Combine

final class TrackItemCollector {
    let collectTime: TimeInterval

    // send all visible ids into this subject
    private let inputSubject: PassthroughSubject<[TrackItem], Never> = .init()
    // subject to receive collected track items
    private let outputSubject: PassthroughSubject<[TrackItem], Never> = .init()
    // storing our subscritions here
    private var cancellables: Set<AnyCancellable> = .init()

    init(collectTime: TimeInterval) {
        self.collectTime = collectTime

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        inputSubject
            // collecting all track items during collect time
            .collect(
                .byTime(DispatchQueue.main, .seconds(collectTime))
            )
            .map { arraysOfTrackItems in
                // we receive array of arrays after collecting.
                // To convert it to a single array, we flatten it
                arraysOfTrackItems.flatMap { $0 }
            }
            // subscribing on values
            .sink(receiveValue: { [weak self] collectedTrackItems in
                // sending each array to the output subject
                self?.outputSubject.send(collectedTrackItems)
            })
            .store(in: &cancellables)
    }

    // returning output from Combine subject as a Concurrency's async sequence
    var outputSequence: any AsyncSequence<[TrackItem], Never> {
        outputSubject.values
    }

    // main function to pass track items for collecting
    func collectTrackItems(_ trackItems: [TrackItem]) {
        guard !trackItems.isEmpty else {
            return
        }
        // sending track items to the visible ids subject
        inputSubject.send(trackItems)
    }
}
