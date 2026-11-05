//
//  SKActivityIndicator.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Three loading indicators that are not the system spinner: bouncing dots,
//  a pulsing arc, and equaliser bars.
//
//  Each loops via `.repeatForever` keyed on a single `onAppear` flag, and each
//  stops dead under Reduce Motion, showing a static state instead — an infinite
//  animation is exactly what that setting exists to stop.
//
//  NOT `phaseAnimator(_:trigger:)`. That overload runs the phases ONCE per
//  trigger change; with a trigger that never changes it plays once and freezes.
//  Looks correct in a static screenshot, dead on device.
//
//  Usage:
//      SKActivityIndicator()
//      SKActivityIndicator(style: .bars, tint: .white)
//

import SwiftUI

public struct SKActivityIndicator: View {
    public enum Style: Sendable, CaseIterable { case dots, arc, bars }

    private let style: Style
    private let tint: Color
    private let size: CGFloat

    @State private var animating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(style: Style = .dots, tint: Color = SK.Palette.accent, size: CGFloat = 40) {
        self.style = style
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Group {
            switch style {
            case .dots: dots
            case .arc: arc
            case .bars: bars
            }
        }
        .frame(width: size, height: size)
        .onAppear { animating = true }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private func loop(_ duration: Double, delay: Double = 0, autoreverses: Bool = true) -> Animation? {
        guard !reduceMotion else { return nil }
        return .easeInOut(duration: duration)
            .repeatForever(autoreverses: autoreverses)
            .delay(delay)
    }

    // MARK: dots

    private var dots: some View {
        HStack(spacing: size * 0.13) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(tint)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .offset(y: animating && !reduceMotion ? -size * 0.2 : size * 0.06)
                    .opacity(animating && !reduceMotion ? 1 : 0.4)
                    // Staggered so they ripple rather than pulse in unison.
                    .animation(loop(0.44, delay: Double(index) * 0.13), value: animating)
            }
        }
    }

    // MARK: arc

    private var arc: some View {
        Circle()
            .trim(from: 0, to: 0.26)
            .stroke(tint, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
            .rotationEffect(.degrees(animating && !reduceMotion ? 360 : 0))
            .animation(
                reduceMotion ? nil
                    : .linear(duration: 0.85).repeatForever(autoreverses: false),
                value: animating
            )
    }

    // MARK: bars

    private var bars: some View {
        HStack(spacing: size * 0.1) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(tint)
                    .frame(width: size * 0.15, height: size * 0.8)
                    .scaleEffect(y: animating && !reduceMotion ? 1 : 0.32, anchor: .center)
                    .animation(loop(0.42, delay: Double(index) * 0.1), value: animating)
            }
        }
    }
}

#Preview("SKActivityIndicator") {
    VStack(spacing: SK.Space.xxl) {
        HStack(spacing: SK.Space.xxl) {
            SKActivityIndicator(style: .dots)
            SKActivityIndicator(style: .arc)
            SKActivityIndicator(style: .bars)
        }
        HStack(spacing: SK.Space.xl) {
            SKActivityIndicator(style: .dots, tint: SK.Palette.success, size: 28)
            SKActivityIndicator(style: .arc, tint: SK.Palette.danger, size: 56)
        }
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
