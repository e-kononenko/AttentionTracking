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
        visibilityThreshold: Double = 1.0 // for partially visible items (1.0 - fully visible, 0.5 - visible at 50%)
    ) -> Bool {
        guard frame.height > 0 else { return false }

        let intersectionTop = max(frame.minY, parentFrame.minY)
        let intersectionBottom = min(frame.maxY, parentFrame.maxY)

        let visibleHeight = max(0, intersectionBottom - intersectionTop)

        let visibility = visibleHeight / frame.height

        return visibility >= visibilityThreshold
    }
}
