//
//  VisibilityHelper.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//
import Foundation

enum VisibilityHelper {
    static func isItemFrameVisible(
        _ frame: CGRect,
        inParentFrame parentFrame: CGRect,
        visibilityThreshold: Double = 1.0 // for partially visible items, e.g 0.7 - visible at 70%
    ) -> Bool {
        guard frame.height > 0 else { return false }

        let visibleHeight = frame.intersection(parentFrame).height
        let visibility = visibleHeight / frame.height

        return visibility >= visibilityThreshold
    }
}
