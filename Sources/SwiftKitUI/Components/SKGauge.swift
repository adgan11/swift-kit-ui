//
//  SKGauge.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A 270° arc gauge. Speed, battery, score, storage.
//
//  Drawn with an explicit arc `Shape` rather than `Circle().trim()` rotated into
//  place. `trim` starts at 3 o'clock, so getting the opening to the bottom means
//  rotating the whole gauge — which rotates the label with it, and every caller
//  then has to counter-rotate their own content by the same magic number. An
//  arc that knows its own start angle keeps the label upright for free.
//
//  `animatableData` is on the shape, so the arc sweeps between values instead of
//  redrawing.
//
//  Usage:
//      SKGauge(value: 0.72) { Text("72%") }
//      SKGauge(value: cpu, in: 0...100, tint: .red) { Text("CPU") }
//

import SwiftUI

public struct SKGauge<Label: View>: View {
    private let value: Double
    private let range: ClosedRange<Double>
    private let tint: Color
    private let lineWidth: CGFloat
    private let showsTicks: Bool
    private let label: Label

    private let startDegrees: Double = 135
    private let sweepDegrees: Double = 270

    public init(
        value: Double,
        in range: ClosedRange<Double> = 0...1,
        tint: Color = SK.Palette.accent,
        lineWidth: CGFloat = 12,
        showsTicks: Bool = true,
        @ViewBuilder label: () -> Label
    ) {
        self.value = value
        self.range = range
        self.tint = tint
        self.lineWidth = lineWidth
        self.showsTicks = showsTicks
        self.label = label()
    }

    private var progress: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    public var body: some View {
        ZStack {
            if showsTicks { ticks }

            SKGaugeArc(progress: 1, startDegrees: startDegrees, sweepDegrees: sweepDegrees)
                .stroke(SK.Palette.fill, style: stroke)

            SKGaugeArc(progress: progress, startDegrees: startDegrees, sweepDegrees: sweepDegrees)
                .stroke(fill, style: stroke)

            label
        }
        // Inset by half the stroke so the rounded cap is not clipped by the frame.
        .padding(lineWidth / 2 + (showsTicks ? SK.Space.md : 0))
        .aspectRatio(1, contentMode: .fit)
        .skAnimation(.settle, value: value)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }

    private var stroke: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    /// Darker at the start, full tint at the end, so the sweep reads as filling
    /// rather than as a flat band.
    private var fill: AngularGradient {
        AngularGradient(
            colors: [tint.opacity(0.55), tint],
            center: .center,
            startAngle: .degrees(startDegrees),
            endAngle: .degrees(startDegrees + sweepDegrees)
        )
    }

    private var ticks: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2 + SK.Space.sm
            ForEach(0..<11, id: \.self) { i in
                let t = Double(i) / 10
                let angle = Angle.degrees(startDegrees + sweepDegrees * t)
                let passed = t <= progress + 0.001

                Capsule()
                    .fill(passed ? tint.opacity(0.7) : SK.Palette.separator)
                    .frame(width: 2, height: i % 5 == 0 ? 9 : 5)
                    .offset(y: -radius)
                    .rotationEffect(angle - .degrees(270))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}

extension SKGauge where Label == EmptyView {
    public init(value: Double, in range: ClosedRange<Double> = 0...1,
                tint: Color = SK.Palette.accent, lineWidth: CGFloat = 12,
                showsTicks: Bool = true) {
        self.init(value: value, in: range, tint: tint,
                  lineWidth: lineWidth, showsTicks: showsTicks) { EmptyView() }
    }
}

/// An arc that knows where it starts, so nothing above it needs rotating.
private struct SKGaugeArc: Shape {
    var progress: Double
    var startDegrees: Double
    var sweepDegrees: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(progress, 0), 1)
        guard clamped > 0 else { return Path() }
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(startDegrees),
            endAngle: .degrees(startDegrees + sweepDegrees * clamped),
            clockwise: false
        )
        return path
    }
}

#Preview("SKGauge") {
    @Previewable @State var value = 0.72

    VStack(spacing: SK.Space.xl) {
        SKGauge(value: value) {
            VStack(spacing: -2) {
                Text("\(Int(value * 100))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(SK.Palette.label)
                    .contentTransition(.numericText())
                Text("SCORE")
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelTertiary)
            }
        }
        .frame(width: 180)

        HStack(spacing: SK.Space.xl) {
            SKGauge(value: 0.35, tint: SK.Palette.success, lineWidth: 9, showsTicks: false)
                .frame(width: 84)
            SKGauge(value: 0.9, tint: SK.Palette.danger, lineWidth: 9, showsTicks: false)
                .frame(width: 84)
        }

        Slider(value: $value, in: 0...1).tint(SK.Palette.accent)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
