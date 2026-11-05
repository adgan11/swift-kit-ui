//
//  SKRating.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Star rating you can tap or drag across. Dragging is the part most
//  implementations skip, and it is how people actually set a rating once they
//  realise it works.
//
//  Usage:
//      SKRating(value: $stars)                       // editable
//      SKRating(value: .constant(4), isEditable: false)
//

import SwiftUI

public struct SKRating: View {
    @Binding private var value: Int
    private let count: Int
    private let isEditable: Bool
    private let size: CGFloat
    private let tint: Color

    @State private var dragValue: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        value: Binding<Int>,
        count: Int = 5,
        isEditable: Bool = true,
        size: CGFloat = SK.Icon.lg,
        tint: Color = SK.Palette.warning
    ) {
        self._value = value
        self.count = count
        self.isEditable = isEditable
        self.size = size
        self.tint = tint
    }

    private var shown: Int { dragValue ?? value }

    public var body: some View {
        HStack(spacing: SK.Space.xs) {
            ForEach(1...count, id: \.self) { index in
                star(index)
            }
        }
        .contentShape(.rect)
        .gesture(isEditable ? drag : nil)
        .accessibilityElement()
        .accessibilityValue(Text("\(value) of \(count)"))
        .accessibilityAdjustableAction { direction in
            guard isEditable else { return }
            switch direction {
            case .increment: if value < count { value += 1 }
            case .decrement: if value > 0 { value -= 1 }
            @unknown default: break
            }
        }
    }

    private func star(_ index: Int) -> some View {
        let filled = index <= shown
        return Image(systemName: filled ? "star.fill" : "star")
            .font(SK.Icon.symbol(size, weight: .medium))
            .foregroundStyle(filled ? tint : SK.Palette.separator)
            // Only the star being set pops; popping all of them at once reads
            // as a glitch rather than feedback.
            .scaleEffect(filled && index == shown ? 1.18 : 1)
            .frame(width: size * 1.6, height: SK.Icon.hitTarget)
            .skAnimation(.pop, value: shown)
            .onTapGesture {
                guard isEditable else { return }
                set(index)
            }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                let per = size * 1.6 + SK.Space.xs
                let index = Int(g.location.x / per) + 1
                let clamped = min(max(index, 1), count)
                if clamped != dragValue {
                    dragValue = clamped
                    SK.Haptic.play(.light)
                }
            }
            .onEnded { _ in
                if let dragValue { value = dragValue }
                dragValue = nil
            }
    }

    private func set(_ index: Int) {
        withAnimation(SKMotion.pop.resolved(reduceMotion: reduceMotion)) {
            // Tapping the only filled star clears the rating, which is the
            // conventional way to undo an accidental one-star.
            value = (value == index && index == 1) ? 0 : index
        }
        SK.Haptic.play(.light)
    }
}

#Preview("SKRating") {
    @Previewable @State var stars = 3

    VStack(spacing: SK.Space.xl) {
        SKRating(value: $stars)
        SKRating(value: $stars, size: SK.Icon.xl, tint: SK.Palette.accent)
        SKRating(value: .constant(4), isEditable: false, size: SK.Icon.sm)
        Text("Drag across the stars").font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
