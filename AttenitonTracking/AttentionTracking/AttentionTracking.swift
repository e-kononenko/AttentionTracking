//
//  AttentionTracking.swift
//  AttentionTracking
//
//  Created by Evgenii Kononenko on 07.07.25.
//
import Foundation

enum AttentionTracking {
    static func getTrackItemsFromVisibleIds(
        _ visibleIds: [Int],
        // we can modify inout parameter inside the function
        helperDict: inout [Int: (Date, Date)],
        minimumViewingTime: TimeInterval,
        currentDate: Date = Date()
    ) -> [TrackItem] {
        // put visible ids into Set for O(1) reading complexity
        let visibleIdsSet = Set(visibleIds)

        // check what was in helper dict, but now disappeared
        let disappearedIdsAndDates: [(Int, (Date, Date))] = helperDict.filter {
            !visibleIdsSet.contains($0.key)
        }

        // creating array to store track items
        var trackItems: [TrackItem] = []

        // creating track items for disappeared ids
        for (id, dates) in disappearedIdsAndDates {
            // remove from the helperDict since it disappeared
            helperDict.removeValue(forKey: id)

            // finding difference betwen dates of first and last appearance
            let viewingTime = dates.1.timeIntervalSince(dates.0)

            // create track item only if we exceeded minimumViewingTime
            if viewingTime >= minimumViewingTime {
                let trackItem = TrackItem(id: id, viewingTime: viewingTime)
                trackItems.append(trackItem)
            }
        }

        // processing new visible ids and updating helperDict with the new elements
        for id in visibleIdsSet {
            if let dates = helperDict[id] {
                // we have already seen this id before - we update the last seen date
                helperDict[id] = (dates.0, currentDate)
            } else {
                // for new ids first and last seen dates are equal
                helperDict[id] = (currentDate, currentDate)
            }
        }
        
        return trackItems
    }
}
