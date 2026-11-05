//
//  SKPromptSuggestions.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  The starter prompts on an empty assistant screen, and the follow-ups after a
//  reply.
//
//  This is the highest-leverage surface in a chat app and it is almost always
//  an afterthought. A blank composer asks the user to invent a use case for
//  your product on the spot; four concrete suggestions teach it in a second.
//
//  They arrive on a stagger — roughly 45ms apart — which is slow enough to read
//  as sequence and fast enough that nobody waits. Appearing all at once is not
//  wrong exactly, it just throws away the one moment where the eye will follow
//  a list in order.
//
//  `.wrapped` is the default because on a phone a horizontal rail hides the
//  fourth suggestion off-screen, and a suggestion nobody sees does no work.
//
//  Usage:
//      SKPromptSuggestions(["Summarise this thread", "Draft a reply"]) { send($0) }
//      SKPromptSuggestions(prompts, layout: .rail, onSelect: send)
//

import SwiftUI

public struct SKPrompt: Identifiable, Sendable, Hashable {
    public let id: String
    public let text: String
    public let systemImage: String?

    public init(_ text: String, systemImage: String? = nil, id: String? = nil) {
        self.id = id ?? text
        self.text = text
        self.systemImage = systemImage
    }
}

public struct SKPromptSuggestions: View {
    public enum Layout: Sendable { case wrapped, rail }

    private let prompts: [SKPrompt]
    private let layout: Layout
    private let onSelect: (SKPrompt) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    public init(
        _ prompts: [SKPrompt],
        layout: Layout = .wrapped,
        onSelect: @escaping (SKPrompt) -> Void
    ) {
        self.prompts = prompts
        self.layout = layout
        self.onSelect = onSelect
    }

    public init(
        _ texts: [String],
        layout: Layout = .wrapped,
        onSelect: @escaping (String) -> Void
    ) {
        self.init(texts.map { SKPrompt($0) }, layout: layout) { onSelect($0.text) }
    }

    public var body: some View {
        Group {
            switch layout {
            case .rail:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SK.Space.sm) { chips }
                        .padding(.horizontal, SK.Space.lg)
                }
                // Cancels the rail's own scroll gesture hijacking the vertical
                // scroll of the transcript it usually sits inside.
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

            case .wrapped:
                SKPromptFlow(spacing: SK.Space.sm) { chips }
            }
        }
        .onAppear { shown = true }
    }

    private var chips: some View {
        ForEach(Array(prompts.enumerated()), id: \.element.id) { index, prompt in
            Button {
                onSelect(prompt)
                SK.Haptic.play(.light)
            } label: {
                HStack(spacing: SK.Space.xs + 2) {
                    if let symbol = prompt.systemImage {
                        Image(systemName: symbol)
                            .font(SK.Icon.symbol(SK.Icon.xs, weight: .semibold))
                            .foregroundStyle(SK.Palette.accent)
                    }
                    Text(prompt.text)
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.label)
                        .lineLimit(1)
                }
                .padding(.horizontal, SK.Space.md)
                .padding(.vertical, SK.Space.sm)
                .background(SK.Palette.fill, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
                }
            }
            .buttonStyle(.skPress(scale: 0.96, haptic: nil))
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
            // `skAnimation` has no delay parameter, so the stagger is applied
            // to the resolved curve directly — still routed through SKMotion,
            // and still nil under Reduce Motion.
            .animation(
                SKMotion.settle.resolved(reduceMotion: reduceMotion)?
                    .delay(Double(index) * 0.045),
                value: shown
            )
        }
    }
}

/// Minimal flow layout: lays chips left to right and wraps.
///
/// `LazyVGrid` cannot do this — its columns are fixed, so "Summarise" and
/// "Draft a reply to the procurement thread" would be given identical widths
/// and the short one would sit in a puddle of empty space.
private struct SKPromptFlow: SwiftUI.Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("SKPromptSuggestions") {
    @Previewable @State var picked = "Nothing yet"

    VStack(alignment: .leading, spacing: SK.Space.xl) {
        SKPromptSuggestions([
            SKPrompt("Summarise this thread", systemImage: "text.alignleft"),
            SKPrompt("Draft a reply", systemImage: "arrowshape.turn.up.left"),
            SKPrompt("Find the contract terms", systemImage: "magnifyingglass"),
            SKPrompt("What changed since Friday?", systemImage: "clock.arrow.circlepath"),
        ]) { picked = $0.text }

        Divider().overlay(SK.Palette.separator)

        SKPromptSuggestions(["Explain", "Shorten", "Add sources"], layout: .rail) { picked = $0 }

        Text(picked)
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .padding(SK.Space.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SK.Palette.surface)
}
