//
//  VisibilityHelper.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//
import Foundation

enum VisibilityHelper {
    // Frames can be partially visible.
    // Small parts of other frames can be shown at top and at bottom.
    // We don't want to consider them as visible.
    // If it lays within its parent bounds for visibilityRate of its height - we consider it visible
    static func isFrameVisible(
        _ frame: CGRect,
        inParentFrame parentFrame: CGRect,
        visibilityRate: Double = 0.7
    ) -> Bool {
        guard frame.height > 0 else { return false }

        let intersectionTop = max(frame.minY, parentFrame.minY)
        let intersectionBottom = min(frame.maxY, parentFrame.maxY)

        let visibleHeight = max(0, intersectionBottom - intersectionTop)

        let visibility = visibleHeight / frame.height

        return visibility >= visibilityRate
    }
}
