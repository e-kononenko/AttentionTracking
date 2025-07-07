//
//  AttentionTracking.swift
//  AttentionTracking
//
//  Created by Evgenii Kononenko on 07.07.25.
//
import Foundation

enum AttentionTracking {
    struct Output {
        let id: Int
        let viewingTime: TimeInterval // how long the id was visible
    }

    // ids visible at a specific time
    struct Batch {
        let visibleIds: Set<Int>
        let date: Date
    }

    typealias HelperDict = [Int: (Date, Date)]  // id and its first and last date of appearance in batches
    
    static func processBatch(
        batch: Batch,
        minimumViewingTime: TimeInterval,
        outputs: inout [Output],
        helperDict: inout HelperDict
    ) {
        // check what was in helper dict, but now disappeared
        let disappearedIdsAndDates: [(Int, (Date, Date))] = helperDict.filter {
            !batch.visibleIds.contains($0.key)
        }

        for (id, dates) in disappearedIdsAndDates {
            helperDict.removeValue(forKey: id)  // remove from the helperDict since it disappeared

            let viewingTime = dates.1.timeIntervalSince(dates.0) // finding difference betwen dates of first and last appearance

            // create Output only if we exceeded minimumViewingTime
            if viewingTime >= minimumViewingTime {
                let outputItem: Output = .init(
                    id: id,
                    viewingTime: viewingTime
                )
                outputs.append(outputItem)
            }
        }

        // processing new batch and updating helperDict with the new elements
        for id in batch.visibleIds {
            if let dates = helperDict[id] {
                // we have already seen this id before - we update the last seen date
                helperDict[id] = (dates.0, batch.date)
            } else {
                // for new ids first and last seen dates are equal
                helperDict[id] = (batch.date, batch.date)
            }
        }
    }
}
