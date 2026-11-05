//
//  SKModelPicker.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Choosing a model, without making the user learn your model line-up.
//
//  The mistake here is listing identifiers. `gpt-4o-mini-2024-07-18` tells a
//  normal person nothing, so every row carries a plain-language subtitle and a
//  single badge saying what the trade is — fast, balanced, powerful. The
//  identifier stays available in monospace for the people who want it, at a
//  size that says "you may ignore this".
//
//  Locked models are shown, not hidden. A model the user cannot reach is the
//  most persuasive upgrade prompt an AI app has, and hiding it means they never
//  learn the better thing exists. Tapping one calls `onLocked` rather than
//  silently doing nothing.
//
//  Usage:
//      SKModelPicker(models: models, selection: $model)
//      SKModelPicker(models: models, selection: $model, style: .list)
//

import SwiftUI

public struct SKModel: Identifiable, Sendable, Hashable {
    public enum Badge: Sendable, Hashable {
        case fast, balanced, powerful, new

        var label: String {
            switch self {
            case .fast: "Fast"
            case .balanced: "Balanced"
            case .powerful: "Powerful"
            case .new: "New"
            }
        }

        var tint: Color {
            switch self {
            case .fast: SK.Palette.success
            case .balanced: SK.Palette.accent
            case .powerful: SK.Palette.warning
            case .new: SK.Palette.accent
            }
        }

        var softTint: Color {
            switch self {
            case .fast: SK.Palette.successSoft
            case .balanced: SK.Palette.accentSoft
            case .powerful: SK.Palette.warningSoft
            case .new: SK.Palette.accentSoft
            }
        }
    }

    public let id: String
    public let name: String
    public let subtitle: String
    public let badge: Badge?
    public let isLocked: Bool

    public init(
        id: String,
        name: String,
        subtitle: String,
        badge: Badge? = nil,
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.badge = badge
        self.isLocked = isLocked
    }
}

public struct SKModelPicker: View {
    public enum Style: Sendable {
        /// A compact button that opens the list in a sheet.
        case button
        /// The rows on their own, for embedding in an existing settings screen.
        case list
    }

    private let models: [SKModel]
    @Binding private var selection: SKModel.ID
    private let style: Style
    private let onLocked: ((SKModel) -> Void)?

    @State private var presenting = false

    public init(
        models: [SKModel],
        selection: Binding<SKModel.ID>,
        style: Style = .button,
        onLocked: ((SKModel) -> Void)? = nil
    ) {
        self.models = models
        self._selection = selection
        self.style = style
        self.onLocked = onLocked
    }

    private var selected: SKModel? {
        models.first { $0.id == selection }
    }

    public var body: some View {
        switch style {
        case .list: rows
        case .button: trigger
        }
    }

    // MARK: Trigger

    private var trigger: some View {
        Button {
            presenting = true
            SK.Haptic.play(.light)
        } label: {
            HStack(spacing: SK.Space.sm) {
                Image(systemName: "sparkles")
                    .font(SK.Icon.symbol(SK.Icon.xs, weight: .semibold))
                    .foregroundStyle(SK.Palette.accent)
                Text(selected?.name ?? "Select model")
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.label)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                    .foregroundStyle(SK.Palette.labelTertiary)
            }
            .padding(.horizontal, SK.Space.md)
            .padding(.vertical, SK.Space.sm)
            .background(SK.Palette.fill, in: Capsule())
            .overlay { Capsule().strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin) }
        }
        .buttonStyle(.skPress(scale: 0.96, haptic: nil))
        .accessibilityLabel("Model: \(selected?.name ?? "none selected")")
        .sheet(isPresented: $presenting) {
            NavigationStack {
                ScrollView { rows.padding(SK.Space.lg) }
                    .background(SK.Palette.surface)
                    .navigationTitle("Model")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            // Sized to content rather than a full sheet: a five-row list
            // presented full-height reads as a screen change, not a choice.
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: Rows

    private var rows: some View {
        VStack(spacing: SK.Space.sm) {
            ForEach(models) { model in
                row(model)
            }
        }
    }

    private func row(_ model: SKModel) -> some View {
        let isSelected = model.id == selection

        return Button {
            guard !model.isLocked else {
                onLocked?(model)
                SK.Haptic.play(.warning)
                return
            }
            selection = model.id
            SK.Haptic.play(.selection)
            presenting = false
        } label: {
            HStack(alignment: .top, spacing: SK.Space.md) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: SK.Space.sm) {
                        Text(model.name)
                            .font(SK.Type_.callout)
                            .foregroundStyle(model.isLocked ? SK.Palette.labelSecondary : SK.Palette.label)

                        if let badge = model.badge {
                            Text(badge.label)
                                .font(SK.Type_.caption)
                                .foregroundStyle(badge.tint)
                                .padding(.horizontal, SK.Space.sm)
                                .padding(.vertical, 1)
                                .background(badge.softTint, in: Capsule())
                        }

                        if model.isLocked {
                            Image(systemName: "lock.fill")
                                .font(SK.Icon.symbol(SK.Icon.xs))
                                .foregroundStyle(SK.Palette.labelTertiary)
                        }
                    }

                    Text(model.subtitle)
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelTertiary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(model.id)
                        .font(SK.Type_.monoCaption)
                        .foregroundStyle(SK.Palette.labelTertiary)
                        .opacity(0.65)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(SK.Icon.symbol(SK.Icon.lg))
                    .foregroundStyle(isSelected ? SK.Palette.accent : SK.Palette.separator)
                    .opacity(model.isLocked ? 0.4 : 1)
            }
            .padding(SK.Space.md)
            .background(
                isSelected ? SK.Palette.accentSoft : SK.Palette.surfaceElevated,
                in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? SK.Palette.accent : SK.Palette.separator,
                        lineWidth: isSelected ? SK.Stroke.thick : SK.Stroke.thin
                    )
            }
            .opacity(model.isLocked ? 0.75 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.skPress(scale: 0.99, haptic: nil))
        .skAnimation(.snap, value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.name). \(model.subtitle)")
        .accessibilityValue(model.isLocked ? "Locked" : (isSelected ? "Selected" : ""))
    }
}

#Preview("SKModelPicker") {
    @Previewable @State var selection = "claude-sonnet-5"

    let models = [
        SKModel(id: "claude-haiku-4-5", name: "Haiku 4.5",
                subtitle: "Quick answers and short edits. Cheapest per message.",
                badge: .fast),
        SKModel(id: "claude-sonnet-5", name: "Sonnet 5",
                subtitle: "The default. Handles most work without thinking about cost.",
                badge: .balanced),
        SKModel(id: "claude-opus-5", name: "Opus 5",
                subtitle: "Long documents, hard reasoning, code that has to be right.",
                badge: .powerful, isLocked: true),
    ]

    VStack(alignment: .leading, spacing: SK.Space.xl) {
        SKModelPicker(models: models, selection: $selection, onLocked: { _ in })
        SKModelPicker(models: models, selection: $selection, style: .list, onLocked: { _ in })
    }
    .padding(SK.Space.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SK.Palette.surface)
}
