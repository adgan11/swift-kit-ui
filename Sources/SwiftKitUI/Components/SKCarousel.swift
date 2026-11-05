//
//  SKCarousel.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A snapping card carousel. Off-centre cards shrink and dim as they move away,
//  which gives the row depth and makes the focused card unambiguous.
//
//  The depth effect uses `.scrollTransition`, so it is driven by real scroll
//  position every frame rather than by a selected index — the cards respond
//  continuously while your finger is still down.
//
//  Usage:
//      SKCarousel(items: photos) { photo in PhotoCard(photo) }
//

import SwiftUI

public struct SKCarousel<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let cardWidth: CGFloat
    private let height: CGFloat
    private let content: (Item) -> Content

    @State private var current: Item.ID?

    public init(
        items: [Item],
        cardWidth: CGFloat = 260,
        height: CGFloat = 320,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.cardWidth = cardWidth
        self.height = height
        self.content = content
    }

    public var body: some View {
        VStack(spacing: SK.Space.lg) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SK.Space.lg) {
                    ForEach(items) { item in
                        content(item)
                            .frame(width: cardWidth, height: height)
                            .scrollTransition(axis: .horizontal) { view, phase in
                                view
                                    .scaleEffect(phase.isIdentity ? 1 : 0.88)
                                    .opacity(phase.isIdentity ? 1 : 0.55)
                                    .rotation3DEffect(
                                        .degrees(phase.value * -8),
                                        axis: (x: 0, y: 1, z: 0),
                                        perspective: 0.5
                                    )
                            }
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, SK.Space.xl)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $current, anchor: .center)

            indicator
        }
        .onAppear { current = items.first?.id }
        .onChange(of: current) { _, _ in SK.Haptic.play(.light) }
    }

    private var indicator: some View {
        HStack(spacing: SK.Space.xs) {
            ForEach(items) { item in
                let active = item.id == current
                Capsule()
                    .fill(active ? SK.Palette.accent : SK.Palette.separator)
                    .frame(width: active ? 20 : 6, height: 6)
                    .skAnimation(.snap, value: current)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DemoCard: Identifiable {
    let id: Int
    let title: String
    let tint: Color
}

#Preview("SKCarousel") {
    let cards = [
        DemoCard(id: 0, title: "Components", tint: .purple),
        DemoCard(id: 1, title: "Animations", tint: .blue),
        DemoCard(id: 2, title: "Screens", tint: .teal),
        DemoCard(id: 3, title: "Liquid Glass", tint: .indigo),
    ]

    return SKCarousel(items: cards) { card in
        VStack(alignment: .leading) {
            Spacer()
            Text(card.title)
                .font(SK.Type_.title)
                .foregroundStyle(.white)
        }
        .padding(SK.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(colors: [card.tint, card.tint.opacity(0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipShape(RoundedRectangle(cornerRadius: SK.Radius.xl, style: .continuous))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
