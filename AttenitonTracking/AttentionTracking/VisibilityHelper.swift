//
//  VisibilityHelper.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//
import Foundation

enum VisibilityHelper {
    static func isChildVisible(
        childFrame: CGRect,
        inParentFrame parentFrame: CGRect,
        // for partially visible items, e.g 0.7 - visible at 70%
        visibilityThreshold: Double = 1.0
    ) -> Bool {
        guard childFrame.height > 0 else { return false }
        // find intersection frame and take its height
        let visibleHeight = childFrame.intersection(parentFrame).height

        // what part of a child is visible
        let visibility = visibleHeight / childFrame.height

        // consider visible if it exceeds the threshold
        return visibility >= visibilityThreshold
    }
}
