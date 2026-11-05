//
//  SKNavigationBar.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A navigation bar that fades in its background as content scrolls under it,
//  rather than sitting on an opaque slab from the first pixel.
//
//  Progress is driven by a scroll offset you pass in — the bar does not own a
//  ScrollView. Components that swallow your scroll view are components you
//  fight for the rest of the project.
//
//  Usage:
//      SKNavigationBar(title: "Settings", scrollOffset: offset) {
//          Button { } label: { Image(systemName: "chevron.left") }
//      } trailing: {
//          Button { } label: { Image(systemName: "ellipsis") }
//      }
//

import SwiftUI

public struct SKNavigationBar<Leading: View, Trailing: View>: View {
    private let title: String
    private let scrollOffset: CGFloat
    private let threshold: CGFloat
    private let leading: Leading
    private let trailing: Trailing

    public init(
        title: String,
        scrollOffset: CGFloat = 0,
        threshold: CGFloat = 40,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.scrollOffset = scrollOffset
        self.threshold = threshold
        self.leading = leading()
        self.trailing = trailing()
    }

    /// 0 at rest, 1 once scrolled past the threshold.
    private var progress: CGFloat {
        min(max(scrollOffset / threshold, 0), 1)
    }

    public var body: some View {
        HStack(spacing: SK.Space.md) {
            leading.frame(minWidth: SK.Icon.hitTarget, alignment: .leading)

            Text(title)
                .font(SK.Type_.headline)
                .foregroundStyle(SK.Palette.label)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .opacity(progress)

            trailing.frame(minWidth: SK.Icon.hitTarget, alignment: .trailing)
        }
        .padding(.horizontal, SK.Space.lg)
        .frame(height: 52)
        .background {
            SK.Palette.surfaceElevated
                .opacity(progress)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(SK.Palette.separator)
                        .frame(height: SK.Stroke.hairline)
                        .opacity(progress)
                }
                .ignoresSafeArea(edges: .top)
        }
        .skAnimation(.snap, value: progress > 0.5)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

extension SKNavigationBar where Trailing == EmptyView {
    public init(title: String, scrollOffset: CGFloat = 0, threshold: CGFloat = 40,
                @ViewBuilder leading: () -> Leading) {
        self.init(title: title, scrollOffset: scrollOffset, threshold: threshold,
                  leading: leading) { EmptyView() }
    }
}

extension SKNavigationBar where Leading == EmptyView, Trailing == EmptyView {
    public init(title: String, scrollOffset: CGFloat = 0, threshold: CGFloat = 40) {
        self.init(title: title, scrollOffset: scrollOffset, threshold: threshold,
                  leading: { EmptyView() }) { EmptyView() }
    }
}

#Preview("SKNavigationBar") {
    @Previewable @State var offset: CGFloat = 0

    VStack(spacing: 0) {
        SKNavigationBar(title: "Settings", scrollOffset: offset) {
            Image(systemName: "chevron.left")
                .font(SK.Icon.symbol(SK.Icon.md, weight: .semibold))
                .foregroundStyle(SK.Palette.accent)
        } trailing: {
            Image(systemName: "ellipsis.circle")
                .font(SK.Icon.symbol(SK.Icon.md))
                .foregroundStyle(SK.Palette.accent)
        }

        ScrollView {
            VStack(alignment: .leading, spacing: SK.Space.lg) {
                Text("Settings").font(SK.Type_.display)
                ForEach(0..<18, id: \.self) { i in
                    Text("Row \(i + 1)").font(SK.Type_.body)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SK.Space.lg)
            .background {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: SKScrollOffsetKey.self,
                        value: -geo.frame(in: .named("scroll")).minY
                    )
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(SKScrollOffsetKey.self) { offset = $0 }
    }
    .background(SK.Palette.surfaceSunken)
}

/// Reports scroll offset upward. Public so callers can reuse it rather than
/// redefining their own key with a clashing name.
public struct SKScrollOffsetKey: PreferenceKey {
    public static let defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
