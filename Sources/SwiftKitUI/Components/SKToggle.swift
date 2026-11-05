//
//  SKToggle.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A toggle you can *drag*, not just tap. That one detail is most of why the
//  system switch feels expensive and a hand-rolled one usually does not — the
//  knob tracks your finger, squashes while held, and commits on release using
//  gesture velocity rather than a naive midpoint test.
//
//  Usage:
//      Toggle("Wi-Fi", isOn: $isOn).toggleStyle(.sk)
//      Toggle("Wi-Fi", isOn: $isOn).toggleStyle(.sk(.liquidGlass))
//

import SwiftUI

public struct SKToggleStyle: ToggleStyle {
    public enum Track: Sendable {
        /// Solid fill that crossfades to the accent colour.
        case solid
        /// iOS 26 Liquid Glass, with an approximation below iOS 26.
        case liquidGlass
    }

    private let track: Track
    private let width: CGFloat
    private let height: CGFloat

    public init(_ track: Track = .solid, width: CGFloat = 52, height: CGFloat = 32) {
        self.track = track
        self.width = width
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        SKToggleBody(
            configuration: configuration,
            track: track,
            width: width,
            height: height
        )
    }
}

private struct SKToggleBody: View {
    let configuration: ToggleStyleConfiguration
    let track: SKToggleStyle.Track
    let width: CGFloat
    let height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    /// Live finger offset while dragging, in points from the resting position.
    @State private var dragOffset: CGFloat = 0
    @State private var isPressed = false

    private var inset: CGFloat { 3 }
    private var knobSize: CGFloat { height - inset * 2 }
    private var travel: CGFloat { width - knobSize - inset * 2 }

    /// Resting x-offset for the current state, before any drag is applied.
    private var restingOffset: CGFloat {
        configuration.isOn ? travel : 0
    }

    /// Clamped so the knob can never leave the track, however far the finger goes.
    private var knobOffset: CGFloat {
        min(max(restingOffset + dragOffset, 0), travel)
    }

    /// A held knob widens slightly, exactly like the system switch. Purely
    /// cosmetic, and the single cheapest way to make this feel native.
    private var knobWidth: CGFloat {
        isPressed ? knobSize + 4 : knobSize
    }

    /// 0…1 across the track. Drives the colour crossfade so the track lights up
    /// progressively under the finger instead of snapping at the end.
    private var progress: CGFloat {
        travel > 0 ? knobOffset / travel : 0
    }

    var body: some View {
        HStack(spacing: 0) {
            // The label area is its own tap target. In a settings list the
            // whole row should toggle, not just the 52pt switch — a fresh
            // agent building a settings screen hit this immediately.
            // Kept separate from the switch so the two gestures never race.
            HStack {
                configuration.label
                Spacer(minLength: SK.Space.md)
            }
            .contentShape(.rect)
            .onTapGesture { commit(to: !configuration.isOn) }

            switchBody
        }
        .frame(minHeight: SK.Icon.hitTarget)
    }

    /// Single commit path for both the row tap and the drag release, so the
    /// animation and haptic can never diverge between the two.
    private func commit(to newValue: Bool) {
        guard isEnabled, newValue != configuration.isOn else { return }
        withAnimation(SKMotion.snap.resolved(reduceMotion: reduceMotion)) {
            configuration.isOn = newValue
        }
        SK.Haptic.play(.selection)
    }

    private var switchBody: some View {
        ZStack(alignment: .leading) {
            trackView
            knobView
                .frame(width: knobWidth, height: knobSize)
                .offset(x: knobOffset)
                .padding(inset)
        }
        .frame(width: width, height: height)
        .opacity(isEnabled ? 1 : 0.45)
        .skAnimation(.snap, value: configuration.isOn)
        .skAnimation(.micro, value: isPressed)
        .gesture(dragGesture, isEnabled: isEnabled)
        .accessibilityAddTraits(configuration.isOn ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var trackView: some View {
        let shape = Capsule(style: .continuous)
        switch track {
        case .solid:
            shape
                .fill(SK.Palette.fill)
                .overlay {
                    // Crossfaded rather than swapped so a partial drag shows a
                    // partial colour — the state reads before you commit to it.
                    shape.fill(SK.Palette.accent).opacity(progress)
                }
                .overlay {
                    shape.strokeBorder(SK.Palette.separator.opacity(1 - progress), lineWidth: SK.Stroke.hairline)
                }
        case .liquidGlass:
            Color.clear
                .skSurface(.liquidGlass, radius: height / 2)
                .overlay {
                    shape.fill(SK.Palette.accent).opacity(progress * 0.85)
                }
        }
    }

    private var knobView: some View {
        Capsule(style: .continuous)
            .fill(.white)
            .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
            .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 0)
    }

    private var dragGesture: some Gesture {
        // minimumDistance 0 so the knob reacts to a plain tap as well, which
        // keeps one code path for both interactions.
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isPressed { isPressed = true }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                isPressed = false

                // Project where the knob would land if the finger kept its
                // current velocity. Using predicted rather than final position
                // is what makes a fast flick commit even when it is short.
                let projected = restingOffset + value.predictedEndTranslation.width
                let shouldBeOn = projected > travel / 2
                dragOffset = 0
                commit(to: shouldBeOn)
            }
    }
}

extension ToggleStyle where Self == SKToggleStyle {
    /// `Toggle(...).toggleStyle(.sk)`
    public static var sk: SKToggleStyle { SKToggleStyle() }

    /// `Toggle(...).toggleStyle(.sk(.liquidGlass))`
    public static func sk(
        _ track: SKToggleStyle.Track,
        width: CGFloat = 52,
        height: CGFloat = 32
    ) -> SKToggleStyle {
        SKToggleStyle(track, width: width, height: height)
    }
}

#Preview("SKToggle") {
    @Previewable @State var a = true
    @Previewable @State var b = false
    @Previewable @State var c = true

    VStack(spacing: SK.Space.xl) {
        Toggle("Solid, on", isOn: $a).toggleStyle(.sk)
        Toggle("Solid, off", isOn: $b).toggleStyle(.sk)
        Toggle("Liquid Glass", isOn: $c).toggleStyle(.sk(.liquidGlass))
        Toggle("Disabled", isOn: .constant(true)).toggleStyle(.sk).disabled(true)
    }
    .font(SK.Type_.body)
    .foregroundStyle(SK.Palette.label)
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
