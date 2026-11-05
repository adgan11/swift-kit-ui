//
//  SKStreamingText.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Text that arrives the way a model actually sends it, without looking like it.
//
//  This is the component people get wrong, and the reason is not obvious until
//  you have watched a real stream: tokens do not arrive evenly. You get one
//  token, then nothing for 300ms, then forty at once. Bind that straight to a
//  `Text` and the reply lurches — a burst, a stall, a burst — which reads as a
//  slow app even when the response is fast.
//
//  So this does not render `text` directly. It keeps a reveal cursor and drains
//  toward the received length at a smoothed rate, speeding up when it has
//  fallen behind and easing off as it catches up. The output is a steady,
//  readable cadence regardless of how erratic the input was, and because the
//  drain rate is bounded by what is actually received it can never run ahead of
//  the model.
//
//  Pass the accumulated text on every update — not the delta. That makes the
//  component idempotent: a dropped or duplicated chunk cannot desynchronise it.
//
//  Usage:
//      SKStreamingText(reply, isStreaming: isGenerating)
//      SKStreamingText(reply, isStreaming: true, charactersPerSecond: 90)
//

import SwiftUI

public struct SKStreamingText: View {
    private let text: String
    private let isStreaming: Bool
    private let charactersPerSecond: Double
    private let font: Font
    private let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var revealed: Int = 0
    /// Sub-character remainder. Without it, a rate slower than one character
    /// per frame truncates to zero every frame and nothing ever appears.
    @State private var carry: Double = 0
    @State private var caretVisible = true
    @State private var caretClock: Double = 0
    /// A mirror of `text` that the drain loop can actually see.
    ///
    /// `.task` captures the view value, so a `let` property is frozen at the
    /// moment the task started — the loop would keep reading the empty string
    /// it launched with and nothing would ever appear. `@State` reads go
    /// through storage that survives view re-creation, so this one tracks.
    @State private var source: String = ""

    public init(
        _ text: String,
        isStreaming: Bool = true,
        charactersPerSecond: Double = 55,
        font: Font = SK.Type_.body,
        color: Color = SK.Palette.label
    ) {
        self.text = text
        self.isStreaming = isStreaming
        self.charactersPerSecond = charactersPerSecond
        self.font = font
        self.color = color
    }

    /// True once the cursor has consumed everything received so far.
    private var caughtUp: Bool { revealed >= source.count }

    private var visible: String {
        guard revealed < text.count else { return text }
        let end = text.index(text.startIndex, offsetBy: revealed, limitedBy: text.endIndex)
            ?? text.endIndex
        return String(text[..<end])
    }

    /// Shown while more is expected. Once the stream closes it disappears, so a
    /// finished reply is not left with a cursor blinking at the end of it.
    private var showsCaret: Bool {
        isStreaming && !reduceMotion
    }

    public var body: some View {
        // Concatenated rather than placed in an HStack: the caret has to sit on
        // the last line, after the final glyph, and only text composition can
        // put it there. The glyph is always drawn and only its colour changes,
        // so blinking never reflows the paragraph.
        (
            Text(visible)
                .font(font)
                .foregroundStyle(color)
            + Text(showsCaret ? "\u{258C}" : "")
                .font(font)
                .foregroundStyle(caretVisible ? SK.Palette.accent : Color.clear)
        )
        .fixedSize(horizontal: false, vertical: true)
        .textSelection(.enabled)
        .onChange(of: text, initial: true) { _, new in
            // A replaced message (new turn, regenerate) restarts the reveal;
            // an appended chunk continues it.
            if !new.hasPrefix(source) { reset() }
            source = new
            if reduceMotion { revealed = new.count }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            await drain()
        }
        .accessibilityLabel(text)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func reset() {
        revealed = 0
        carry = 0
    }

    /// Advances the reveal cursor once per frame for as long as the view lives.
    private func drain() async {
        var last = ContinuousClock.now
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            let now = ContinuousClock.now
            let dt = seconds(from: last, to: now)
            last = now
            // A backgrounded app resumes with a huge dt; clamping stops the
            // whole buffer flushing in a single frame on return.
            step(dt: min(dt, 0.1))
        }
    }

    private func step(dt: Double) {
        advanceCaret(dt: dt)

        let pending = source.count - revealed
        guard pending > 0 else { return }

        // Catch-up: the further behind the cursor is, the faster it drains.
        // Capped at 5x so a large paste still reads as typing rather than
        // snapping in, and floored at 1x so it never crawls.
        let catchUp = 1 + min(Double(pending) / 40, 4)
        carry += charactersPerSecond * catchUp * dt

        let whole = Int(carry)
        guard whole > 0 else { return }
        carry -= Double(whole)
        revealed = min(source.count, revealed + whole)
    }

    private func advanceCaret(dt: Double) {
        guard showsCaret else {
            caretVisible = true
            return
        }
        // Solid while glyphs are landing, blinking only once the cursor has
        // drained and is waiting on the model. The difference is what makes a
        // stall read as "thinking" instead of "stuck".
        guard caughtUp else {
            caretClock = 0
            caretVisible = true
            return
        }
        caretClock += dt
        if caretClock >= 0.53 {
            caretClock = 0
            caretVisible.toggle()
        }
    }

    private func seconds(from start: ContinuousClock.Instant, to end: ContinuousClock.Instant) -> Double {
        let d = end - start
        return Double(d.components.seconds) + Double(d.components.attoseconds) * 1e-18
    }
}

#Preview("SKStreamingText") {
    @Previewable @State var received = ""
    @Previewable @State var streaming = true

    let full = """
    Revenue grew 12% this quarter and churn fell to 1.8%. The gain is \
    concentrated in annual plans, which now account for 61% of new subscriptions \
    — up from 44% in Q2. Monthly conversion was flat, so the shift looks like \
    pricing rather than demand.
    """

    VStack(alignment: .leading, spacing: SK.Space.lg) {
        SKStreamingText(received, isStreaming: streaming)
            .frame(maxWidth: .infinity, alignment: .leading)

        Button("Replay") {
            received = ""
            streaming = true
        }
        .font(SK.Type_.callout)
        .foregroundStyle(SK.Palette.accent)
        .buttonStyle(.skPress)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(SK.Palette.surface)
    // Deliberately uneven chunks — this is what a real stream looks like, and
    // the point of the component is that the output does not show it.
    .task(id: received.isEmpty) {
        guard received.isEmpty else { return }
        var index = full.startIndex
        while index < full.endIndex {
            let burst = [1, 1, 2, 14, 1, 3, 28, 1, 1, 9].randomElement() ?? 3
            let next = full.index(index, offsetBy: burst, limitedBy: full.endIndex) ?? full.endIndex
            received += String(full[index..<next])
            index = next
            try? await Task.sleep(for: .milliseconds([40, 60, 90, 260].randomElement() ?? 60))
        }
        streaming = false
    }
}
