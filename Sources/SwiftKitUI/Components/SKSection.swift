//
//  SKSection.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A titled group. Pair with SKRow, or put anything else inside.
//
//  Deliberately generic over its content rather than taking a row array: a
//  section should not know what a row is. That keeps this file compilable on
//  its own, which is the rule every component in this kit follows.
//
//  Usage:
//      SKSection("Preferences") {
//          SKRow(title: "Wi-Fi")
//          SKRow(title: "Bluetooth", showsSeparator: false)
//      }
//

import SwiftUI

public struct SKSection<Content: View>: View {
    private let title: String?
    private let footer: String?
    private let style: SK.Surface
    private let content: Content

    public init(
        _ title: String? = nil,
        footer: String? = nil,
        style: SK.Surface = .bordered,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.style = style
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            if let title {
                Text(title.uppercased())
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .padding(.leading, SK.Space.xs)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: 0) { content }
                .skSurface(style, radius: SK.Radius.lg)
                // Clip so a trailing row separator cannot escape the corner
                // radius and draw a stray line across the card's rounded edge.
                .clipShape(RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous))

            if let footer {
                Text(footer)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelTertiary)
                    .padding(.leading, SK.Space.xs)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("SKSection") {
    // Rows here are inlined rather than using SKRow: a component's preview must
    // not reference a sibling, or the file stops compiling on its own.
    // `scripts/isolation_test.py` enforces this.
    func demoRow(_ title: String, _ symbol: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: SK.Space.md) {
                Image(systemName: symbol)
                    .font(SK.Icon.symbol(SK.Icon.md))
                    .foregroundStyle(SK.Palette.accent)
                    .frame(width: SK.Icon.lg)
                Text(title).font(SK.Type_.body).foregroundStyle(SK.Palette.label)
                Spacer()
            }
            .padding(.horizontal, SK.Space.lg)
            .padding(.vertical, SK.Space.md)
            .frame(minHeight: SK.Icon.hitTarget)

            if !last {
                Rectangle()
                    .fill(SK.Palette.separator)
                    .frame(height: SK.Stroke.hairline)
                    .padding(.leading, SK.Space.lg + SK.Icon.lg + SK.Space.md)
            }
        }
    }

    return ScrollView {
        VStack(spacing: SK.Space.xl) {
            SKSection("Preferences") {
                demoRow("Wi-Fi", "wifi")
                demoRow("Bluetooth", "dot.radiowaves.right", last: true)
            }
            SKSection("Danger Zone", footer: "This cannot be undone.") {
                demoRow("Delete Account", "trash.fill", last: true)
            }
        }
        .padding(SK.Space.lg)
    }
    .background(SK.Palette.surfaceSunken)
}
