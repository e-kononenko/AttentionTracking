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
        visibleIds: [Int],
        minimumViewingTime: TimeInterval,
        visibilityDate: Date = Date(),
        helperDict: inout HelperDict) -> [Output]? {
            // put visible ids into set for O(1) read complexity
            let visibleIdsSet = Set(visibleIds)

            // check what was in helper dict, but now disappeared
            let disappearedIdsAndDates: [(Int, (Date, Date))] = helperDict.filter {
                !visibleIdsSet.contains($0.key)
            }

            var outputs: [Output] = []

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

            // processing new visible ids and updating helperDict with the new elements
            for id in visibleIdsSet {
                if let dates = helperDict[id] {
                    // we have already seen this id before - we update the last seen date
                    helperDict[id] = (dates.0, visibilityDate)
                } else {
                    // for new ids first and last seen dates are equal
                    helperDict[id] = (visibilityDate, visibilityDate)
                }
            }

            return outputs.isEmpty ? nil : outputs  // proceed only if there are outputs
        }
}
