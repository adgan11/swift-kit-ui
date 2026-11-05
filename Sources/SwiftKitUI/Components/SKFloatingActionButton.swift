//
//  SKFloatingActionButton.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A FAB that fans out secondary actions when expanded.
//
//  Actions animate out with a per-item delay so they arrive in sequence rather
//  than all at once — staggering is the whole difference between "menu opened"
//  and "menu unfolded". The main icon rotates 45 degrees to become a close
//  affordance, so no second button is needed.
//
//  Usage:
//      SKFloatingActionButton(actions: [
//          .init(symbol: "camera.fill", title: "Photo") { },
//          .init(symbol: "mic.fill", title: "Audio") { },
//      ])
//

import SwiftUI

public struct SKFABAction: Identifiable {
    public let id = UUID()
    public let symbol: String
    public let title: String
    public let handler: () -> Void

    public init(symbol: String, title: String, handler: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.handler = handler
    }
}

public struct SKFloatingActionButton: View {
    private let symbol: String
    private let tint: Color
    private let actions: [SKFABAction]
    private let onTap: (() -> Void)?

    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        symbol: String = "plus",
        tint: Color = SK.Palette.accent,
        actions: [SKFABAction] = [],
        onTap: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.tint = tint
        self.actions = actions
        self.onTap = onTap
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: SK.Space.md) {
            if isExpanded {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    actionRow(action)
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                            .combined(with: .scale(scale: 0.6, anchor: .bottomTrailing))
                        )
                        // Reversed so the item nearest the button leads.
                        .animation(
                            SKMotion.settle.resolved(reduceMotion: reduceMotion)?
                                .delay(Double(actions.count - 1 - index) * 0.045),
                            value: isExpanded
                        )
                }
            }
            mainButton
        }
    }

    private var mainButton: some View {
        Button {
            if actions.isEmpty {
                onTap?()
                SK.Haptic.play(.medium)
            } else {
                withAnimation(SKMotion.settle.resolved(reduceMotion: reduceMotion)) {
                    isExpanded.toggle()
                }
                SK.Haptic.play(.light)
            }
        } label: {
            Image(systemName: symbol)
                .font(SK.Icon.symbol(SK.Icon.lg, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(tint))
                .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
                .rotationEffect(.degrees(isExpanded ? 45 : 0))
        }
        .buttonStyle(.skPress(scale: 0.92, haptic: nil))
        .skAnimation(.settle, value: isExpanded)
        .accessibilityLabel(isExpanded ? "Close menu" : "Actions")
    }

    private func actionRow(_ action: SKFABAction) -> some View {
        Button {
            action.handler()
            withAnimation(SKMotion.settle.resolved(reduceMotion: reduceMotion)) { isExpanded = false }
            SK.Haptic.play(.light)
        } label: {
            HStack(spacing: SK.Space.md) {
                Text(action.title)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.label)
                    .padding(.horizontal, SK.Space.md)
                    .padding(.vertical, SK.Space.xs)
                    .background(Capsule().fill(SK.Palette.surfaceElevated))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)

                Image(systemName: action.symbol)
                    .font(SK.Icon.symbol(SK.Icon.md))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(SK.Palette.surfaceElevated))
                    .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
            }
        }
        .buttonStyle(.skPress(scale: 0.94, haptic: nil))
    }
}

#Preview("SKFloatingActionButton") {
    ZStack(alignment: .bottomTrailing) {
        SK.Palette.surfaceSunken.ignoresSafeArea()

        SKFloatingActionButton(actions: [
            .init(symbol: "camera.fill", title: "Photo") {},
            .init(symbol: "mic.fill", title: "Audio") {},
            .init(symbol: "doc.fill", title: "Document") {},
        ])
        .padding(SK.Space.xl)
    }
}
