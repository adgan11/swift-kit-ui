//
//  SKIconBubble.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A tinted container for an SF Symbol. The thing every settings row, feature
//  list and empty state reinvents slightly differently.
//
//  Usage:
//      SKIconBubble("star.fill")
//      SKIconBubble("trash.fill", tone: .danger)
//      SKIconBubble("bolt.fill", tone: .accent, shape: .circle, size: SK.Icon.xl)
//

import SwiftUI

public struct SKIconBubble: View {
    public enum Tone: Sendable {
        case neutral, accent, success, warning, danger

        var foreground: Color {
            switch self {
            case .neutral: SK.Palette.labelSecondary
            case .accent: SK.Palette.accent
            case .success: SK.Palette.success
            case .warning: SK.Palette.warning
            case .danger: SK.Palette.danger
            }
        }

        var background: Color {
            switch self {
            case .neutral: SK.Palette.fill
            case .accent: SK.Palette.accentSoft
            case .success: SK.Palette.successSoft
            case .warning: SK.Palette.warningSoft
            case .danger: SK.Palette.dangerSoft
            }
        }
    }

    public enum Shape_: Sendable { case rounded, circle }

    private let systemImage: String
    private let tone: Tone
    private let shape: Shape_
    private let size: CGFloat

    public init(
        _ systemImage: String,
        tone: Tone = .accent,
        shape: Shape_ = .rounded,
        size: CGFloat = SK.Icon.md
    ) {
        self.systemImage = systemImage
        self.tone = tone
        self.shape = shape
        self.size = size
    }

    /// The container scales with the glyph so bubbles stay optically balanced
    /// at any size instead of needing a second hard-coded number.
    private var box: CGFloat { size * 2.1 }

    public var body: some View {
        Image(systemName: systemImage)
            .font(SK.Icon.symbol(size))
            .foregroundStyle(tone.foreground)
            .frame(width: box, height: box)
            .background {
                switch shape {
                case .rounded:
                    RoundedRectangle(cornerRadius: box * 0.28, style: .continuous)
                        .fill(tone.background)
                case .circle:
                    Circle().fill(tone.background)
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview("SKIconBubble") {
    VStack(spacing: SK.Space.xl) {
        HStack(spacing: SK.Space.md) {
            SKIconBubble("star.fill")
            SKIconBubble("checkmark", tone: .success)
            SKIconBubble("exclamationmark.triangle.fill", tone: .warning)
            SKIconBubble("trash.fill", tone: .danger)
            SKIconBubble("gear", tone: .neutral)
        }
        HStack(spacing: SK.Space.md) {
            SKIconBubble("bolt.fill", shape: .circle, size: SK.Icon.sm)
            SKIconBubble("bolt.fill", shape: .circle, size: SK.Icon.md)
            SKIconBubble("bolt.fill", shape: .circle, size: SK.Icon.lg)
            SKIconBubble("bolt.fill", shape: .circle, size: SK.Icon.xl)
        }
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
