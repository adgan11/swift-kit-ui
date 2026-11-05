//
//  SKColorSwatchPicker.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A swatch grid. Use this instead of the system ColorPicker when you have a
//  fixed brand palette — an eyedropper and an infinite colour wheel are the
//  wrong affordance for "pick one of our eight accent colours".
//
//  Usage:
//      SKColorSwatchPicker(selection: $accent, colors: brandColors)
//

import SwiftUI

public struct SKColorSwatchPicker: View {
    @Binding private var selection: Color
    private let colors: [Color]
    private let columns: Int
    private let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        selection: Binding<Color>,
        colors: [Color],
        columns: Int = 6,
        size: CGFloat = 44
    ) {
        self._selection = selection
        self.colors = colors
        self.columns = columns
        self.size = size
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: SK.Space.md), count: columns),
            spacing: SK.Space.md
        ) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                swatch(color)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func swatch(_ color: Color) -> some View {
        let isSelected = color == selection
        return Button {
            withAnimation(SKMotion.pop.resolved(reduceMotion: reduceMotion)) {
                selection = color
            }
            SK.Haptic.play(.selection)
        } label: {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.5), lineWidth: SK.Stroke.thin)
                }
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(SK.Icon.symbol(SK.Icon.sm, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.35), radius: 2)
                    }
                }
                // A ring outside the swatch rather than a border on it, so the
                // colour being chosen is never altered by its own selection UI.
                .overlay {
                    Circle()
                        .strokeBorder(SK.Palette.accent, lineWidth: isSelected ? 3 : 0)
                        .padding(-5)
                }
                .scaleEffect(isSelected ? 1.06 : 1)
                .contentShape(.circle)
        }
        .buttonStyle(.skPress(scale: 0.9, haptic: nil))
        .skAnimation(.snap, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("SKColorSwatchPicker") {
    @Previewable @State var accent = Color.purple
    let palette: [Color] = [.purple, .blue, .teal, .green, .yellow, .orange,
                            .red, .pink, .indigo, .mint, .brown, .gray]

    VStack(spacing: SK.Space.xl) {
        SKColorSwatchPicker(selection: $accent, colors: palette)
        RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous)
            .fill(accent)
            .frame(height: 80)
            .skAnimation(.settle, value: accent)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
