//
//  SKTextField.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A text field whose label rises out of the way on focus, with a focus ring and
//  an error state that does not resize the layout when it appears.
//
//  Two things most floating-label fields get wrong, both fixed here:
//
//  1. The label must stay INSIDE the box. Offsetting it far enough to sit on the
//     border means it collides with the stroke, and the collision is worst in
//     exactly the state you look at most — focused, where the border is thick
//     and tinted. The label travels within the field's own padding instead.
//  2. The error slot reserves its height whether or not there is an error.
//     Fields that grow on validation shove the rest of the form down while
//     someone is still typing in them.
//
//  Usage:
//      SKTextField("Email", text: $email, systemImage: "envelope")
//      SKTextField("Password", text: $pw, isSecure: true, error: error)
//

import SwiftUI

public struct SKTextField: View {
    private let title: String
    @Binding private var text: String
    private let systemImage: String?
    private let isSecure: Bool
    private let error: String?
    private let capitalization: SK.Capitalization?
    private let keyboard: SK.Keyboard

    @FocusState private var focused: Bool

    public init(
        _ title: String,
        text: Binding<String>,
        systemImage: String? = nil,
        isSecure: Bool = false,
        error: String? = nil,
        autocapitalization: SK.Capitalization? = nil,
        keyboard: SK.Keyboard = .default
    ) {
        self.title = title
        self._text = text
        self.systemImage = systemImage
        self.isSecure = isSecure
        self.error = error
        self.capitalization = autocapitalization
        self.keyboard = keyboard
    }

    private var isFloating: Bool { focused || !text.isEmpty }

    private var borderColor: Color {
        if error != nil { return SK.Palette.danger }
        return focused ? SK.Palette.accent : SK.Palette.separator
    }

    private var labelColor: Color {
        if error != nil { return SK.Palette.danger }
        return focused ? SK.Palette.accent : SK.Palette.labelSecondary
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.xs) {
            box
            errorSlot
        }
    }

    private var box: some View {
        HStack(spacing: SK.Space.md) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(SK.Icon.symbol(SK.Icon.md))
                    .foregroundStyle(focused ? SK.Palette.accent : SK.Palette.labelTertiary)
                    .frame(width: SK.Icon.lg)
            }

            // Label and field share one leading-aligned stack and slide within
            // it, so neither can ever reach the border.
            ZStack(alignment: .leading) {
                Text(title)
                    .font(isFloating ? SK.Type_.caption : SK.Type_.body)
                    .foregroundStyle(labelColor)
                    .offset(y: isFloating ? -13 : 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                field
                    .offset(y: isFloating ? 8 : 0)
                    // Hidden until the label has moved, otherwise the caret
                    // sits on top of the resting label.
                    .opacity(isFloating ? 1 : 0)
            }
            .frame(height: 34)

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
                .accessibilityLabel("Clear \(title)")
            }
        }
        .padding(.horizontal, SK.Space.lg)
        .padding(.vertical, SK.Space.md)
        .background(SK.Palette.surface, in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                .strokeBorder(borderColor, lineWidth: focused || error != nil ? SK.Stroke.thick : SK.Stroke.thin)
        }
        .skAnimation(.snap, value: isFloating)
        .skAnimation(.snap, value: focused)
        .skAnimation(.snap, value: error)
        .contentShape(.rect)
        .onTapGesture { focused = true }
    }

    @ViewBuilder
    private var field: some View {
        Group {
            if isSecure {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
        .font(SK.Type_.body)
        .foregroundStyle(SK.Palette.label)
        .focused($focused)
        .skCapitalization(capitalization)
        .skKeyboard(keyboard)
        .autocorrectionDisabled(isSecure)
    }

    private var errorSlot: some View {
        Text(error ?? " ")
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.danger)
            .padding(.leading, SK.Space.xs)
            .opacity(error == nil ? 0 : 1)
            .skAnimation(.snap, value: error)
            .accessibilityHidden(error == nil)
    }
}

#Preview("SKTextField") {
    @Previewable @State var email = ""
    @Previewable @State var password = "hunter2"
    @Previewable @State var name = "Ahmed"

    VStack(spacing: SK.Space.md) {
        SKTextField("Email", text: $email, systemImage: "envelope.fill",
                    autocapitalization: .never, keyboard: .email)
        SKTextField("Password", text: $password, systemImage: "lock.fill", isSecure: true)
        SKTextField("Full name", text: $name)
        SKTextField("Username", text: .constant("taken"),
                    error: "That username is already in use.")
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
