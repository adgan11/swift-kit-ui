//
//  SKSkeleton.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Placeholder shapes for loading states.
//
//  Skeletons beat spinners when you know the shape of what is coming: the
//  layout does not jump when real content lands, because the placeholder was
//  already the right size.
//
//  Usage:
//      SKSkeleton(.text(lines: 3))
//      SKSkeleton(.circle, size: 48)
//      SKSkeletonRow()
//      Text("Loaded").skRedacted(isLoading)
//

import SwiftUI

public struct SKSkeleton: View {
    public enum Shape_: Sendable {
        case rect
        case circle
        case text(lines: Int)
    }

    private let shape: Shape_
    private let size: CGFloat?
    private let cornerRadius: CGFloat

    public init(_ shape: Shape_ = .rect, size: CGFloat? = nil, cornerRadius: CGFloat = SK.Radius.sm) {
        self.shape = shape
        self.size = size
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Group {
            switch shape {
            case .rect:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SK.Palette.placeholder)
                    .frame(height: size ?? 16)
            case .circle:
                Circle()
                    .fill(SK.Palette.placeholder)
                    .frame(width: size ?? 44, height: size ?? 44)
            case .text(let lines):
                VStack(alignment: .leading, spacing: SK.Space.sm) {
                    ForEach(0..<max(lines, 1), id: \.self) { index in
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(SK.Palette.placeholder)
                            .frame(height: size ?? 12)
                            // Last line short, like real text.
                            .frame(maxWidth: index == lines - 1 && lines > 1 ? 160 : .infinity,
                                   alignment: .leading)
                    }
                }
            }
        }
        .skShimmer()
        .accessibilityHidden(true)
    }
}

/// Avatar + two lines. The single most-repeated skeleton in any list app.
public struct SKSkeletonRow: View {
    private let showsAvatar: Bool

    public init(showsAvatar: Bool = true) { self.showsAvatar = showsAvatar }

    public var body: some View {
        HStack(spacing: SK.Space.md) {
            if showsAvatar { SKSkeleton(.circle, size: 44) }
            VStack(alignment: .leading, spacing: SK.Space.sm) {
                SKSkeleton(.rect, size: 12)
                SKSkeleton(.rect, size: 10).frame(maxWidth: 140, alignment: .leading)
            }
        }
        .accessibilityHidden(true)
    }
}

extension View {
    /// Greys out and shimmers this view while loading, keeping its exact layout.
    public func skRedacted(_ isLoading: Bool) -> some View {
        redacted(reason: isLoading ? .placeholder : [])
            .skShimmer(isLoading)
    }
}

#Preview("SKSkeleton") {
    VStack(alignment: .leading, spacing: SK.Space.xl) {
        SKSkeletonRow()
        SKSkeletonRow()
        SKSkeleton(.text(lines: 3))
        SKSkeleton(.rect, size: 120, cornerRadius: SK.Radius.lg)
        VStack(alignment: .leading, spacing: SK.Space.xs) {
            Text("Real text, redacted").font(SK.Type_.headline)
            Text("Same layout, no jump when it loads.").font(SK.Type_.callout)
        }
        .skRedacted(true)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SK.Palette.surfaceSunken)
}
