//
//  SKVoiceOrb.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  The listening target for voice input — a ring of bars that reacts to the
//  microphone, drawn in a single `Canvas`.
//
//  Two things make this feel like an instrument rather than a decoration.
//
//  The first is asymmetric smoothing. A level meter that rises and falls at the
//  same rate looks like jelly; ears expect a transient to appear instantly and
//  decay slowly. So attack runs at roughly 14/s and release at 5/s, which is
//  the same shape a hardware VU meter has and the reason this tracks speech
//  instead of wobbling around behind it.
//
//  The second is that the ring is driven by two incommensurate waves on top of
//  the real level. A ring modulated by the level alone pumps uniformly — every
//  bar the same length — which instantly reads as fake. The waves break that
//  symmetry without inventing signal that is not there: amplitude is still the
//  microphone, only its distribution around the ring is synthetic.
//
//  Forty-four bars as forty-four `View`s would be forty-four layout passes per
//  frame. `Canvas` draws them in one, which is what keeps this at 60fps next to
//  a live transcript.
//
//  Pass `level` from your audio engine — `AVAudioRecorder.averagePower`
//  normalised to 0...1, or the RMS of an `AVAudioPCMBuffer`.
//
//  Usage:
//      SKVoiceOrb(state: recorder.state, level: recorder.level) { toggle() }
//

import SwiftUI

public enum SKVoiceState: Sendable, Hashable {
    case idle, listening, processing
}

public struct SKVoiceOrb: View {
    private let state: SKVoiceState
    private let level: Double
    private let size: CGFloat
    private let onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The displayed level, chasing `level` with attack/release shaping.
    @State private var smoothed: Double = 0
    @State private var clock: Double = 0
    /// Mirrors of the inputs, for the same reason `SKStreamingText` keeps one:
    /// `.task` captures the view value, so the loop cannot see a `let` that
    /// changed after it started. Without these the ring would freeze at
    /// whatever the level was on the frame the task launched.
    @State private var liveLevel: Double = 0
    @State private var liveState: SKVoiceState = .idle

    private let barCount = 44

