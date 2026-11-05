//
//  SKToolCallCard.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  What the agent is doing, while it does it.
//
//  An assistant that calls tools goes quiet at exactly the moment it is working
//  hardest. Users read that silence as a hang, and the fix is not a spinner —
//  it is naming the action. "Running `search_web`" with a live bar is a
//  different experience from three seconds of nothing, even though it is the
//  same three seconds.
//
//  The tool name is set in monospace deliberately: it is an identifier, not
//  prose, and rendering it as prose invites people to read it as a sentence.
//  Arguments and results stay collapsed, because in the common case nobody
//  wants them and in the debugging case nothing else will do.
//
//  Usage:
//      SKToolCallCard("search_web", summary: "Q3 revenue", state: .running)
//      SKToolCallCard("read_file", state: .success, detail: json, duration: 0.42)
//

import SwiftUI

public enum SKToolCallState: Sendable, Hashable {
    case running, success, failure
}

public struct SKToolCallCard: View {
    private let name: String
    private let summary: String?
    private let state: SKToolCallState
    private let detail: String?
    private let duration: TimeInterval?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    @State private var sweep: CGFloat = -1
    @State private var pulse = false

    public init(
        _ name: String,
        summary: String? = nil,
        state: SKToolCallState = .running,
        detail: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.name = name
        self.summary = summary
        self.state = state
        self.detail = detail
        self.duration = duration
    }

    private var tint: Color {
        switch state {
        case .running: SK.Palette.accent
        case .success: SK.Palette.success
        case .failure: SK.Palette.danger
        }
    }

    private var tintSoft: Color {
        switch state {
        case .running: SK.Palette.accentSoft
        case .success: SK.Palette.successSoft
        case .failure: SK.Palette.dangerSoft
        }
    }

    private var symbol: String {
        switch state {
        case .running: "wrench.and.screwdriver.fill"
        case .success: "checkmark"
        case .failure: "exclamationmark.triangle.fill"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                guard detail != nil else { return }
                expanded.toggle()
                SK.Haptic.play(.light)
            } label: {
                headerRow
            }
            .buttonStyle(.skPress(scale: 0.995, haptic: nil))
            .disabled(detail == nil)

            if state == .running { progressBar }

            if expanded, let detail {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(detail)
                        .font(SK.Type_.monoCaption)
                        .foregroundStyle(SK.Palette.labelSecondary)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, SK.Space.md)
                .padding(.bottom, SK.Space.md)
                .transition(.opacity)
            }
        }
        .background(SK.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                .strokeBorder(state == .running ? tint.opacity(0.35) : SK.Palette.separator,
                              lineWidth: SK.Stroke.thin)
        }
        .skAnimation(.snap, value: expanded)
        .skAnimation(.settle, value: state)
    }

    private var headerRow: some View {
        HStack(spacing: SK.Space.md) {
            ZStack {
                RoundedRectangle(cornerRadius: SK.Radius.sm, style: .continuous)
                    .fill(tintSoft)
                    .frame(width: 30, height: 30)
                Image(systemName: symbol)
                    .font(SK.Icon.symbol(SK.Icon.sm, weight: .bold))
                    .foregroundStyle(tint)
            }
            // A slow breath rather than a spin: the card already has a
            // progress bar, and two things moving at different rates in one
            // 30pt square reads as noise.
            .scaleEffect(pulse ? 1.06 : 1)
            .opacity(pulse ? 1 : 0.82)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(SK.Type_.monoCaption)
                    .foregroundStyle(SK.Palette.label)
                    .lineLimit(1)
                if let summary {
                    Text(summary)
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if let duration, state != .running {
                Text(String(format: "%.2fs", duration))
                    .font(SK.Type_.caption)
                    .monospacedDigit()
                    .foregroundStyle(SK.Palette.labelTertiary)
            }

            if detail != nil {
                Image(systemName: "chevron.down")
                    .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                    .foregroundStyle(SK.Palette.labelTertiary)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
                    .skAnimation(.snap, value: expanded)
            }
        }
        .padding(SK.Space.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tool \(name), \(accessibilityState)")
    }

    private var accessibilityState: String {
        switch state {
        case .running: "running"
        case .success: "completed"
        case .failure: "failed"
        }
    }

    /// Indeterminate, because a tool call has no measurable progress. It exists
    /// to prove the app is alive, which is a different job from reporting how
    /// far along something is — so it never pretends to fill.
    private var progressBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            Capsule()
                .fill(tint)
                .frame(width: max(width * 0.34, 40))
                .offset(x: reduceMotion ? width * 0.33 : sweep * width)
                .opacity(reduceMotion ? 0.5 : 1)
        }
        .frame(height: 3)
        .background(SK.Palette.fill)
        .clipShape(Capsule())
        .padding(.horizontal, SK.Space.md)
        .padding(.bottom, SK.Space.md)
        .onAppear {
            guard !reduceMotion else { return }
            sweep = -0.4
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: false)) {
                sweep = 1.05
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("SKToolCallCard") {
    @Previewable @State var state: SKToolCallState = .running

    VStack(spacing: SK.Space.md) {
        SKToolCallCard(
            "search_web",
            summary: "q3 saas churn benchmarks 2026",
            state: state,
            detail: #"{ "query": "q3 saas churn benchmarks 2026", "top_k": 5 }"#,
            duration: 1.24
        )

        SKToolCallCard(
            "read_file",
            summary: "Sources/Billing/Renewals.swift",
            state: .success,
            detail: "418 lines · 14.2 KB",
            duration: 0.42
        )

        SKToolCallCard(
            "run_query",
            summary: "connection refused on replica-2",
            state: .failure,
            detail: "psql: error: connection to server at \"replica-2\" failed",
            duration: 8.01
        )
    }
    .padding(SK.Space.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SK.Palette.surface)
    .task {
        try? await Task.sleep(for: .seconds(3))
        state = .success
    }
}
