//
//  VisibilityHelper.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//
import Foundation

enum VisibilityHelper {
//    static func findVisibleAndDisappearedIds(
//        idFrames: [Int : CGRect],
//        inParentBounds parentBounds: CGRect
//    ) -> (visibleIds: Set<Int>, disappearedIds: Set<Int>) {
//        var visibleIds: Set<Int> = .init()
//        var disappearedIds: Set<Int> = .init()
//        
//        for idFrame in idFrames {
//            let id = idFrame.key
//            let frame = idFrame.value
//            if isFrameVisible(frame, inParentBounds: parentBounds) {
//                visibleIds.insert(id)
//            } else if isFrameDisappeared(frame, inParentBounds: parentBounds) {
//                disappearedIds.insert(id)
//            }
//        }
//        print("Visible ids: \(visibleIds)\nDisappeared ids: \(disappearedIds)")
//        return (visibleIds, disappearedIds)
//    }
//
//    static func isFrameVisible(_ frame: CGRect, inParentBounds parentBounds: CGRect) -> Bool {
//        // consider only fully visible items in this example
//        frame.minY >= parentBounds.minY && frame.maxY <= parentBounds.maxY
//    }
//
//    static func isFrameDisappeared(_ frame: CGRect, inParentBounds parentBounds: CGRect) -> Bool {
//        // if we don't see it anymore, we consider it as disappeared
//        !frame.intersects(parentBounds)
//    }

    // Frames can be partially visible.
    // Small parts of other frames can be shown at top and at bottom.
    // We don't want to consider them as visible.
    // If it lays within its parent bounds for visibilityRate of its height - we consider it visible
    static func isFrameVisible(
        _ frame: CGRect,
        inParentBounds parentBounds: CGRect,
        visibilityRate: Double = 0.7
    ) -> Bool {
        guard frame.height > 0 else { return false }

        let intersectionTop = max(frame.minY, parentBounds.minY)
        let intersectionBottom = min(frame.maxY, parentBounds.maxY)

        let visibleHeight = max(0, intersectionBottom - intersectionTop)

        let visibility = visibleHeight / frame.height

        return visibility >= visibilityRate
    }
}
