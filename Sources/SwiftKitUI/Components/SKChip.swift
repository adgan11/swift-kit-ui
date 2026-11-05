//
//  SKChip.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A selectable tag. Filter bars, topic pickers, multi-select.
//
//  Selection animates on `.snap` and fires a selection haptic, so a row of
//  chips feels like the same control as the toggle and the tab bar rather than
//  a different one that happens to be nearby.
//
//  Usage:
//      SKChip("Swift", isSelected: selected.contains("Swift")) { toggle("Swift") }
//      SKChip("Removable", isSelected: true, onRemove: { })
//

import SwiftUI

public struct SKChip: View {
    private let text: String
    private let systemImage: String?
    private let isSelected: Bool
    private let onTap: (() -> Void)?
    private let onRemove: (() -> Void)?

    public init(
        _ text: String,
        systemImage: String? = nil,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.text = text
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.onTap = onTap
        self.onRemove = onRemove
    }

    public var body: some View {
        Button {
            onTap?()
            SK.Haptic.play(.selection)
        } label: {
            HStack(spacing: SK.Space.xs) {
                if let systemImage {
                    Image(systemName: systemImage).font(SK.Icon.symbol(SK.Icon.xs))
                }
                Text(text).font(SK.Type_.caption)
                if onRemove != nil {
                    Image(systemName: "xmark")
                        .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                        .onTapGesture { onRemove?() }
                        .accessibilityLabel("Remove \(text)")
                }
            }
            .foregroundStyle(isSelected ? Color.white : SK.Palette.label)
            .padding(.horizontal, SK.Space.md)
            .padding(.vertical, SK.Space.sm)
            .background {
                Capsule().fill(isSelected ? SK.Palette.accent : SK.Palette.fill)
            }
            .overlay {
                if !isSelected {
                    Capsule().strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.hairline)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.skPress(scale: 0.95, haptic: nil))
        .skAnimation(.snap, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("SKChip") {
    @Previewable @State var selected: Set<String> = ["SwiftUI"]
    let tags = ["SwiftUI", "UIKit", "Combine", "SwiftData", "Metal"]

    VStack(spacing: SK.Space.xl) {
        FlowRow(tags: tags, selected: selected) { tag in
            if selected.contains(tag) { selected.remove(tag) } else { selected.insert(tag) }
        }
        HStack(spacing: SK.Space.sm) {
            SKChip("Removable", isSelected: true, onRemove: {})
            SKChip("With icon", systemImage: "star.fill")
        }
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}

private struct FlowRow: View {
    let tags: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        HStack(spacing: SK.Space.sm) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                SKChip(tag, isSelected: selected.contains(tag)) { onTap(tag) }
            }
        }
    }
}
