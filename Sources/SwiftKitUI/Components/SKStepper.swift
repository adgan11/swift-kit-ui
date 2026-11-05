//
//  SKStepper.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Minus / value / plus, with press-and-hold repeat that accelerates.
//
//  The number uses `.contentTransition(.numericText())` so digits roll rather
//  than pop — at hold speed a popping label reads as flicker.
//
//  Usage:
//      SKStepper(value: $quantity, in: 1...99)
//

import SwiftUI

public struct SKStepper: View {
    @Binding private var value: Int
    private let range: ClosedRange<Int>
    private let stepBy: Int

    @State private var repeatTask: Task<Void, Never>?
    @Environment(\.isEnabled) private var isEnabled

    public init(value: Binding<Int>, in range: ClosedRange<Int> = 0...99, stepBy: Int = 1) {
        self._value = value
        self.range = range
        self.stepBy = stepBy
    }

    public var body: some View {
        HStack(spacing: 0) {
            button("minus", enabled: value > range.lowerBound, delta: -stepBy)

            Text("\(value)")
                .font(SK.Type_.numeric)
                .foregroundStyle(SK.Palette.label)
                .contentTransition(.numericText())
                .skAnimation(.snap, value: value)
                .frame(minWidth: 44)
                .accessibilityHidden(true)

            button("plus", enabled: value < range.upperBound, delta: stepBy)
        }
        .padding(.horizontal, SK.Space.xs)
        .frame(height: SK.Icon.hitTarget)
        .background(SK.Palette.fill, in: Capsule(style: .continuous))
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityElement()
        .accessibilityValue(Text("\(value)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: bump(stepBy)
            case .decrement: bump(-stepBy)
            @unknown default: break
            }
        }
    }

    private func button(_ symbol: String, enabled: Bool, delta: Int) -> some View {
        Image(systemName: symbol)
            .font(SK.Icon.symbol(SK.Icon.sm, weight: .bold))
            .foregroundStyle(enabled ? SK.Palette.label : SK.Palette.labelTertiary)
            .frame(width: SK.Icon.hitTarget, height: SK.Icon.hitTarget)
            .contentShape(.rect)
            .onLongPressGesture(minimumDuration: 0.35) {
                // Long press begins the repeat; the tap case is handled below.
                startRepeating(delta)
            } onPressingChanged: { pressing in
                if !pressing {
                    stopRepeating()
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded { bump(delta) }
            )
            .disabled(!enabled)
            .accessibilityHidden(true)
    }

    private func bump(_ delta: Int) {
        let next = min(max(value + delta, range.lowerBound), range.upperBound)
        guard next != value else {
            SK.Haptic.play(.rigid)   // hit the end of the range
            return
        }
        value = next
        SK.Haptic.play(.light)
    }

    private func startRepeating(_ delta: Int) {
        stopRepeating()
        repeatTask = Task { @MainActor in
            var interval: Duration = .milliseconds(220)
            while !Task.isCancelled {
                bump(delta)
                try? await Task.sleep(for: interval)
                // Accelerate, but floor it so it never becomes uncontrollable.
                interval = max(.milliseconds(45), interval - .milliseconds(35))
            }
        }
    }

    private func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
    }
}

#Preview("SKStepper") {
    @Previewable @State var qty = 1
    @Previewable @State var people = 12

    VStack(spacing: SK.Space.xl) {
        SKStepper(value: $qty, in: 1...20)
        SKStepper(value: $people, in: 0...99, stepBy: 2)
        SKStepper(value: .constant(5)).disabled(true)
        Text("Hold to repeat").font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
