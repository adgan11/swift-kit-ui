//
//  SKMessageActions.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Copy, regenerate and rate — the row under an assistant reply.
//
//  Two decisions carry this component. First, copy confirms *in place*: the
//  glyph becomes a tick for a moment and the row does not resize, because a
//  toast for something this small is a sledgehammer and a button that silently
//  does nothing visible gets pressed three times.
//
//  Second, the rating is exclusive and latching. Thumbs that can both be lit,
//  or that reset on the next render, produce feedback data you cannot use —
//  and users notice immediately that their answer did not stick.
//
//  The row is deliberately quiet: tertiary glyphs, no fills, no borders. It
//  lives under every single reply, so anything louder competes with the reply
//  itself.
//
//  Usage:
//      SKMessageActions(copyText: reply, feedback: $rating, onRegenerate: retry)
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum SKMessageFeedback: Sendable, Hashable {
    case none, positive, negative
}

public struct SKMessageActions: View {
    private let copyText: String?
    @Binding private var feedback: SKMessageFeedback
    private let onRegenerate: (() -> Void)?
    private let onShare: (() -> Void)?
    private let onCopy: (() -> Void)?

    @State private var copied = false

    public init(
        copyText: String? = nil,
        feedback: Binding<SKMessageFeedback> = .constant(.none),
        onRegenerate: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onCopy: (() -> Void)? = nil
    ) {
        self.copyText = copyText
        self._feedback = feedback
        self.onRegenerate = onRegenerate
        self.onShare = onShare
        self.onCopy = onCopy
    }

    public var body: some View {
        HStack(spacing: SK.Space.xs) {
            if copyText != nil {
                action(
                    symbol: copied ? "checkmark" : "doc.on.doc",
                    label: copied ? "Copied" : "Copy",
                    tint: copied ? SK.Palette.success : SK.Palette.labelTertiary,
                    perform: copy
                )
            }

            if let onRegenerate {
                action(symbol: "arrow.clockwise", label: "Regenerate", tint: SK.Palette.labelTertiary) {
                    onRegenerate()
                    SK.Haptic.play(.light)
                }
            }

            if let onShare {
                action(symbol: "square.and.arrow.up", label: "Share", tint: SK.Palette.labelTertiary) {
                    onShare()
                    SK.Haptic.play(.light)
                }
            }

            action(
                symbol: feedback == .positive ? "hand.thumbsup.fill" : "hand.thumbsup",
                label: "Good response",
                tint: feedback == .positive ? SK.Palette.success : SK.Palette.labelTertiary
            ) {
                // Tapping the lit thumb clears it: a rating you cannot take
                // back is one people stop giving.
                feedback = feedback == .positive ? .none : .positive
                SK.Haptic.play(feedback == .positive ? .success : .light)
            }

            action(
                symbol: feedback == .negative ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                label: "Bad response",
                tint: feedback == .negative ? SK.Palette.danger : SK.Palette.labelTertiary
            ) {
                feedback = feedback == .negative ? .none : .negative
                SK.Haptic.play(.light)
            }
        }
        .skAnimation(.snap, value: feedback)
        .skAnimation(.snap, value: copied)
    }

    private func action(
        symbol: String,
        label: String,
        tint: Color,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Image(systemName: symbol)
                .font(SK.Icon.symbol(SK.Icon.sm))
                .foregroundStyle(tint)
                // The glyph is small; the target is not. 30pt with the row's
                // own padding clears Apple's minimum without the icons
                // drifting apart visually.
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.skPress(scale: 0.85, haptic: nil))
        .accessibilityLabel(label)
    }

    private func copy() {
        guard let copyText else { return }
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        UIPasteboard.general.string = copyText
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(copyText, forType: .string)
        #endif
        onCopy?()
        SK.Haptic.play(.success)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            copied = false
        }
    }
}

#Preview("SKMessageActions") {
    @Previewable @State var rating: SKMessageFeedback = .none

    VStack(alignment: .leading, spacing: SK.Space.md) {
        Text("Annual plans now account for 61% of new subscriptions, up from 44% in Q2. Monthly conversion was flat, so the shift looks like pricing rather than demand.")
            .font(SK.Type_.body)
            .foregroundStyle(SK.Palette.label)
            .fixedSize(horizontal: false, vertical: true)

        SKMessageActions(
            copyText: "Annual plans now account for 61% of new subscriptions.",
            feedback: $rating,
            onRegenerate: {},
            onShare: {}
        )
        .padding(.leading, -SK.Space.sm)

        Text("Rating: \(String(describing: rating))")
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(SK.Palette.surface)
}
