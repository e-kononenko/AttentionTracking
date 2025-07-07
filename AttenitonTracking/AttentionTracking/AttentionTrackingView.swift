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

    @State private var attentionTracker: AttentionTracker = .init()

    @State private var resultText: String = ""

    var body: some View {
        Text("Test")
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

                print("parentFrame = \(parentFrame)")
                var aaa = 0
                aaa += 1
                
                Task {
                    for await outputModels in attentionTracker.outputSequence {
                        resultText = outputModels
                            .map { outputModel in
                                // simple formatting
                                let viewingTimeString = String(format: "%.2f", outputModel.viewingTime)
                                return "id \(outputModel.id): \(viewingTimeString)"
                            }
                            .joined(separator: "\n")
                    }
                }
            })
            .onPreferenceChange(
                ChildViewFramePreferenceKey.self,
                perform: { idFrames in
                    attentionTracker
                        .trackVisibleIds(Set(visibleIds))
                })
            .overlay(alignment: .top) {
                ResultView(resultText: resultText)
            }
        }
        .ignoresSafeArea()
    }
}

struct AttentionTrackingViewTest: View {
    @State private var items: [Item] = (0...100).map { Item(id: $0) }
    @State private var parentFrame: CGRect = .zero

    @State private var attentionTracker: AttentionTracker = .init()

    @State private var resultText: String = ""

    var body: some View {
        List {
            ForEach(items) { item in
                ItemView(item: item)
            }
        }
        .listStyle(.plain)
        .listRowSpacing(20)
        .ignoresSafeArea()
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

struct ResultView: View {
    let resultText: String
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.5)
                    .frame(height: 300)

                Text(resultText)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .padding(.leading, 20)
            }
        }
    }
}

#Preview {
    AttentionTrackingView()
}


#Preview {
    AttentionTrackingViewTest()
}
