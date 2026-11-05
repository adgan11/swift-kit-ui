//
//  SKPullToRefresh.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//  Requires iOS 18 / macOS 15 — see the note below. Every other component in
//  the kit is iOS 17.
//
//  Pull-to-refresh you can brand, unlike `.refreshable`'s fixed system spinner.
//  The arc fills in proportion to the pull and ticks once at the threshold, so
//  the commit point is felt rather than watched.
//
//  WHY iOS 18, AND WHY NOT A GeometryReader
//  ----------------------------------------
//  The classic trick — a `GeometryReader` in the scroll content publishing its
//  `minY` through a `PreferenceKey` — DOES NOT WORK under the modern scroll
//  system. Instrumented on iOS 26.2 with a counter: through a full drag and a
//  swipe, with the list demonstrably scrolling, the preference fired exactly
//  ONCE, at first layout. A GeometryReader is not re-evaluated for pure
//  translation, only for size changes. Named and `.global` coordinate spaces
//  both behave the same way.
//
//  `onScrollGeometryChange` is the API that actually reports offset, and it is
//  iOS 18+. Rather than ship a component that silently does nothing, this one
//  carries a higher floor and says so.
//
//  WHY IT OWNS THE ScrollView
//  --------------------------
//  Reading a scroll view's geometry requires being the scroll view. A modifier
//  applied to content already inside one cannot reach it.
//
//  Usage:
//      SKRefreshableScrollView {
//          await reload()
//      } content: {
//          ForEach(items) { ... }
//      }
//

import SwiftUI

@available(iOS 18.0, macOS 15.0, *)
public struct SKRefreshableScrollView<Content: View>: View {
    private let threshold: CGFloat
    private let showsIndicators: Bool
    private let action: () async -> Void
    private let content: Content

    @State private var pull: CGFloat = 0
    @State private var isRefreshing = false
    /// Set once the pull passes the threshold; the refresh fires when the pull
    /// then collapses, which is the release.
    @State private var armed = false
    @State private var spin = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        threshold: CGFloat = 72,
        showsIndicators: Bool = false,
        action: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.threshold = threshold
        self.showsIndicators = showsIndicators
        self.action = action
        self.content = content()
    }

    private var progress: CGFloat { min(max(pull / threshold, 0), 1) }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            content
                // Holds the content down while refreshing so the spinner has
                // somewhere to sit instead of overlapping the first row.
                .padding(.top, isRefreshing ? threshold : 0)
        }
        // A list shorter than the viewport would otherwise never bounce, and an
        // empty list is exactly when people pull hardest.
        .scrollBounceBehavior(.always, axes: .vertical)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            // Distance overscrolled past the top. Positive while pulling down.
            -(geometry.contentOffset.y + geometry.contentInsets.top)
        } action: { _, distance in
            handle(distance)
        }
        .overlay(alignment: .top) { indicator }
        .skAnimation(.settle, value: isRefreshing)
    }

    @ViewBuilder
    private var indicator: some View {
        Group {
            if isRefreshing {
                Circle()
                    .trim(from: 0, to: 0.26)
                    .stroke(SK.Palette.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                            spin = true
                        }
                    }
                    .onDisappear { spin = false }
            } else if progress > 0.02 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(SK.Palette.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(0.55 + progress * 0.45)
                    .opacity(Double(progress))
            }
        }
        .frame(width: 26, height: 26)
        // Rides down with the finger, then parks at the threshold.
        .offset(y: (isRefreshing ? threshold : min(pull, threshold)) / 2 - 13)
        .accessibilityHidden(true)
    }

    private func handle(_ distance: CGFloat) {
        guard !isRefreshing else { return }
        pull = max(0, distance)

        if pull >= threshold, !armed {
            armed = true
            SK.Haptic.play(.medium)
        }
        // Armed, then collapsing: the finger let go.
        if armed, pull < threshold * 0.55 {
            armed = false
            start()
        }
    }

    private func start() {
        guard !isRefreshing else { return }
        withAnimation(SKMotion.settle.resolved(reduceMotion: reduceMotion)) {
            isRefreshing = true
        }
        Task { @MainActor in
            await action()
            withAnimation(SKMotion.settle.resolved(reduceMotion: reduceMotion)) {
                isRefreshing = false
                pull = 0
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("SKPullToRefresh") {
    @Previewable @State var items = Array(1...14)

    SKRefreshableScrollView {
        try? await Task.sleep(for: .seconds(1.2))
        items = items.map { $0 + 14 }
    } content: {
        VStack(spacing: SK.Space.sm) {
            Text("Pull down to refresh")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
            ForEach(items, id: \.self) { i in
                Text("Item \(i)")
                    .font(SK.Type_.body)
                    .foregroundStyle(SK.Palette.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(SK.Space.md)
                    .skSurface(.bordered, radius: SK.Radius.md)
            }
        }
        .padding(SK.Space.lg)
    }
    .background(SK.Palette.surfaceSunken)
}
