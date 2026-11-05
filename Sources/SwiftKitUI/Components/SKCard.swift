//
//  SKCard.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A container with the kit's standard internal padding.
//
//  This exists because "just use .skSurface" was not enough: every screen then
//  picks its own padding and the cards drift apart by 2-4pt until nothing lines
//  up. One card, one padding scale, everywhere.
//
//  Usage:
//      SKCard { Text("Hello") }
//      SKCard(style: .elevated) { ... }
//      SKCard(style: .liquidGlass) { ... } onTap: { open() }
//

import SwiftUI

public struct SKCard<Content: View>: View {
    private let style: SK.Surface
    private let radius: CGFloat
    private let padding: CGFloat
    private let onTap: (() -> Void)?
    private let content: Content

    public init(
        style: SK.Surface = .bordered,
        radius: CGFloat = SK.Radius.lg,
        padding: CGFloat = SK.Space.lg,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.radius = radius
        self.padding = padding
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        if let onTap {
            // A real Button, not .onTapGesture — this is what gets VoiceOver,
            // keyboard focus and pointer hover for free.
            Button(action: onTap) { surface }
                .buttonStyle(.skPress)
        } else {
            surface
        }
    }

    private var surface: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skSurface(style, radius: radius)
            .contentShape(.rect)
    }
}

#Preview("SKCard") {
    ScrollView {
        VStack(spacing: SK.Space.lg) {
            SKCard {
                VStack(alignment: .leading, spacing: SK.Space.xs) {
                    Text("Bordered").font(SK.Type_.headline)
                    Text("The default. Quiet enough to stack.")
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelSecondary)
                }
            }
            SKCard(style: .elevated) {
                Text("Elevated").font(SK.Type_.headline)
            }
            SKCard(style: .liquidGlass) {
                Text("Liquid Glass").font(SK.Type_.headline)
            }
            SKCard(style: .elevated, onTap: {}) {
                Text("Tappable — press me").font(SK.Type_.headline)
            }
        }
        .padding(SK.Space.lg)
    }
    .background(SK.Palette.surfaceSunken)
}
