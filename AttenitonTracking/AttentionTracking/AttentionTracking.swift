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

    typealias HelperDict = [Int: (Date, Date)]  // id and its first and last appearance dates

    static func getOutputsFromVisibleIds(
        _ visibleIds: [Int],
        // we can modify inout parameter inside the function
        helperDict: inout HelperDict,
        minimumViewingTime: TimeInterval,
        currentDate: Date = Date()
    ) -> [Output]? {
            // put visible ids into Set for O(1) reading complexity
            let visibleIdsSet = Set(visibleIds)

            // check what was in helper dict, but now disappeared
            let disappearedIdsAndDates: [(Int, (Date, Date))] = helperDict.filter {
                !visibleIdsSet.contains($0.key)
            }

            // creating array to store outputs
            var outputs: [Output] = []

            // creating outputs for disappeared ids
            for (id, dates) in disappearedIdsAndDates {
                // remove from the helperDict since it disappeared
                helperDict.removeValue(forKey: id)

                // finding difference betwen dates of first and last appearance
                let viewingTime = dates.1.timeIntervalSince(dates.0)

                // create Output only if we exceeded minimumViewingTime
                if viewingTime >= minimumViewingTime {
                    let output = Output(id: id, viewingTime: viewingTime)
                    outputs.append(output)
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

            // do not return empty array
            return outputs.isEmpty ? nil : outputs
        }
}
