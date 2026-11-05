//
//  SKTokenMeter.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Usage against a quota, shown before it becomes a problem.
//
//  The bar changes colour at 70% and again at 90%, which is the entire point:
//  a meter that is the same colour at 20% and 99% is decoration. Those two
//  thresholds are also where the copy changes and where the upgrade action
//  appears — a prompt to upgrade at 15% is an advert, the same prompt at 92%
//  is help.
//
//  The fill animates on `.glide` rather than snapping, because a quota moving
//  visibly is how someone learns that what they just did was expensive.
//
//  Usage:
//      SKTokenMeter(used: 18_420, limit: 25_000)
//      SKTokenMeter(used: used, limit: limit, style: .compact, onUpgrade: upgrade)
//

import SwiftUI

public struct SKTokenMeter: View {
    public enum Style: Sendable { case card, compact }

    private let used: Int
    private let limit: Int
    private let unit: String
    private let style: Style
    private let onUpgrade: (() -> Void)?

    public init(
        used: Int,
        limit: Int,
        unit: String = "tokens",
        style: Style = .card,
        onUpgrade: (() -> Void)? = nil
    ) {
        self.used = used
        self.limit = limit
        self.unit = unit
        self.style = style
        self.onUpgrade = onUpgrade
    }

    private var fraction: Double {
        guard limit > 0 else { return 0 }
        return min(1, max(0, Double(used) / Double(limit)))
    }

    private var tint: Color {
        switch fraction {
        case ..<0.7: SK.Palette.accent
        case ..<0.9: SK.Palette.warning
        default: SK.Palette.danger
        }
    }

    private var remaining: Int { max(0, limit - used) }

    public var body: some View {
        switch style {
        case .compact: compact
        case .card: card
        }
    }

    // MARK: Bar

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(SK.Palette.fill)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .frame(height: 6)
        .skAnimation(.glide, value: fraction)
        .accessibilityHidden(true)
    }

    // MARK: Styles

    private var compact: some View {
        VStack(alignment: .leading, spacing: SK.Space.xs) {
            HStack(spacing: SK.Space.xs) {
                Text("\(short(used)) / \(short(limit))")
                    .font(SK.Type_.caption)
                    .monospacedDigit()
                    .foregroundStyle(SK.Palette.labelSecondary)
                Spacer(minLength: 0)
                Text("\(Int(fraction * 100))%")
                    .font(SK.Type_.caption)
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }
            bar
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(short(used)) of \(short(limit)) \(unit) used")
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: SK.Space.md) {
            HStack(alignment: .firstTextBaseline, spacing: SK.Space.sm) {
                Text(short(used))
                    .font(SK.Type_.title)
                    .monospacedDigit()
                    .foregroundStyle(SK.Palette.label)
                Text("of \(short(limit)) \(unit)")
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelTertiary)
                Spacer(minLength: 0)
                if fraction >= 0.7 {
                    Image(systemName: fraction >= 0.9 ? "exclamationmark.triangle.fill" : "clock.fill")
                        .font(SK.Icon.symbol(SK.Icon.sm))
                        .foregroundStyle(tint)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            bar

            HStack(spacing: SK.Space.sm) {
                Text(message)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                // Only offered once it is useful. Below 70% this is an advert.
                if let onUpgrade, fraction >= 0.7 {
                    Button("Upgrade") {
                        onUpgrade()
                        SK.Haptic.play(.light)
                    }
                    .font(SK.Type_.caption)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, SK.Space.md)
                    .padding(.vertical, SK.Space.xs + 1)
                    .background(tint, in: Capsule())
                    .buttonStyle(.skPress(scale: 0.94, haptic: nil))
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(SK.Space.lg)
        .background(SK.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous)
                .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
        }
        .skAnimation(.snap, value: fraction >= 0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(short(used)) of \(short(limit)) \(unit) used. \(message)")
    }

    private var message: String {
        switch fraction {
        case ..<0.7: "\(short(remaining)) \(unit) left this month."
        case ..<0.9: "You are using these faster than usual."
        case ..<1: "Almost out — \(short(remaining)) \(unit) left."
        default: "Limit reached. Usage resets on the 1st."
        }
    }

    /// 18,420 -> "18.4K". Long numbers in a tight row push the layout around
    /// and nobody reads the last three digits of a quota anyway.
    private func short(_ value: Int) -> String {
        func trim(_ text: String) -> String {
            text.hasSuffix(".0") ? String(text.dropLast(2)) : text
        }
        if value >= 1_000_000 { return trim(String(format: "%.1f", Double(value) / 1_000_000)) + "M" }
        if value >= 1_000 { return trim(String(format: "%.1f", Double(value) / 1_000)) + "K" }
        return "\(value)"
    }
}

#Preview("SKTokenMeter") {
    @Previewable @State var used = 4_200

    VStack(spacing: SK.Space.lg) {
        SKTokenMeter(used: used, limit: 25_000, onUpgrade: {})
        SKTokenMeter(used: used, limit: 25_000, style: .compact)

        Button("Spend 6K") { used = min(25_000, used + 6_000) }
            .font(SK.Type_.callout)
            .foregroundStyle(SK.Palette.accent)
            .buttonStyle(.skPress)
    }
    .padding(SK.Space.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SK.Palette.surface)
}
