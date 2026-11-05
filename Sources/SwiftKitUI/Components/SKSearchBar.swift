//
//  SKSearchBar.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Search field with a Cancel button that slides in on focus.
//
//  Cancel is width-animated rather than inserted, so the field shrinks smoothly
//  instead of the button popping into existence and shoving it sideways.
//
//  Usage:
//      SKSearchBar(text: $query)
//      SKSearchBar(text: $query, placeholder: "Search components") { submit() }
//

import SwiftUI

public struct SKSearchBar: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: (() -> Void)?

    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        text: Binding<String>,
        placeholder: String = "Search",
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: SK.Space.sm) {
            field
            if focused {
                Button("Cancel") {
                    text = ""
                    focused = false
                    SK.Haptic.play(.light)
                }
                .font(SK.Type_.callout)
                .foregroundStyle(SK.Palette.accent)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .skAnimation(.snap, value: focused)
    }

    private var field: some View {
        HStack(spacing: SK.Space.sm) {
            Image(systemName: "magnifyingglass")
                .font(SK.Icon.symbol(SK.Icon.md))
                .foregroundStyle(focused ? SK.Palette.accent : SK.Palette.labelTertiary)

            TextField(placeholder, text: $text)
                .font(SK.Type_.body)
                .foregroundStyle(SK.Palette.label)
                .focused($focused)
                .autocorrectionDisabled()
                .skCapitalization(.never)
                .submitLabel(.search)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button {
                    text = ""
                    SK.Haptic.play(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(SK.Icon.symbol(SK.Icon.md))
                        .foregroundStyle(SK.Palette.labelTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, SK.Space.md)
        .frame(height: SK.Icon.hitTarget)
        .background(SK.Palette.fill, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(SK.Palette.accent, lineWidth: focused ? SK.Stroke.thick : 0)
        }
        .contentShape(.capsule)
        .onTapGesture { focused = true }
    }
}

#Preview("SKSearchBar") {
    @Previewable @State var query = ""
    @Previewable @State var filled = "swiftui toggle"

    VStack(spacing: SK.Space.xl) {
        SKSearchBar(text: $query)
        SKSearchBar(text: $filled, placeholder: "Search components")
        Text("Tap a field to see Cancel slide in")
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
