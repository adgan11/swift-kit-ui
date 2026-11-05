//
//  SKTabBar.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A custom tab bar where the selection indicator *travels* between tabs rather
//  than cutting. That is `matchedGeometryEffect` doing the work: one pill exists
//  at a time and SwiftUI interpolates its frame, which is both cheaper and
//  smoother than animating an offset you calculate yourself.
//
//  Usage:
//      SKTabBar(selection: $tab, tabs: [
//          .init(tab: .home,    title: "Home",    systemImage: "house.fill"),
//          .init(tab: .search,  title: "Search",  systemImage: "magnifyingglass"),
//          .init(tab: .profile, title: "Profile", systemImage: "person.fill"),
//      ])
//

import SwiftUI

public struct SKTabItem<Tab: Hashable>: Identifiable {
    public let tab: Tab
    public let title: String
    public let systemImage: String

    public var id: Tab { tab }

    public init(tab: Tab, title: String, systemImage: String) {
        self.tab = tab
        self.title = title
        self.systemImage = systemImage
    }
}

public struct SKTabBar<Tab: Hashable>: View {
    public enum Style: Sendable {
        case floating
        case liquidGlass
    }

    @Binding private var selection: Tab
    private let tabs: [SKTabItem<Tab>]
    private let style: Style
    private let showsLabels: Bool

    @Namespace private var pill
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        selection: Binding<Tab>,
        tabs: [SKTabItem<Tab>],
        style: Style = .floating,
        showsLabels: Bool = true
    ) {
        self._selection = selection
        self.tabs = tabs
        self.style = style
        self.showsLabels = showsLabels
    }

    public var body: some View {
        HStack(spacing: SK.Space.xxs) {
            ForEach(tabs) { item in
                tabButton(item)
            }
        }
        .padding(SK.Space.xs)
        .background { barBackground }
        .clipShape(Capsule(style: .continuous))
        .overlay {
            if style == .floating {
                Capsule(style: .continuous)
                    .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.hairline)
            }
        }
        .shadow(color: .black.opacity(style == .floating ? 0.12 : 0), radius: 18, x: 0, y: 8)
        .accessibilityElement(children: .contain)
    }

    private func tabButton(_ item: SKTabItem<Tab>) -> some View {
        let isSelected = item.tab == selection

        return Button {
            guard !isSelected else { return }
            withAnimation(SKMotion.snap.resolved(reduceMotion: reduceMotion)) {
                selection = item.tab
            }
            SK.Haptic.play(.selection)
        } label: {
            HStack(spacing: SK.Space.xs) {
                Image(systemName: item.systemImage)
                    .font(SK.Icon.symbol(SK.Icon.md))
                    // Bounces only the newly selected icon. `value:` is the
                    // selection itself so deselection stays silent.
                    .symbolEffect(.bounce, value: isSelected ? selection : nil)

                if showsLabels && isSelected {
                    Text(item.title)
                        .font(SK.Type_.caption)
                        .fixedSize()
                        // Asymmetric on purpose: the label should appear with
                        // the pill but leave instantly, otherwise two labels
                        // are briefly visible mid-transition.
                        .transition(AnyTransition.asymmetric(
                            insertion: AnyTransition.opacity
                                .combined(with: .scale(scale: 0.82, anchor: .leading)),
                            removal: AnyTransition.opacity
                        ))
                }
            }
            .foregroundStyle(isSelected ? Color.white : SK.Palette.labelSecondary)
            .padding(.vertical, SK.Space.sm + 2)
            .padding(.horizontal, isSelected ? SK.Space.lg : SK.Space.md)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(SK.Palette.accent)
                        // One pill, moved by SwiftUI. Do not add a second.
                        .matchedGeometryEffect(id: "sk.tabbar.pill", in: pill)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var barBackground: some View {
        switch style {
        case .floating:
            SK.Palette.surfaceElevated
        case .liquidGlass:
            Color.clear.skSurface(.liquidGlass, radius: SK.Radius.pill)
        }
    }
}

private enum PreviewTab: Hashable { case home, search, saved, profile }

#Preview("SKTabBar") {
    @Previewable @State var selection: PreviewTab = .home

    VStack {
        Spacer()
        SKTabBar(selection: $selection, tabs: [
            .init(tab: .home, title: "Home", systemImage: "house.fill"),
            .init(tab: .search, title: "Search", systemImage: "magnifyingglass"),
            .init(tab: .saved, title: "Saved", systemImage: "bookmark.fill"),
            .init(tab: .profile, title: "Profile", systemImage: "person.fill"),
        ])
        Spacer().frame(height: SK.Space.xl)
        SKTabBar(selection: $selection, tabs: [
            .init(tab: .home, title: "Home", systemImage: "house.fill"),
            .init(tab: .search, title: "Search", systemImage: "magnifyingglass"),
            .init(tab: .saved, title: "Saved", systemImage: "bookmark.fill"),
            .init(tab: .profile, title: "Profile", systemImage: "person.fill"),
        ], style: .liquidGlass)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [SK.Palette.accentSoft, SK.Palette.surfaceSunken],
            startPoint: .top, endPoint: .bottom
        )
    )
}
