//
//  SKChatComposer.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  The input bar for an assistant. Grows with the message, and its trailing
//  button changes job rather than multiplying.
//
//  One button occupies that corner and means three different things depending
//  on state — dictate when there is nothing to send, send when there is, stop
//  while the model is answering. Shipping three buttons instead is the usual
//  shortcut and it costs you the corner: on a phone, that is the only spot the
//  thumb reaches without moving, so it has to hold whatever action is live.
//
//  The field grows to `lineLimit` and then scrolls internally, which is the
//  behaviour every messaging app has and almost no reimplementation does —
//  an unbounded field eventually pushes the send button off the screen.
//
//  Usage:
//      SKChatComposer(text: $draft, isStreaming: generating,
//                     onSend: send, onStop: cancel)
//

import SwiftUI

public struct SKChatComposer: View {
    @Binding private var text: String
    private let isStreaming: Bool
    private let placeholder: String
    private let lineLimit: Int
    private let onSend: () -> Void
    private let onStop: (() -> Void)?
    private let onAttach: (() -> Void)?
    private let onVoice: (() -> Void)?

    @FocusState private var focused: Bool

    public init(
        text: Binding<String>,
        isStreaming: Bool = false,
        placeholder: String = "Message",
        lineLimit: Int = 6,
        onSend: @escaping () -> Void,
        onStop: (() -> Void)? = nil,
        onAttach: (() -> Void)? = nil,
        onVoice: (() -> Void)? = nil
    ) {
        self._text = text
        self.isStreaming = isStreaming
        self.placeholder = placeholder
        self.lineLimit = lineLimit
        self.onSend = onSend
        self.onStop = onStop
        self.onAttach = onAttach
        self.onVoice = onVoice
    }

    /// What the trailing button currently does.
    private enum Action { case send, stop, dictate }

    private var hasDraft: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var action: Action {
        if isStreaming { return .stop }
        if hasDraft || onVoice == nil { return .send }
        return .dictate
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: SK.Space.sm) {
            if let onAttach {
                circleButton(
                    symbol: "plus",
                    label: "Add attachment",
                    foreground: SK.Palette.labelSecondary,
                    background: SK.Palette.fill
                ) {
                    onAttach()
                    SK.Haptic.play(.light)
                }
            }

            field
            trailingButton
        }
        .padding(.horizontal, SK.Space.md)
        .padding(.vertical, SK.Space.sm)
        .skSurface(.bar)
        .skAnimation(.snap, value: action)
    }

    private func circleButton(
        symbol: String,
        label: String,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(background).frame(width: 38, height: 38)
                Image(systemName: symbol)
                    .font(SK.Icon.symbol(SK.Icon.md, weight: .bold))
                    .foregroundStyle(foreground)
            }
        }
        .buttonStyle(.skPress(scale: 0.9, haptic: nil))
        .accessibilityLabel(label)
    }

    // MARK: Field

    private var field: some View {
        ZStack(alignment: .leading) {
            // A manual placeholder, because `TextField`'s own disappears the
            // instant the field is focused — before anything has been typed —
            // which leaves an empty bar with no hint of what it wants.
            if text.isEmpty {
                Text(placeholder)
                    .font(SK.Type_.body)
                    .foregroundStyle(SK.Palette.labelTertiary)
                    .allowsHitTesting(false)
            }

            TextField("", text: $text, axis: .vertical)
                .font(SK.Type_.body)
                .foregroundStyle(SK.Palette.label)
                .lineLimit(1...lineLimit)
                .focused($focused)
                .skCapitalization(.sentences)
                .tint(SK.Palette.accent)
                .onSubmit(submit)
        }
        .padding(.horizontal, SK.Space.md)
        .padding(.vertical, SK.Space.sm + 2)
        .background(SK.Palette.fill, in: RoundedRectangle(cornerRadius: SK.Radius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.xl, style: .continuous)
                .strokeBorder(
                    focused ? SK.Palette.accent : SK.Palette.separator,
                    lineWidth: focused ? SK.Stroke.thick : SK.Stroke.thin
                )
        }
        .skAnimation(.snap, value: focused)
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .accessibilityLabel(placeholder)
    }

    // MARK: Trailing button

    private var trailingButton: some View {
        Button(action: trigger) {
            ZStack {
                Circle()
                    .fill(buttonFill)
                    .frame(width: 38, height: 38)

                // Cross-faded and scaled rather than swapped, so the corner
                // reads as one control changing job instead of three buttons
                // taking turns.
                symbol("arrow.up", visible: action == .send)
                symbol("stop.fill", visible: action == .stop)
                symbol("mic.fill", visible: action == .dictate)
            }
        }
        .buttonStyle(.skPress(scale: 0.9, haptic: nil))
        .disabled(action == .send && !hasDraft)
        .accessibilityLabel(accessibilityLabel)
    }

    private func symbol(_ name: String, visible: Bool) -> some View {
        Image(systemName: name)
            .font(SK.Icon.symbol(action == .stop ? SK.Icon.sm : SK.Icon.md, weight: .bold))
            .foregroundStyle(symbolColor)
            .scaleEffect(visible ? 1 : 0.4)
            .opacity(visible ? 1 : 0)
            .skAnimation(.snap, value: visible)
    }

    private var buttonFill: Color {
        switch action {
        case .stop: return SK.Palette.label
        case .send: return hasDraft ? SK.Palette.accent : SK.Palette.fill
        case .dictate: return SK.Palette.fill
        }
    }

    private var symbolColor: Color {
        switch action {
        case .stop: return SK.Palette.surface
        case .send: return hasDraft ? Color.white : SK.Palette.labelTertiary
        case .dictate: return SK.Palette.labelSecondary
        }
    }

    private var accessibilityLabel: String {
        switch action {
        case .send: return "Send message"
        case .stop: return "Stop generating"
        case .dictate: return "Dictate message"
        }
    }

    private func trigger() {
        switch action {
        case .send: submit()
        case .stop:
            onStop?()
            SK.Haptic.play(.rigid)
        case .dictate:
            onVoice?()
            SK.Haptic.play(.light)
        }
    }

    private func submit() {
        guard hasDraft else { return }
        onSend()
        SK.Haptic.play(.light)
    }
}

#Preview("SKChatComposer") {
    @Previewable @State var draft = ""
    @Previewable @State var streaming = false
    @Previewable @State var sent: [String] = []

    VStack(spacing: 0) {
        ScrollView {
            VStack(spacing: SK.Space.xs) {
                ForEach(Array(sent.enumerated()), id: \.offset) { _, message in
                    Text(message)
                        .font(SK.Type_.body)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, SK.Space.lg)
                        .padding(.vertical, SK.Space.md)
                        .background(SK.Palette.accent, in: Capsule())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(SK.Space.lg)
        }

        SKChatComposer(
            text: $draft,
            isStreaming: streaming,
            onSend: {
                sent.append(draft)
                draft = ""
                streaming = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    streaming = false
                }
            },
            onStop: { streaming = false },
            onAttach: {},
            onVoice: {}
        )
    }
    .background(SK.Palette.surface)
}
