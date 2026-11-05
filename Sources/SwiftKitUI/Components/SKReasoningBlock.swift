//
//  SKReasoningBlock.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  The collapsible "thinking" disclosure, with the one detail that makes it
//  worth having: while the model is reasoning, the block shows the line it is
//  currently on.
//
//  A spinner labelled "Thinking…" tells the user nothing and makes five seconds
//  feel like thirty. A single line of the actual reasoning, replaced as it
//  moves, turns dead time into something to read — and it is honest, because it
//  is the real text rather than a progress fiction. Collapsed, it costs one
//  line of layout; expanded, it is the full trace.
//
//  When reasoning ends the header settles into "Thought for 4s", because the
//  duration is the part people actually want afterwards.
//
//  Usage:
//      SKReasoningBlock(reasoning, isThinking: model.isReasoning)
//      SKReasoningBlock(reasoning, isThinking: false, duration: 4.2)
//

import SwiftUI

public struct SKReasoningBlock: View {
    private let text: String
    private let isThinking: Bool
    private let providedDuration: TimeInterval?
    private let title: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    @State private var elapsed: TimeInterval = 0
    @State private var settledDuration: TimeInterval?

    public init(
        _ text: String,
        isThinking: Bool = false,
        duration: TimeInterval? = nil,
        title: String = "Thinking"
    ) {
        self.text = text
        self.isThinking = isThinking
        self.providedDuration = duration
        self.title = title
    }

    /// The last non-empty line — what the model is working on right now.
    private var currentLine: String {
        text.components(separatedBy: .newlines)
            .last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }

    private var shownDuration: TimeInterval? {
        providedDuration ?? settledDuration
    }

    private var headerText: String {
        if isThinking { return title }
        if let shownDuration { return "Thought for \(format(shownDuration))" }
        return "Reasoning"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if expanded {
                Text(text.isEmpty ? "No reasoning recorded." : text)
                    .font(SK.Type_.callout)
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, SK.Space.md)
                    .padding(.bottom, SK.Space.md)
                    .transition(.opacity)
            } else if isThinking && !currentLine.isEmpty {
                livePreview
            }
        }
        .background(SK.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
        }
        .skAnimation(.snap, value: expanded)
        .skAnimation(.snap, value: isThinking)
        .task(id: isThinking) {
            guard isThinking else { return }
            elapsed = 0
            // Ticking at 10Hz rather than 60: the label shows tenths, so
            // anything faster is work nobody can see.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                elapsed += 0.1
            }
        }
        .onChange(of: isThinking) { was, now in
            // Freeze the measured time the moment reasoning stops, so the
            // header keeps reporting it after the timer task is cancelled.
            if was && !now { settledDuration = elapsed }
        }
    }

    // MARK: Header

    private var header: some View {
        Button {
            expanded.toggle()
            SK.Haptic.play(.light)
        } label: {
            HStack(spacing: SK.Space.sm) {
                Image(systemName: isThinking ? "sparkles" : "checkmark.circle.fill")
                    .font(SK.Icon.symbol(SK.Icon.sm))
                    .foregroundStyle(isThinking ? SK.Palette.accent : SK.Palette.labelTertiary)

                Text(headerText)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .skShimmer(isThinking && !reduceMotion)

                if isThinking {
                    Text(format(elapsed))
                        .font(SK.Type_.caption)
                        .monospacedDigit()
                        .foregroundStyle(SK.Palette.labelTertiary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                    .foregroundStyle(SK.Palette.labelTertiary)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
                    .skAnimation(.snap, value: expanded)
            }
            .padding(.horizontal, SK.Space.md)
            .padding(.vertical, SK.Space.sm + 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.skPress(scale: 0.995, haptic: nil))
        .accessibilityLabel(headerText)
        .accessibilityHint(expanded ? "Collapse reasoning" : "Expand reasoning")
    }

    // MARK: Live line

    private var livePreview: some View {
        Text(currentLine)
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SK.Space.md)
            .padding(.bottom, SK.Space.md)
            // Keyed on the text so each new line is a *different* view and can
            // therefore transition. Without the id SwiftUI reuses the same
            // Text and the content simply swaps with no movement at all.
            .id(currentLine)
            .transition(
                reduceMotion
                    ? .opacity
                    : .push(from: .bottom).combined(with: .opacity)
            )
            .clipped()
            .skAnimation(.snap, value: currentLine)
            .accessibilityHidden(true)
    }

    private func format(_ seconds: TimeInterval) -> String {
        seconds < 10
            ? String(format: "%.1fs", max(0, seconds))
            : String(format: "%.0fs", seconds)
    }
}

#Preview("SKReasoningBlock") {
    @Previewable @State var trace = ""
    @Previewable @State var thinking = true

    let steps = [
        "Looking at the Q3 revenue table.",
        "Annual plans are 61% of new subscriptions, up from 44%.",
        "Checking whether monthly conversion moved at all.",
        "Monthly is flat at 3.1% — so this is a mix shift, not demand.",
        "Confirming churn: 1.8%, down from 2.4%.",
    ]

    VStack(spacing: SK.Space.lg) {
        SKReasoningBlock(trace, isThinking: thinking)

        SKReasoningBlock(
            steps.joined(separator: "\n"),
            isThinking: false,
            duration: 4.2
        )
    }
    .padding(SK.Space.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SK.Palette.surface)
    .task(id: trace.isEmpty) {
        guard trace.isEmpty else { return }
        thinking = true
        for step in steps {
            try? await Task.sleep(for: .milliseconds(1100))
            trace += (trace.isEmpty ? "" : "\n") + step
        }
        try? await Task.sleep(for: .milliseconds(600))
        thinking = false
    }
}
