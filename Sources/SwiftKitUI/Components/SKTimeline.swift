//
//  SKTimeline.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A vertical timeline: order status, activity feeds, onboarding progress.
//
//  The connector between two steps is drawn by the step above it and stops at
//  the row's bottom edge, so the line never overshoots past the final node —
//  the giveaway of a hand-rolled timeline.
//
//  Usage:
//      SKTimeline(steps: [
//          .init(title: "Ordered", subtitle: "Mon", state: .done),
//          .init(title: "Shipped", state: .current),
//          .init(title: "Delivered", state: .upcoming),
//      ])
//

import SwiftUI

public struct SKTimelineStep: Identifiable {
    public enum State_: Sendable { case done, current, upcoming, failed }

    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let state: State_

    public init(title: String, subtitle: String? = nil, state: State_ = .upcoming) {
        self.title = title
        self.subtitle = subtitle
        self.state = state
    }

    var tint: Color {
        switch state {
        case .done: SK.Palette.success
        case .current: SK.Palette.accent
        case .upcoming: SK.Palette.separator
        case .failed: SK.Palette.danger
        }
    }

    var symbol: String? {
        switch state {
        case .done: "checkmark"
        case .failed: "xmark"
        case .current, .upcoming: nil
        }
    }
}

public struct SKTimeline: View {
    private let steps: [SKTimelineStep]
    private let nodeSize: CGFloat = 26

    public init(steps: [SKTimelineStep]) { self.steps = steps }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                row(step, isLast: index == steps.count - 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func row(_ step: SKTimelineStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: SK.Space.md) {
            VStack(spacing: 0) {
                node(step)
                if !isLast {
                    Rectangle()
                        .fill(step.state == .done ? SK.Palette.success : SK.Palette.separator)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: nodeSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(SK.Type_.headline)
                    .foregroundStyle(step.state == .upcoming ? SK.Palette.labelTertiary : SK.Palette.label)
                if let subtitle = step.subtitle {
                    Text(subtitle)
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelSecondary)
                }
            }
            .padding(.bottom, isLast ? 0 : SK.Space.xl)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private func node(_ step: SKTimelineStep) -> some View {
        ZStack {
            Circle()
                .fill(step.state == .upcoming ? SK.Palette.surface : step.tint)
                .frame(width: nodeSize, height: nodeSize)
            Circle()
                .strokeBorder(step.tint, lineWidth: 2)
                .frame(width: nodeSize, height: nodeSize)

            if let symbol = step.symbol {
                Image(systemName: symbol)
                    .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                    .foregroundStyle(.white)
            } else if step.state == .current {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview("SKTimeline") {
    SKTimeline(steps: [
        .init(title: "Order placed", subtitle: "Monday, 9:14", state: .done),
        .init(title: "Payment confirmed", subtitle: "Monday, 9:15", state: .done),
        .init(title: "Out for delivery", subtitle: "Arriving today", state: .current),
        .init(title: "Delivered", state: .upcoming),
    ])
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SK.Palette.surfaceSunken)
}
