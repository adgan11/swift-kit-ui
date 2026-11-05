//
//  SKEmptyState.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  The screen you see when there is nothing to see. Most apps ship a blank view
//  here, which reads as a bug rather than a state.
//
//  Usage:
//      SKEmptyState(systemImage: "tray", title: "No messages",
//                   message: "When someone writes, it lands here.",
//                   actionTitle: "Refresh") { reload() }
//

import SwiftUI

public struct SKEmptyState: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?
    private let tint: Color

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        systemImage: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        tint: Color = SK.Palette.accent,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        VStack(spacing: SK.Space.lg) {
            Image(systemName: systemImage)
                .font(SK.Icon.symbol(44, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 92, height: 92)
                .background(Circle().fill(tint.opacity(0.10)))
                // A small settle on appear, so the state reads as arriving
                // rather than as content that failed to load.
                .scaleEffect(appeared ? 1 : 0.86)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: SK.Space.xs) {
                Text(title)
                    .font(SK.Type_.headline)
                    .foregroundStyle(SK.Palette.label)
                if let message {
                    Text(message)
                        .font(SK.Type_.callout)
                        .foregroundStyle(SK.Palette.labelSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .opacity(appeared ? 1 : 0)

            if let actionTitle, let action {
                Button(actionTitle) {
                    action()
                    SK.Haptic.play(.light)
                }
                .font(SK.Type_.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, SK.Space.xl)
                .padding(.vertical, SK.Space.md)
                .background(Capsule().fill(tint))
                .buttonStyle(.skPress)
                .opacity(appeared ? 1 : 0)
            }
        }
        .padding(SK.Space.xl)
        .frame(maxWidth: 340)
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(SKMotion.settle.standard.delay(0.05)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("SKEmptyState") {
    VStack(spacing: SK.Space.xxxl) {
        SKEmptyState(
            systemImage: "tray",
            title: "No messages yet",
            message: "When someone writes to you, it will show up here.",
            actionTitle: "Refresh"
        ) {}

        SKEmptyState(
            systemImage: "wifi.slash",
            title: "You're offline",
            message: "Check your connection and try again.",
            tint: SK.Palette.warning
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
