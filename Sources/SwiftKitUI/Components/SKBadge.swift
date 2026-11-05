//
//  SKBadge.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A small status pill.
//
//  Tones resolve to real tinted colours from the palette rather than
//  `.opacity()` on a solid — opacity composites against whatever is behind it,
//  so the same badge drifts in appearance from screen to screen.
//
//  Usage:
//      SKBadge("New")
//      SKBadge("Pro", tone: .accent)
//      SKBadge("3", tone: .danger, shape: .circle)
//

import SwiftUI

public struct SKBadge: View {
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

    public enum Shape_: Sendable { case capsule, circle }

    private let text: String
    private let tone: Tone
    private let shape: Shape_
    private let systemImage: String?

    public init(_ text: String, tone: Tone = .neutral, shape: Shape_ = .capsule, systemImage: String? = nil) {
        self.text = text
        self.tone = tone
        self.shape = shape
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: SK.Space.xxs) {
            if let systemImage {
                Image(systemName: systemImage).font(SK.Icon.symbol(SK.Icon.xs))
            }
            Text(text)
        }
        .font(SK.Type_.caption)
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, shape == .circle ? SK.Space.xs : SK.Space.sm)
        .padding(.vertical, SK.Space.xxs)
        .frame(minWidth: shape == .circle ? 22 : nil)
        .background(Capsule().fill(tone.background))
        .accessibilityElement(children: .combine)
    }
}

#Preview("SKBadge") {
    VStack(spacing: SK.Space.lg) {
        HStack(spacing: SK.Space.sm) {
            SKBadge("Neutral")
            SKBadge("Accent", tone: .accent)
            SKBadge("Success", tone: .success, systemImage: "checkmark")
        }
        HStack(spacing: SK.Space.sm) {
            SKBadge("Warning", tone: .warning, systemImage: "exclamationmark.triangle.fill")
            SKBadge("Danger", tone: .danger)
            SKBadge("3", tone: .danger, shape: .circle)
        }
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
