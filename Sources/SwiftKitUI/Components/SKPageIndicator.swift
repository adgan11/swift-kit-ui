//
//  SKPageIndicator.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Page dots where the active one stretches into a capsule instead of just
//  changing colour. Tappable, so it doubles as navigation.
//
//  Usage:
//      SKPageIndicator(count: 4, index: $page)
//      SKPageIndicator(count: 4, index: $page, style: .bars)
//

import SwiftUI

public struct SKPageIndicator: View {
    public enum Style: Sendable { case dots, bars }

    private let count: Int
    @Binding private var index: Int
    private let style: Style
    private let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        count: Int,
        index: Binding<Int>,
        style: Style = .dots,
        tint: Color = SK.Palette.accent
    ) {
        self.count = count
        self._index = index
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: style == .dots ? SK.Space.sm : SK.Space.xs) {
            ForEach(0..<max(count, 1), id: \.self) { page in
                dot(page)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page")
        .accessibilityValue("\(index + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if index + 1 < count { index += 1 }
            case .decrement: if index > 0 { index -= 1 }
            @unknown default: break
            }
        }
    }

    private func dot(_ page: Int) -> some View {
        let active = page == index
        let height: CGFloat = style == .dots ? 8 : 4
        let activeWidth: CGFloat = style == .dots ? 24 : 28
        let restWidth: CGFloat = style == .dots ? 8 : 14

        return Capsule()
            .fill(active ? tint : SK.Palette.separator)
            .frame(width: active ? activeWidth : restWidth, height: height)
            // Hit target stays a comfortable size even though the dot is tiny.
            .frame(width: max(activeWidth, 30), height: SK.Space.xxl, alignment: .center)
            .contentShape(.rect)
            .onTapGesture {
                guard !active else { return }
                withAnimation(SKMotion.snap.resolved(reduceMotion: reduceMotion)) { index = page }
                SK.Haptic.play(.selection)
            }
            .skAnimation(.snap, value: index)
    }
}

#Preview("SKPageIndicator") {
    @Previewable @State var page = 0

    VStack(spacing: SK.Space.xxl) {
        TabView(selection: $page) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: SK.Radius.xl, style: .continuous)
                    .fill(SK.Palette.accentSoft)
                    .overlay(Text("Page \(i + 1)").font(SK.Type_.title))
                    .padding(SK.Space.lg)
                    .tag(i)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        .frame(height: 220)

        SKPageIndicator(count: 4, index: $page)
        SKPageIndicator(count: 4, index: $page, style: .bars, tint: SK.Palette.success)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
