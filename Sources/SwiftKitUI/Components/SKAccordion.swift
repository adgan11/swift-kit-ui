//
//  SKAccordion.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Expand/collapse with the chevron rotating on the same spring as the height
//  change, so the two read as one movement instead of two.
//
//  Usage:
//      SKAccordion("What is included?") { Text("Everything.") }
//      SKAccordion("Advanced", isExpanded: $open) { ... }
//

import SwiftUI

public struct SKAccordion<Content: View>: View {
    private let title: String
    private let systemImage: String?
    private let content: Content

    @Binding private var externalExpanded: Bool
    @State private var internalExpanded: Bool
    private let usesExternal: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isExpanded: Bool {
        usesExternal ? externalExpanded : internalExpanded
    }

    public init(
        _ title: String,
        systemImage: String? = nil,
        initiallyExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
        self._externalExpanded = .constant(false)
        self._internalExpanded = State(initialValue: initiallyExpanded)
        self.usesExternal = false
    }

    public init(
        _ title: String,
        systemImage: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
        self._externalExpanded = isExpanded
        self._internalExpanded = State(initialValue: false)
        self.usesExternal = true
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if isExpanded {
                content
                    .font(SK.Type_.callout)
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, SK.Space.lg)
                    .padding(.bottom, SK.Space.lg)
                    // Opacity + a slight scale from the top edge, NOT
                    // `.move(edge: .top)`. A move transition slides the content
                    // up THROUGH the header — `.clipped()` on the VStack cannot
                    // help, because the header is inside those same bounds.
                    // The height change alone reads as the expansion.
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .clipped()
        .skSurface(.bordered, radius: SK.Radius.lg)
        .skAnimation(.settle, value: isExpanded)
    }

    private var header: some View {
        Button(action: toggle) {
            HStack(spacing: SK.Space.md) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(SK.Icon.symbol(SK.Icon.md))
                        .foregroundStyle(SK.Palette.accent)
                }
                Text(title)
                    .font(SK.Type_.headline)
                    .foregroundStyle(SK.Palette.label)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: SK.Space.sm)
                Image(systemName: "chevron.down")
                    .font(SK.Icon.symbol(SK.Icon.sm, weight: .semibold))
                    .foregroundStyle(SK.Palette.labelTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(SK.Space.lg)
            .frame(minHeight: SK.Icon.hitTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }

    private func toggle() {
        SK.Haptic.play(.light)
        withAnimation(SKMotion.settle.resolved(reduceMotion: reduceMotion)) {
            if usesExternal { externalExpanded.toggle() } else { internalExpanded.toggle() }
        }
    }
}

#Preview("SKAccordion") {
    ScrollView {
        VStack(spacing: SK.Space.md) {
            SKAccordion("What is included?", systemImage: "shippingbox.fill", initiallyExpanded: true) {
                Text("Every component, every variant, the full source, and updates for a year.")
            }
            SKAccordion("Can I use it commercially?", systemImage: "briefcase.fill") {
                Text("Yes. It is MIT licensed, so use it in any app.")
            }
            SKAccordion("Which iOS versions?", systemImage: "iphone") {
                Text("iOS 17 and later. Liquid Glass falls back gracefully below iOS 26.")
            }
        }
        .padding(SK.Space.lg)
    }
    .background(SK.Palette.surfaceSunken)
}
