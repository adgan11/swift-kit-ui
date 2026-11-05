//
//  SKSlider.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A slider that grows under your thumb and ticks haptically as it crosses
//  steps. The track thickens on contact — the same trick that makes the system
//  volume slider feel physical.
//
//  Usage:
//      SKSlider(value: $volume, in: 0...1)
//      SKSlider(value: $rating, in: 0...10, step: 1) { Text("Rating") }
//

import SwiftUI

public struct SKSlider<Label: View>: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let label: Label

    @State private var isDragging = false
    @State private var lastTick: Double?
    @Environment(\.isEnabled) private var isEnabled

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label()
    }

    private var progress: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    private var trackHeight: CGFloat { isDragging ? 14 : 10 }

    public var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            label
            GeometryReader { geo in
                track(width: geo.size.width)
                    .frame(height: SK.Icon.hitTarget)
                    .contentShape(.rect)
                    .gesture(drag(width: geo.size.width))
            }
            .frame(height: SK.Icon.hitTarget)
        }
        .opacity(isEnabled ? 1 : 0.45)
        .skAnimation(.micro, value: isDragging)
        .accessibilityElement()
        .accessibilityValue(Text(String(format: "%.2f", value)))
        .accessibilityAdjustableAction { direction in
            let delta = step ?? (range.upperBound - range.lowerBound) / 20
            switch direction {
            case .increment: value = min(value + delta, range.upperBound)
            case .decrement: value = max(value - delta, range.lowerBound)
            @unknown default: break
            }
        }
    }

    private func track(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Capsule().fill(SK.Palette.fill)
                .frame(height: trackHeight)
            Capsule().fill(SK.Palette.accent)
                .frame(width: max(trackHeight, width * progress), height: trackHeight)
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.22), radius: 4, y: 2)
                .frame(width: isDragging ? 30 : 26, height: isDragging ? 30 : 26)
                .offset(x: (width - 26) * progress)
        }
        .frame(maxHeight: .infinity)
    }

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                isDragging = true
                let span = range.upperBound - range.lowerBound
                let raw = range.lowerBound + Double(min(max(g.location.x / width, 0), 1)) * span
                let next = step.map { (raw / $0).rounded() * $0 } ?? raw
                let clamped = min(max(next, range.lowerBound), range.upperBound)

                // Tick only when a step boundary is actually crossed, otherwise
                // a continuous drag would fire haptics every frame.
                if step != nil, clamped != lastTick {
                    SK.Haptic.play(.light)
                    lastTick = clamped
                }
                value = clamped
            }
            .onEnded { _ in
                isDragging = false
                lastTick = nil
            }
    }
}

extension SKSlider where Label == EmptyView {
    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double? = nil) {
        self.init(value: value, in: range, step: step) { EmptyView() }
    }
}

#Preview("SKSlider") {
    @Previewable @State var volume = 0.4
    @Previewable @State var rating = 6.0

    VStack(spacing: SK.Space.xl) {
        SKSlider(value: $volume) {
            Text("Volume").font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
        }
        SKSlider(value: $rating, in: 0...10, step: 1) {
            Text("Steps of 1 — feel the ticks")
                .font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
        }
        SKSlider(value: .constant(0.6)).disabled(true)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
