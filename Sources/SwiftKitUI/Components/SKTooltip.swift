//
//  SKTooltip.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A pointed bubble anchored to whatever it is explaining. For onboarding
//  coach-marks and "what does this do?" hints.
//
//  The arrow is part of the bubble's `Shape`, not a rotated square behind it.
//  A rotated square shows a seam wherever the bubble is translucent and gets
//  clipped wrong at the corners; one path has neither problem.
//
//  Usage:
//      Button("?") { show.toggle() }
//          .skTooltip(isPresented: $show, edge: .top) { Text("Tap to refresh") }
//

import SwiftUI

public struct SKTooltipShape: Shape {
    public var arrowEdge: Edge
    public var cornerRadius: CGFloat = SK.Radius.md
    public var arrowWidth: CGFloat = 16
    public var arrowHeight: CGFloat = 8

    public init(arrowEdge: Edge) { self.arrowEdge = arrowEdge }

    public func path(in rect: CGRect) -> Path {
        var body = rect
        switch arrowEdge {
        case .top: body.origin.y += arrowHeight; body.size.height -= arrowHeight
        case .bottom: body.size.height -= arrowHeight
        case .leading: body.origin.x += arrowHeight; body.size.width -= arrowHeight
        case .trailing: body.size.width -= arrowHeight
        }

        var path = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)
        var arrow = Path()
        switch arrowEdge {
        case .top:
            let x = body.midX
            arrow.move(to: CGPoint(x: x - arrowWidth / 2, y: body.minY))
            arrow.addLine(to: CGPoint(x: x, y: rect.minY))
            arrow.addLine(to: CGPoint(x: x + arrowWidth / 2, y: body.minY))
        case .bottom:
            let x = body.midX
            arrow.move(to: CGPoint(x: x - arrowWidth / 2, y: body.maxY))
            arrow.addLine(to: CGPoint(x: x, y: rect.maxY))
            arrow.addLine(to: CGPoint(x: x + arrowWidth / 2, y: body.maxY))
        case .leading:
            let y = body.midY
            arrow.move(to: CGPoint(x: body.minX, y: y - arrowWidth / 2))
            arrow.addLine(to: CGPoint(x: rect.minX, y: y))
            arrow.addLine(to: CGPoint(x: body.minX, y: y + arrowWidth / 2))
        case .trailing:
            let y = body.midY
            arrow.move(to: CGPoint(x: body.maxX, y: y - arrowWidth / 2))
            arrow.addLine(to: CGPoint(x: rect.maxX, y: y))
            arrow.addLine(to: CGPoint(x: body.maxX, y: y + arrowWidth / 2))
        }
        arrow.closeSubpath()
        path.addPath(arrow)
        return path
    }
}

/// Positioning maths, kept out of the generic modifier.
///
/// An `alignmentGuide` closure inside a type generic over the tip's View would
/// capture `Tip.Type`, which Swift 6 flags as a non-Sendable capture in an
/// isolated closure. Pulling the logic into a non-generic enum means the
/// closure captures only an `Edge`.
private enum SKTooltipGeometry {
    static func overlayAlignment(for edge: Edge) -> Alignment {
        switch edge {
        case .top: .top          // arrow on top -> bubble sits ABOVE the anchor
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    /// Pushes the bubble fully outside the anchor instead of overlapping it.
    static func verticalGuide(for edge: Edge, _ d: ViewDimensions) -> CGFloat {
        switch edge {
        case .top: d[.bottom]
        case .bottom: d[.top]
        default: d[VerticalAlignment.center]
        }
    }

    static func offset(for edge: Edge) -> CGSize {
        switch edge {
        case .top: CGSize(width: 0, height: -6)
        case .bottom: CGSize(width: 0, height: 6)
        case .leading: CGSize(width: -6, height: 0)
        case .trailing: CGSize(width: 6, height: 0)
        }
    }

    static func arrowPadding(for edge: Edge) -> Edge.Set {
        switch edge {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }
}

private struct SKTooltipModifier<Tip: View>: ViewModifier {
    @Binding var isPresented: Bool
    let edge: Edge
    let tip: Tip

    func body(content: Content) -> some View {
        let anchorEdge = edge
        let alignment = SKTooltipGeometry.overlayAlignment(for: anchorEdge)
        let shift = SKTooltipGeometry.offset(for: anchorEdge)

        return content
            .overlay(alignment: alignment) {
                if isPresented {
                    bubble
                        .fixedSize()
                        .alignmentGuide(alignment.vertical) { d in
                            SKTooltipGeometry.verticalGuide(for: anchorEdge, d)
                        }
                        .offset(x: shift.width, y: shift.height)
                        .transition(.opacity.combined(with: .scale(scale: 0.88)))
                        .zIndex(1)
                }
            }
            .skAnimation(.settle, value: isPresented)
    }

    private var bubble: some View {
        tip
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.surface)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, SK.Space.md)
            .padding(.vertical, SK.Space.sm)
            .padding(SKTooltipGeometry.arrowPadding(for: edge), 8)
            .background {
                SKTooltipShape(arrowEdge: edge)
                    .fill(SK.Palette.label)
                    .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
            }
            .frame(maxWidth: 240)
            .onTapGesture { isPresented = false }
            .accessibilityAddTraits(.isStaticText)
    }
}

extension View {
    /// Shows a pointed tooltip attached to this view.
    public func skTooltip<Tip: View>(
        isPresented: Binding<Bool>,
        edge: Edge = .bottom,
        @ViewBuilder tip: () -> Tip
    ) -> some View {
        modifier(SKTooltipModifier(isPresented: isPresented, edge: edge, tip: tip()))
    }
}

#Preview("SKTooltip") {
    @Previewable @State var a = true
    @Previewable @State var b = false

    VStack(spacing: 90) {
        Image(systemName: "questionmark.circle.fill")
            .font(SK.Icon.symbol(SK.Icon.xl))
            .foregroundStyle(SK.Palette.accent)
            .onTapGesture { a.toggle() }
            .skTooltip(isPresented: $a, edge: .bottom) {
                Text("Arrow points down at the thing it explains.")
            }

        Image(systemName: "bell.fill")
            .font(SK.Icon.symbol(SK.Icon.xl))
            .foregroundStyle(SK.Palette.accent)
            .onTapGesture { b.toggle() }
            .skTooltip(isPresented: $b, edge: .top) {
                Text("And up, when there is no room below.")
            }
    }
    .padding(SK.Space.xxxl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
