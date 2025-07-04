//
//  AttentionTrackingView.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//

import SwiftUI

struct Item: Identifiable {
    let id: Int
}

// Define a custom PreferenceKey to track frames of child views
struct ChildViewFramePreferenceKey: PreferenceKey {

    // Default value is an empty dictionary, where keys are Int (IDs) and values are CGRect (frames of child views)
    static var defaultValue: [Int: CGRect] = [:]

    // Merging values from multiple child views into the main value
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        // Merging the current value with the new value
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/*
struct ItemView: View {
    let items: [Item] = (0..<100).map { Item(id: $0) }

    var body: some View {
        List {
            ForEach(items) { item in
                Text("Item \(item.id)")
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .background(Color.mint)
                    .listRowInsets(.init())
            }
        }
        .listStyle(.plain)
        .listRowSpacing(20)
        .ignoresSafeArea()
    }
}
*/

struct AttentionTrackingView: View {
    @State var items: [Item] = (0...100).map { Item(id: $0) }
    @State var attentionTracker: AttentionTracker = .init()

    var body: some View {
        GeometryReader { parentGeometry in
            List {
                ForEach(items) { item in
                    Text("Item \(item.id)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .background(Color.mint)
                        .listRowInsets(.init())
                        .overlay {
                            GeometryReader { childGeometry in
                                Color.clear
                                    .preference(
                                        key: ChildViewFramePreferenceKey.self,
                                        value: [item.id: childGeometry.frame(in: .global)]
                                    )
                            }
                        }
                }
            }
            .listStyle(.plain)
            .listRowSpacing(20)
            .ignoresSafeArea()
            .onPreferenceChange(
                ChildViewFramePreferenceKey.self,
                perform: { childFrames in
                    let parentBounds = parentGeometry.frame(in: .global)

                    let visibleIds = childFrames
                        .compactMap { (id, frame) -> Int? in
                            return frame.intersects(parentBounds) ? id : nil
                        }

                    attentionTracker.trackIds(visibleIds)
                })
            .listRowSpacing(20)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AttentionTrackingView()
}

//#Preview {
//    ItemView()
//}
