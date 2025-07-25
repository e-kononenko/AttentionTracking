//
//  TrackItem.swift
//  AttentionTracking
//
//  Created by Evgenii Kononenko on 24.07.25.
//
import Foundation

struct TrackItem {
    let id: Int
    let viewingTime: TimeInterval // how long the id was viewed
}

extension TrackItem: CustomStringConvertible {
    var description: String {
        let viewingTimeString = String(format: "%.2f", viewingTime)
        return "Id \(id) was viewed for \(viewingTimeString) seconds"
    }
}
