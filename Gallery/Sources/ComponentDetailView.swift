//
//  ComponentDetailView.swift
//  Swift Kit UI Gallery
//
//  One component, on a stage you can change underneath it.
//
//  The appearance and Dynamic Type controls apply to the canvas only. That is
//  the point: flip a component to dark mode at AX5 text size and watch whether
//  it still holds together. Most component libraries cannot survive that test,
//  which is exactly why the control is here rather than buried in Settings.
//

import SwiftUI
import SwiftKitUI

struct ComponentDetailView: View {
    let component: GalleryComponent

    @State private var variant: String
    @State private var scheme: ColorScheme
    @State private var typeSize: DynamicTypeSize = .large
    @State private var source: RegistrySource?

    init(component: GalleryComponent,
         initialVariant: String? = nil,
         initialScheme: ColorScheme? = nil) {
        self.component = component
        _scheme = State(initialValue: initialScheme ?? .light)
        let valid = component.variants.map(\.id)
        let start = initialVariant.flatMap { valid.contains($0) ? $0 : nil }
        _variant = State(initialValue: start ?? valid.first ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SK.Space.lg) {
                PreviewCanvas(scheme: scheme, typeSize: typeSize) {
                    ComponentShowcase(componentID: component.id, variantID: variant)
                }
                // Re-render cleanly when the variant changes rather than trying
                // to interpolate between two structurally different demos.
                .id(variant)
                .skAnimation(.settle, value: variant)

                CanvasControls(scheme: $scheme, typeSize: $typeSize)

                if component.variants.count > 1 {
                    variantPicker
                }

                if let source {
                    Text(source.description)
                        .font(SK.Type_.callout)
                        .foregroundStyle(SK.Palette.labelSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let source {
                    CodeBlock(
                        title: "Usage",
                        code: source.usage
                    )
                    CodeBlock(
                        title: source.target,
                        code: source.swift,
                        subtitle: "\(source.lineCount) lines · depends only on SwiftKitUI.swift"
                    )
                } else {
                    missingSourceNote
                }
            }
            .padding(.horizontal, SK.Space.lg)
            .padding(.bottom, SK.Space.xxxl)
        }
        .background(SK.Palette.surfaceSunken)
        .navigationTitle(component.title)
        .navigationBarTitleDisplayMode(.large)
        .task { source = SourceLoader.load(component.id) }
    }

    private var variantPicker: some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            Text("Variant")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SK.Space.sm) {
                    ForEach(component.variants) { option in
                        let isOn = option.id == variant
                        Button(option.title) {
                            variant = option.id
                            SK.Haptic.play(.selection)
                        }
                        .font(SK.Type_.caption)
                        .foregroundStyle(isOn ? .white : SK.Palette.label)
                        .padding(.horizontal, SK.Space.lg)
                        .padding(.vertical, SK.Space.sm)
                        .background(
                            Capsule().fill(isOn ? SK.Palette.accent : SK.Palette.fill)
                        )
                        .skAnimation(.snap, value: variant)
                    }
                }
                .padding(.vertical, SK.Space.xxs)
            }
        }
    }

    private var missingSourceNote: some View {
        Text("Source unavailable — run scripts/build_registry.py to regenerate the bundled registry.")
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.warning)
            .padding(SK.Space.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skSurface(.bordered, radius: SK.Radius.md)
    }
}

#Preview {
    NavigationStack {
        ComponentDetailView(component: Catalog.components[0])
    }
}
