//
//  SKConfetti.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A celebration burst for purchases, streaks and completions.
//
//  Three things separate confetti that looks good from confetti that looks
//  cheap, and all three are here:
//
//  1. A CURATED palette. Random hues produce muddy olives and browns alongside
//     the good colours, and the eye reads the worst one.
//  2. FLUTTER. Real confetti is flat paper tumbling edge-on, so each piece
//     squashes horizontally on a sine wave. Pieces that only translate and spin
//     look like falling stickers.
//  3. VARIED pieces — streamers, squares and discs at different sizes, each
//     with its own spin and drift, so no two follow the same arc.
//
//  Drawn in a single `Canvas` rather than N views: 160 SwiftUI nodes being laid
//  out per frame will stutter, 160 immediate-mode shapes will not.
//
//  lint:allow hard-coded-color — confetti needs its own vivid palette; the
//  semantic tokens are tuned for legible UI, not for celebration.
//
//  Usage:
//      .skConfetti(trigger: purchaseCount)
//

import SwiftUI

private struct SKConfettiPiece {
    enum Shape_ { case strip, square, disc }

    var x: Double            // 0…1 of width
    var y: Double            // 0…1 of height
    var vx: Double
    var vy: Double
    var spin: Double
    var spinPhase: Double
    var flutter: Double      // horizontal squash rate
    var width: Double
    var height: Double
    var colorIndex: Int
    var shape: Shape_
}

private struct SKConfettiModifier<T: Equatable>: ViewModifier {
    let trigger: T
    let intensity: Int

    @State private var pieces: [SKConfettiPiece] = []
    @State private var startedAt: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let duration: Double = 3.0

    /// Hand-picked so every piece lands somewhere pleasant.
    private static var palette: [Color] {
        [
            Color(red: 0.48, green: 0.23, blue: 0.93),  // violet
            Color(red: 0.95, green: 0.35, blue: 0.55),  // rose
            Color(red: 1.00, green: 0.72, blue: 0.20),  // amber
            Color(red: 0.18, green: 0.80, blue: 0.55),  // mint
            Color(red: 0.25, green: 0.60, blue: 0.98),  // azure
            Color(red: 1.00, green: 0.45, blue: 0.30),  // coral
            Color(red: 0.62, green: 0.85, blue: 0.30),  // lime
        ]
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if startedAt != nil {
                    TimelineView(.animation) { timeline in
                        Canvas { context, size in
                            draw(in: &context, size: size, now: timeline.date)
                        }
                        .allowsHitTesting(false)
                    }
                    .ignoresSafeArea()
                }
            }
            .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        guard !reduceMotion else { return }
        pieces = (0..<intensity).map { _ in
            // A wide upward cone from just below the centre, so the burst
            // rises, spreads, then falls back through the frame.
            let angle = Double.random(in: (-.pi * 0.78)...(-.pi * 0.22))
            let speed = Double.random(in: 0.95...1.85)
            let shape: SKConfettiPiece.Shape_ = {
                let r = Double.random(in: 0...1)
                return r < 0.55 ? .strip : (r < 0.85 ? .square : .disc)
            }()
            let w = Double.random(in: 5...9)
            return SKConfettiPiece(
                x: Double.random(in: 0.35...0.65),
                y: 0.62,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                spin: Double.random(in: -7...7),
                spinPhase: Double.random(in: 0...(.pi * 2)),
                flutter: Double.random(in: 4...9),
                width: w,
                height: shape == .strip ? w * Double.random(in: 2.0...3.2) : w,
                colorIndex: Int.random(in: 0..<Self.palette.count),
                shape: shape
            )
        }
        startedAt = Date()
        SK.Haptic.play(.success)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            startedAt = nil
            pieces = []
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, now: Date) {
        guard let startedAt else { return }
        let t = now.timeIntervalSince(startedAt)
        guard t < duration else { return }

        let gravity = 1.65
        let drag = 0.55                       // air resistance on horizontal drift
        let colors = Self.palette
        // Hold full opacity most of the way, then fade out at the end.
        let fade = t < duration * 0.62 ? 1.0 : max(0, 1 - (t - duration * 0.62) / (duration * 0.38))

        for piece in pieces {
            let driftX = piece.vx * (1 - exp(-drag * t)) / drag
            let px = (piece.x + driftX * 0.55) * size.width
            let py = (piece.y + piece.vy * t + 0.5 * gravity * t * t) * size.height
            guard py > -60, py < size.height + 60 else { continue }

            // Flat paper tumbling edge-on: the piece narrows to nothing and
            // opens out again. This is what sells it as confetti.
            let flutter = cos(t * piece.flutter + piece.spinPhase)
            let w = piece.width * max(0.15, abs(flutter))
            let rect = CGRect(x: -w / 2, y: -piece.height / 2, width: w, height: piece.height)

            var layer = context
            layer.opacity = fade
            layer.translateBy(x: px, y: py)
            layer.rotate(by: .radians(piece.spinPhase + piece.spin * t))

            let path: Path
            switch piece.shape {
            case .strip:  path = Path(roundedRect: rect, cornerRadius: 1)
            case .square: path = Path(roundedRect: rect, cornerRadius: 1.5)
            case .disc:   path = Path(ellipseIn: rect)
            }
            // Edge-on pieces read darker, like paper turning away from the light.
            let shade = 0.72 + 0.28 * abs(flutter)
            layer.fill(path, with: .color(colors[piece.colorIndex].opacity(shade)))
        }
    }
}

extension View {
    /// Bursts confetti whenever `trigger` changes. No-op under Reduce Motion.
    public func skConfetti<T: Equatable>(trigger: T, intensity: Int = 160) -> some View {
        modifier(SKConfettiModifier(trigger: trigger, intensity: intensity))
    }
}

#Preview("SKConfetti") {
    @Previewable @State var count = 0

    VStack(spacing: SK.Space.xl) {
        Image(systemName: "party.popper.fill")
            .font(SK.Icon.symbol(56))
            .foregroundStyle(SK.Palette.accent)
        Button("Celebrate") { count += 1 }
            .font(SK.Type_.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, SK.Space.xl)
            .padding(.vertical, SK.Space.md)
            .background(Capsule().fill(SK.Palette.accent))
            .buttonStyle(.skPress)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
    .skConfetti(trigger: count)
}