    public init(
        state: SKVoiceState = .idle,
        level: Double = 0,
        size: CGFloat = 168,
        onTap: (() -> Void)? = nil
    ) {
        self.state = state
        self.level = level
        self.size = size
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
            SK.Haptic.play(state == .listening ? .rigid : .medium)
        } label: {
            ZStack {
                Canvas(opaque: false) { context, canvasSize in
                    draw(in: &context, size: canvasSize)
                }
                .frame(width: size, height: size)
                // Drawing is pure; it reads state only through these.
                .allowsHitTesting(false)

                glyph
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.skPress(scale: 0.96, haptic: nil))
        .disabled(onTap == nil)
        .onChange(of: level, initial: true) { _, new in liveLevel = new }
        .onChange(of: state, initial: true) { _, new in liveState = new }
        .task(id: reduceMotion) {
            guard !reduceMotion else {
                smoothed = state == .listening ? 0.45 : 0.12
                return
            }
            await run()
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Drive

    private func run() async {
        var last = ContinuousClock.now
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            let now = ContinuousClock.now
            let dt = min(seconds(from: last, to: now), 0.1)
            last = now
            clock += dt

            let target: Double
            switch liveState {
            case .listening: target = min(1, max(0, liveLevel))
            case .processing: target = 0.42
            case .idle: target = 0.07
            }

            // Attack fast, release slow. The whole character of the thing.
            let rate = target > smoothed ? 14.0 : 5.0
            smoothed += (target - smoothed) * min(1, rate * dt)
        }
    }

    private func seconds(from start: ContinuousClock.Instant, to end: ContinuousClock.Instant) -> Double {
        let d = end - start
        return Double(d.components.seconds) + Double(d.components.attoseconds) * 1e-18
    }

    // MARK: Draw

    private func draw(in context: inout GraphicsContext, size canvasSize: CGSize) {
        let centre = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = min(canvasSize.width, canvasSize.height) / 2
        let innerRadius = radius * 0.46
        let barWidth = radius * 0.035
        let baseLength = radius * 0.07
        let reactive = radius * 0.30

        // Glow — scaled by level, so loud speech lights the whole control.
        let glowRadius = innerRadius * (1.15 + smoothed * 0.5)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: radius * 0.16))
            layer.fill(
                Path(ellipseIn: CGRect(
                    x: centre.x - glowRadius, y: centre.y - glowRadius,
                    width: glowRadius * 2, height: glowRadius * 2
                )),
                with: .color(SK.Palette.accent.opacity(0.18 + smoothed * 0.30))
            )
        }

        // Bars.
        let head = clock * 2.4
        for index in 0..<barCount {
            let phase = Double(index) / Double(barCount) * 2 * .pi

            let amplitude: Double
            if state == .processing {
                // A comet running the ring: distance from the head, wrapped.
                var delta = abs(phase - head.truncatingRemainder(dividingBy: 2 * .pi))
                if delta > .pi { delta = 2 * .pi - delta }
                amplitude = exp(-delta * 2.1) * 0.95
            } else {
                // Two waves that do not share a period, so the ring never
                // visibly loops. Amplitude is still the real level.
                let wobble = 0.55
                    + 0.30 * sin(phase * 3 + clock * 2.1)
                    + 0.15 * sin(phase * 7 - clock * 1.3)
                amplitude = smoothed * wobble
            }

            let length = baseLength + reactive * max(0, amplitude)
            let rect = CGRect(
                x: -barWidth / 2,
                y: -(innerRadius + length),
                width: barWidth,
                height: length
            )
            let bar = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                .applying(
                    CGAffineTransform(rotationAngle: phase)
                        .concatenating(CGAffineTransform(translationX: centre.x, y: centre.y))
                )

            let intensity = 0.42 + min(1, amplitude * 1.6) * 0.58
            context.fill(bar, with: .color(SK.Palette.accent.opacity(intensity)))
        }

        // Orb. Lighter at the top-left so it reads as a sphere lit from above
        // rather than a flat disc.
        let orbRect = CGRect(
            x: centre.x - innerRadius, y: centre.y - innerRadius,
            width: innerRadius * 2, height: innerRadius * 2
        )
        context.fill(
            Path(ellipseIn: orbRect),
            with: .radialGradient(
                Gradient(colors: [
                    SK.Palette.accent.opacity(0.95),
                    SK.Palette.accent.opacity(0.62),
                ]),
                center: CGPoint(x: centre.x - innerRadius * 0.28, y: centre.y - innerRadius * 0.34),
                startRadius: 0,
                endRadius: innerRadius * 1.5
            )
        )

        context.stroke(
            Path(ellipseIn: orbRect.insetBy(dx: 0.5, dy: 0.5)),
            with: .color(Color.white.opacity(0.22)),
            lineWidth: 1
        )
    }

    // MARK: Glyph

    private var glyph: some View {
        Image(systemName: symbol)
            .font(SK.Icon.symbol(size * 0.19, weight: .medium))
            .foregroundStyle(Color.white)
            .contentTransition(.symbolEffect(.replace))
            .skAnimation(.snap, value: state)
    }

    private var symbol: String {
        switch state {
        case .idle: "mic.fill"
        case .listening: "waveform"
        case .processing: "ellipsis"
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .idle: "Start voice input"
        case .listening: "Listening. Tap to stop"
        case .processing: "Processing your speech"
        }
    }
}

#Preview("SKVoiceOrb") {
    @Previewable @State var state: SKVoiceState = .listening
    @Previewable @State var level: Double = 0

    VStack(spacing: SK.Space.xxl) {
        SKVoiceOrb(state: state, level: level) {
            state = state == .listening ? .idle : .listening
        }

        Text(String(describing: state).capitalized)
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surface)
    // Stands in for a microphone: speech-shaped bursts with pauses, not a sine
    // wave — a sine makes any orb look good and proves nothing.
    .task {
        while !Task.isCancelled {
            let syllables = Int.random(in: 3...7)
            for _ in 0..<syllables {
                level = Double.random(in: 0.45...1.0)
                try? await Task.sleep(for: .milliseconds(Int.random(in: 90...170)))
                level = Double.random(in: 0.10...0.35)
                try? await Task.sleep(for: .milliseconds(Int.random(in: 60...110)))
            }
            level = 0.04
            try? await Task.sleep(for: .milliseconds(Int.random(in: 500...900)))
        }
    }
}
