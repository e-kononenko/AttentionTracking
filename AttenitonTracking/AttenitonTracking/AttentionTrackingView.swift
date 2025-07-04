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

// using PreferenceKey to report child frames
struct ChildViewFramePreferenceKey: PreferenceKey {
    // empty dictionary, key is id, value is a child frame
    static var defaultValue: [Int: CGRect] = [:]

    // merging frames of from multiple views together
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct AttentionTrackingView: View {
    @State private var items: [Item] = (0...100).map { Item(id: $0) }
    @State private var parentBounds: CGRect = .zero

    @State private var attentionTracker: AttentionTracker = .init()
    @State private var attentionOutputs: [AttentionTracker.Output] = .init()

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
                parentBounds = parentGeometry.frame(in: .global)
            })
            .onPreferenceChange(
                ChildViewFramePreferenceKey.self,
                perform: { childFrames in
                    let visibleIds = childFrames
                        .compactMap { (id, frame) -> Int? in
                            return frame.intersects(parentBounds) ? id : nil
                        }

                    attentionTracker.trackIds(visibleIds)
                })
            .onReceive(attentionTracker.outputPublisher, perform: { outputs in
                self.attentionOutputs = outputs
            })
            .overlay {
                let outputText = attentionOutputs
                    .map { output in
                        let viewingTimeString = String(format: "%.2f", output.viewingTime)

                        return "id \(output.id): \(viewingTimeString)"
                    }
                    .joined(separator: "\n")
                let resultText = "Result:\n\(outputText)"

                ResultView(resultText: resultText)
            }
        }
        .ignoresSafeArea()
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


struct ItemView: View {
    let item: Item
    var body: some View {
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

struct ResultView: View {
    let resultText: String
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.5)
                    .frame(height: 200)

                Text(resultText)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .padding(.leading, 20)
            }
            Spacer()
        }
    }
}

#Preview {
    AttentionTrackingView()
}

//#Preview {
//    ItemView()
//}
