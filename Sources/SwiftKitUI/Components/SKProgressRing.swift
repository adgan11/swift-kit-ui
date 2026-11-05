//
//  SKProgressRing.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A closed circular progress ring, determinate or indeterminate.
//
//  The indeterminate mode spins a fixed arc rather than animating `trim`
//  endpoints — rotating one layer is far cheaper than re-trimming a path 120
//  times a second, and it is the difference between a smooth ring and a
//  stuttering one on an older device.
//
//  Usage:
//      SKProgressRing(value: 0.4)
//      SKProgressRing()              // indeterminate
//

import SwiftUI

public struct SKProgressRing: View {
    private let value: Double?
    private let tint: Color
    private let lineWidth: CGFloat
    private let showsPercentage: Bool

    @State private var spin = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        value: Double? = nil,
        tint: Color = SK.Palette.accent,
        lineWidth: CGFloat = 8,
        showsPercentage: Bool = false
    ) {
        self.value = value
        self.tint = tint
        self.lineWidth = lineWidth
        self.showsPercentage = showsPercentage
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(SK.Palette.fill, lineWidth: lineWidth)

            if let value {
                Circle()
                    .trim(from: 0, to: min(max(value, 0), 1))
                    .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .skAnimation(.settle, value: value)

                if showsPercentage {
                    Text("\(Int(min(max(value, 0), 1) * 100))%")
                        .font(SK.Type_.numeric)
                        .foregroundStyle(SK.Palette.label)
                        .contentTransition(.numericText())
                        .skAnimation(.snap, value: value)
                }
            } else {
                Circle()
                    .trim(from: 0, to: 0.22)
                    .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                            spin = true
                        }
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(value == nil ? "Loading" : "Progress")
        .accessibilityValue(value.map { Text("\(Int($0 * 100)) percent") } ?? Text(""))
    }
}

#Preview("SKProgressRing") {
    @Previewable @State var progress = 0.35

    VStack(spacing: SK.Space.xl) {
        HStack(spacing: SK.Space.xl) {
            SKProgressRing(value: progress, showsPercentage: true).frame(width: 96)
            SKProgressRing(value: 0.8, tint: SK.Palette.success).frame(width: 64)
            SKProgressRing().frame(width: 44)
        }
        Slider(value: $progress, in: 0...1).tint(SK.Palette.accent)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
