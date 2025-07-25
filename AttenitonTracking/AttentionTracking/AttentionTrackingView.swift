//
//  AttentionTrackingView.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//

import SwiftUI

// collecting ids and frames from multiple child views
struct ItemFramePreferenceKey: PreferenceKey {
    // dictionary that accumulates multiple pairs of id and frame
    static var defaultValue: [Int: CGRect] = [:]

    // processing next value - merging it with the accumulator
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct AttentionTrackingView: View {
    private enum Constants {
        static let visibilityThreshold: CGFloat = 0.7
        static let minimumViewingTime: TimeInterval = 2.0
        static let collectTime: TimeInterval = 10.0
    }

    @State private var items: [Item] = (0...100).map { Item(id: $0) }
    @State private var resultText: String = ""
    // ids and dates when they were visible for the first and last time
    @State private var helperDict = [Int: (Date, Date)]()

    @State private var trackItemCollector = TrackItemCollector(
        collectTime: Constants.collectTime
    )

    var body: some View {
        GeometryReader { parentGeometry in
            List {
                ForEach(items) { item in
                    ItemView(item: item)
                }
            }
            .listStyle(.plain)
            .listRowSpacing(20)
            .ignoresSafeArea()
            .onAppear(perform: {
                Task {
                    for await trackItems in trackItemCollector.outputSequence {
                        resultText = trackItems
                            .map { String(describing: $0) }
                            .joined(separator: "\n")
                    }
                }
            })
            .onPreferenceChange(ItemFramePreferenceKey.self, perform: { idFrames in
                // finding parent frame
                let parentFrame = parentGeometry.frame(in: .global)

                // mapping [Int : CGRect] dictionary into [Int] array of visible ids
                let visibleIds: [Int] = idFrames.compactMap { keyValue in
                    return VisibilityHelper.isChildVisible(
                        childFrame: keyValue.value,
                        inParentFrame: parentFrame,
                        visibilityThreshold: Constants.visibilityThreshold
                    ) ? keyValue.key : nil
                }

                let trackItems = AttentionTracking.getTrackItemsFromVisibleIds(
                    visibleIds,
                    helperDict: &helperDict,
                    minimumViewingTime: Constants.minimumViewingTime
                )

                trackItemCollector.collectTrackItems(trackItems)
            })
            .overlay(alignment: .top) {
                ResultView(resultText: resultText)
            }
        }
    }
}

struct ItemView: View {
    let item: Item
    var body: some View {
        Text("Item \(item.id)")
            .frame(maxWidth: .infinity)
            .frame(height: 600)
            .background(Color.mint)
            .listRowInsets(.init())
            .overlay {
                GeometryReader { geometry in
                    Color.clear
                    // Setting value for the preference key
                        .preference(
                            key: ItemFramePreferenceKey.self,
                            // Getting frame in global coordinates and pair it with the id
                            value: [item.id: geometry.frame(in: .global)]
                        )
                }
            }
    }
}

struct ResultView: View {
    let resultText: String
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.5)
                    .frame(height: 250)

                Text(resultText)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 60)
                    .padding(.leading, 20)
            }
            .ignoresSafeArea()
        }
        // let the gestures pass through
        .allowsHitTesting(false)
    }
}

#Preview {
    AttentionTrackingView()
}
