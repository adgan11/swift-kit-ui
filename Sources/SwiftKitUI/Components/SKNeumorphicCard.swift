//
//  SKNeumorphicCard.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Soft UI: two shadows, one light from the top-left and one dark from the
//  bottom-right, so the surface appears extruded from its background.
//
//  Neumorphism only works when the card and its background are the SAME colour.
//  If they differ the illusion collapses, which is why `background:` is a
//  parameter here and not assumed — pass the colour the card is sitting on.
//
//  Usage:
//      SKNeumorphicCard { Text("Raised") }
//      SKNeumorphicCard(style: .pressed) { Text("Inset") }
//

import SwiftUI

public struct SKNeumorphicCard<Content: View>: View {
    public enum Style_: Sendable { case raised, pressed, flat }

    private let style: Style_
    private let background: Color
    private let radius: CGFloat
    private let padding: CGFloat
    private let content: Content

    public init(
        style: Style_ = .raised,
        background: Color = SK.Palette.surfaceSunken,
        radius: CGFloat = SK.Radius.xl,
        padding: CGFloat = SK.Space.xl,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.background = background
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    public var body: some View {
        content
            .padding(padding)
            .background { surface }
            .contentShape(shape)
    }

    @ViewBuilder
    private var surface: some View {
        switch style {
        case .raised:
            shape
                .fill(background)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 6, y: 6)
                .shadow(color: .white.opacity(0.65), radius: 10, x: -6, y: -6)
        case .pressed:
            // A true inner shadow needs a stroke blurred and clipped to the
            // shape — SwiftUI has no inset shadow primitive.
            shape
                .fill(background)
                .overlay {
                    shape
                        .stroke(Color.black.opacity(0.18), lineWidth: 5)
                        .blur(radius: 5)
                        .offset(x: 3, y: 3)
                        .mask(shape.fill(LinearGradient(
                            colors: [.black, .clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )))
                }
                .overlay {
                    shape
                        .stroke(Color.white.opacity(0.7), lineWidth: 5)
                        .blur(radius: 5)
                        .offset(x: -3, y: -3)
                        .mask(shape.fill(LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )))
                }
                .clipShape(shape)
        case .flat:
            shape.fill(background)
        }
    }
}

#Preview("SKNeumorphicCard") {
    let bg = SK.Palette.surfaceSunken

    return VStack(spacing: SK.Space.xxl) {
        SKNeumorphicCard(background: bg) {
            Text("Raised").font(SK.Type_.headline).foregroundStyle(SK.Palette.label)
        }
        SKNeumorphicCard(style: .pressed, background: bg) {
            Text("Pressed").font(SK.Type_.headline).foregroundStyle(SK.Palette.label)
        }
        HStack(spacing: SK.Space.lg) {
            ForEach(["play.fill", "pause.fill", "forward.fill"], id: \.self) { symbol in
                SKNeumorphicCard(background: bg, radius: SK.Radius.pill, padding: SK.Space.lg) {
                    Image(systemName: symbol)
                        .font(SK.Icon.symbol(SK.Icon.md))
                        .foregroundStyle(SK.Palette.accent)
                }
            }
        }
    }
    .padding(SK.Space.xxl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(bg)
}
