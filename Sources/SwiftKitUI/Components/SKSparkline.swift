//
//  SKSparkline.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A compact trend line for cards and rows — no axes, no legend, no chart
//  framework. Optional gradient fill and a highlighted last point.
//
//  Built on `Shape`, so it animates between datasets: the path interpolates
//  when the values change instead of snapping to the new shape.
//
//  Usage:
//      SKSparkline(values: [3, 5, 4, 8, 7, 11])
//      SKSparkline(values: revenue, tint: .green, showsFill: true)
//

import SwiftUI

public struct SKSparkline: View {
    private let values: [Double]
    private let tint: Color
    private let showsFill: Bool
    private let showsLastPoint: Bool
    private let lineWidth: CGFloat

    public init(
        values: [Double],
        tint: Color = SK.Palette.accent,
        showsFill: Bool = true,
        showsLastPoint: Bool = true,
        lineWidth: CGFloat = 2
    ) {
        self.values = values
        self.tint = tint
        self.showsFill = showsFill
        self.showsLastPoint = showsLastPoint
        self.lineWidth = lineWidth
    }

    public var body: some View {
        GeometryReader { geo in
            let points = normalized(in: geo.size)
            ZStack {
                if showsFill {
                    SparkPath(points: points, closed: true)
                        .fill(LinearGradient(
                            colors: [tint.opacity(0.28), tint.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        ))
                }
                SparkPath(points: points, closed: false)
                    .stroke(tint, style: StrokeStyle(lineWidth: lineWidth,
                                                     lineCap: .round, lineJoin: .round))
                if showsLastPoint, let last = points.last {
                    Circle()
                        .fill(tint)
                        .frame(width: lineWidth * 3, height: lineWidth * 3)
                        .position(last)
                }
            }
        }
        .skAnimation(.settle, value: values)
        .accessibilityElement()
        .accessibilityLabel("Trend")
        .accessibilityValue(trendDescription)
    }

    private func normalized(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let lo = values.min() ?? 0
        let hi = values.max() ?? 1
        let span = hi - lo
        let inset = lineWidth * 1.5

        return values.enumerated().map { index, value in
            let x = size.width * Double(index) / Double(values.count - 1)
            // A flat series sits on the midline rather than dividing by zero.
            let ratio = span == 0 ? 0.5 : (value - lo) / span
            let y = inset + (size.height - inset * 2) * (1 - ratio)
            return CGPoint(x: x, y: y)
        }
    }

    private var trendDescription: String {
        guard let first = values.first, let last = values.last, first != 0 else { return "No data" }
        let change = (last - first) / abs(first) * 100
        return "\(change >= 0 ? "Up" : "Down") \(abs(Int(change))) percent"
    }
}

private struct SparkPath: Shape {
    var points: [CGPoint]
    var closed: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        if closed {
            path.addLine(to: CGPoint(x: points.last?.x ?? rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

#Preview("SKSparkline") {
    @Previewable @State var data: [Double] = [3, 5, 4, 8, 6, 11, 9, 14]

    VStack(spacing: SK.Space.lg) {
        HStack(spacing: SK.Space.lg) {
            VStack(alignment: .leading, spacing: SK.Space.xs) {
                Text("Revenue").font(SK.Type_.caption).foregroundStyle(SK.Palette.labelSecondary)
                Text("$4,280").font(SK.Type_.title).foregroundStyle(SK.Palette.label)
                SKSparkline(values: data, tint: SK.Palette.success).frame(height: 40)
            }
            .padding(SK.Space.lg)
            .skSurface(.bordered, radius: SK.Radius.lg)

            VStack(alignment: .leading, spacing: SK.Space.xs) {
                Text("Churn").font(SK.Type_.caption).foregroundStyle(SK.Palette.labelSecondary)
                Text("2.1%").font(SK.Type_.title).foregroundStyle(SK.Palette.label)
                SKSparkline(values: data.reversed(), tint: SK.Palette.danger).frame(height: 40)
            }
            .padding(SK.Space.lg)
            .skSurface(.bordered, radius: SK.Radius.lg)
        }

        SKSparkline(values: data, showsFill: false, lineWidth: 3).frame(height: 80)

        Button("Shuffle") { data = (0..<8).map { _ in Double.random(in: 1...15) } }
            .font(SK.Type_.callout).foregroundStyle(SK.Palette.accent)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
