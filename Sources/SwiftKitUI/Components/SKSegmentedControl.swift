//
//  SKSegmentedControl.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  The indicator slides between segments via matchedGeometryEffect rather than
//  cutting. Same technique as the tab bar, deliberately — two controls that
//  both express "one of these is selected" should move the same way.
//
//  Usage:
//      SKSegmentedControl(selection: $billing, options: Billing.allCases) { $0.title }
//

import SwiftUI

public struct SKSegmentedControl<Option: Hashable>: View {
    @Binding private var selection: Option
    private let options: [Option]
    private let title: (Option) -> String

    @Namespace private var indicator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        selection: Binding<Option>,
        options: [Option],
        title: @escaping (Option) -> String
    ) {
        self._selection = selection
        self.options = options
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(SK.Space.xs)
        .background(SK.Palette.fill, in: Capsule(style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            guard !isSelected else { return }
            withAnimation(SKMotion.snap.resolved(reduceMotion: reduceMotion)) {
                selection = option
            }
            SK.Haptic.play(.selection)
        } label: {
            Text(title(option))
                .font(SK.Type_.callout)
                .foregroundStyle(isSelected ? SK.Palette.label : SK.Palette.labelSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SK.Space.sm)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(SK.Palette.surfaceElevated)
                            .shadow(color: .black.opacity(0.10), radius: 4, y: 1)
                            .matchedGeometryEffect(id: "sk.segment.indicator", in: indicator)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("SKSegmentedControl") {
    @Previewable @State var billing = "Annual"
    @Previewable @State var view = "Grid"

    VStack(spacing: SK.Space.xl) {
        SKSegmentedControl(selection: $billing, options: ["Monthly", "Annual"]) { $0 }
        SKSegmentedControl(selection: $view, options: ["List", "Grid", "Map"]) { $0 }
        Text(billing + " / " + view)
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelSecondary)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
