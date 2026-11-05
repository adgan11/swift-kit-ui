//
//  SKWheelPicker.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A horizontal ruler picker — the control you want for weight, age, duration
//  or tempo. Values snap to centre and tick as they pass.
//
//  WHY THIS OWNS ITS OFFSET INSTEAD OF USING ScrollView
//  ----------------------------------------------------
//  The obvious build is `ScrollView` + `.scrollTargetBehavior(.viewAligned)` +
//  `.scrollPosition(id:)`. It does not work for a centred ruler: `.viewAligned`
//  snaps children to the container's LEADING edge, which fights a centre
//  anchor, and neither `scrollPosition`'s initial value nor
//  `ScrollViewReader.scrollTo` reliably lands when the content sits inside a
//  GeometryReader — the picker opens parked two ticks away from the value its
//  own label is already showing. Verified on iOS 26.2.
//
//  Driving the offset directly is a few more lines and is exactly right every
//  time. Momentum survives because the release projects the gesture's predicted
//  end translation, so a flick still coasts.
//
//  Usage:
//      SKWheelPicker(selection: $weight, values: Array(40...120)) { "\($0) kg" }
//

import SwiftUI

public struct SKWheelPicker<Value: Hashable>: View {
    @Binding private var selection: Value
    private let values: [Value]
    private let title: (Value) -> String
    private let itemWidth: CGFloat

    @GestureState private var dragTranslation: CGFloat = 0
    @State private var settledIndex: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        selection: Binding<Value>,
        values: [Value],
        itemWidth: CGFloat = 64,
        title: @escaping (Value) -> String
    ) {
        self._selection = selection
        self.values = values
        self.itemWidth = itemWidth
        self.title = title
        self._settledIndex = State(
            initialValue: values.firstIndex(of: selection.wrappedValue) ?? 0
        )
    }

    private var lastIndex: CGFloat { CGFloat(max(values.count - 1, 0)) }

    /// Offset that puts `index` under the centre line, given the strip is
    /// centred in its container.
    private func offset(for index: Int) -> CGFloat {
        -(CGFloat(index) - lastIndex / 2) * itemWidth
    }

    /// Where the strip sits right now, including any in-flight drag.
    private var currentOffset: CGFloat {
        offset(for: settledIndex) + dragTranslation
    }

    /// The tick nearest the centre line at this instant. Drives highlighting
    /// live, so values light up under your finger rather than on release.
    private var liveIndex: Int {
        let raw = lastIndex / 2 - currentOffset / itemWidth
        return min(max(Int(raw.rounded()), 0), Int(lastIndex))
    }

    public var body: some View {
        VStack(spacing: SK.Space.sm) {
            Text(title(values[safe: liveIndex] ?? selection))
                .font(SK.Type_.title)
                .foregroundStyle(SK.Palette.label)
                .contentTransition(.numericText())
                .skAnimation(.snap, value: liveIndex)

            ZStack {
                // Window BEHIND the ticks. The previous build drew a thin line
                // on top, which landed on the selected tick and its label and
                // read as a collision rather than an indicator.
                selectionWindow
                viewport
            }
            .frame(height: 76)
            .contentShape(.rect)
            .gesture(drag)
        }
        .onChange(of: liveIndex) { _, new in
            // Tick as each value passes the centre, not only on release.
            guard let value = values[safe: new], value != selection else { return }
            selection = value
            SK.Haptic.play(.light)
        }
        .accessibilityElement()
        .accessibilityValue(Text(title(selection)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(by: 1)
            case .decrement: move(by: -1)
            @unknown default: break
            }
        }
    }

    /// A fixed-size window onto the strip.
    ///
    /// The strip is `values.count * itemWidth` wide — thousands of points — so
    /// it must never size its parent. Hanging it off `Color.clear` as an
    /// OVERLAY does that: overlay content is laid out against the container and
    /// contributes nothing to its measured size. Putting the strip in the view
    /// tree directly stretches the whole screen.
    private var viewport: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { strip }
            .clipped()
            .mask(edgeFade)
    }

    private var strip: some View {
        HStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                tick(value, isSelected: index == liveIndex)
                    .frame(width: itemWidth)
            }
        }
        .offset(x: currentOffset)
        .fixedSize()
    }

    private func tick(_ value: Value, isSelected: Bool) -> some View {
        VStack(spacing: SK.Space.xs) {
            Capsule()
                .fill(isSelected ? SK.Palette.accent : SK.Palette.separator)
                .frame(width: 2, height: isSelected ? 34 : 20)
            Text(title(value))
                .font(SK.Type_.caption)
                .foregroundStyle(isSelected ? SK.Palette.accent : SK.Palette.labelTertiary)
        }
        .frame(maxHeight: .infinity)
        .skAnimation(.snap, value: isSelected)
    }

    /// The centre window. Same idea as a system picker: frame the value rather
    /// than draw a line through it.
    private var selectionWindow: some View {
        RoundedRectangle(cornerRadius: SK.Radius.sm, style: .continuous)
            .fill(SK.Palette.accentSoft.opacity(0.85))
            .overlay {
                RoundedRectangle(cornerRadius: SK.Radius.sm, style: .continuous)
                    .strokeBorder(SK.Palette.accent.opacity(0.35), lineWidth: SK.Stroke.thin)
            }
            .frame(width: itemWidth - 6)
            .frame(maxHeight: .infinity)
            .allowsHitTesting(false)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                // Project the flick so it coasts instead of stopping dead.
                let projected = offset(for: settledIndex) + value.predictedEndTranslation.width
                let raw = lastIndex / 2 - projected / itemWidth
                let target = min(max(Int(raw.rounded()), 0), Int(lastIndex))

                withAnimation(SKMotion.glide.resolved(reduceMotion: reduceMotion)) {
                    settledIndex = target
                }
                if let v = values[safe: target], v != selection {
                    selection = v
                    SK.Haptic.play(.light)
                }
            }
    }

    private func move(by delta: Int) {
        let target = min(max(settledIndex + delta, 0), Int(lastIndex))
        guard target != settledIndex else { return }
        withAnimation(SKMotion.snap.resolved(reduceMotion: reduceMotion)) {
            settledIndex = target
        }
        if let v = values[safe: target] { selection = v }
    }

    /// Fades the ends so values dissolve rather than being chopped by the frame.
    private var edgeFade: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.16),
                .init(color: .black, location: 0.84),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("SKWheelPicker") {
    @Previewable @State var weight = 72
    @Previewable @State var tempo = 120

    VStack(spacing: SK.Space.xxl) {
        SKWheelPicker(selection: $weight, values: Array(40...120)) { "\($0)" }
        SKWheelPicker(selection: $tempo,
                      values: Array(stride(from: 60, through: 200, by: 5))) { "\($0)" }
        Text("Opens on the selected value, every time")
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .padding(.vertical, SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
