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
    @State private var items: [Item] = (0...100).map { Item(id: $0) }
    @State private var parentFrame: CGRect = .zero

    @State private var attentionTracker: AttentionTracking.Tracker = .init()

    @State private var resultText: String = ""

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
                parentFrame = parentGeometry.frame(in: .global)

                Task {
                    for await outputModels in attentionTracker.outputSequence {
                        resultText = outputModels
                            .map { outputModel in
                                // simple formatting
                                let viewingTimeString = String(format: "%.2f", outputModel.viewingTime)
                                return "\(outputModel.id):\(viewingTimeString)"
                            }
                            .joined(separator: ", ")
                    }
                }
            })
            .onPreferenceChange(
                ItemFramePreferenceKey.self,
                perform: { idFrames in
                    let visibleIds = idFrames.compactMap { keyValue in
                        return VisibilityHelper
                            .isChildVisible(
                                childFrame: keyValue.value,
                                inParentFrame: parentFrame,
                                visibilityThreshold: 0.7
                            ) ? keyValue.key : nil

                    }
                    attentionTracker
                        .trackVisibleIds(visibleIds)
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
            .frame(height: 500)
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
