//
//  GalleryApp.swift
//  Swift Kit UI Gallery
//
//  Run this to see every component live on a real device or simulator. This is
//  the exact preview — no HTML recreation, no recording. What you see here is
//  what ships in your app.
//

import SwiftUI
import SwiftKitUI

/// Deep-link options read from launch arguments.
///
/// Exists so screenshots and screen recordings can be captured deterministically
/// from the command line — `--component sk-toggle --variant liquid-glass`. That
/// is how the marketing site's recorded component loops get produced, so this is
/// build infrastructure, not a debug affordance.
struct LaunchOptions {
    var component: String?
    var variant: String?
    var scheme: ColorScheme?

    static func fromProcess() -> LaunchOptions {
        let args = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        let scheme: ColorScheme? = switch value("--scheme") {
        case "dark": .dark
        case "light": .light
        default: nil
        }
        return LaunchOptions(
            component: value("--component"),
            variant: value("--variant"),
            scheme: scheme
        )
    }
}

@main
struct GalleryApp: App {
    private let options = LaunchOptions.fromProcess()

    var body: some Scene {
        WindowGroup {
            ComponentListView(options: options)
                .tint(SK.Palette.accent)
        }
    }
}

struct ComponentListView: View {
    var options = LaunchOptions()
    @State private var path: [GalleryComponent] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: SK.Space.xl) {
                    header

                    ForEach(Catalog.grouped(), id: \.0) { category, items in
                        section(category, items)
                    }

                    footer
                }
                .padding(.horizontal, SK.Space.lg)
                .padding(.bottom, SK.Space.xxxl)
            }
            .background(SK.Palette.surfaceSunken)
            .navigationTitle("Swift Kit UI")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: GalleryComponent.self) { component in
                ComponentDetailView(component: component,
                                    initialVariant: options.variant,
                                    initialScheme: options.scheme)
            }
        }
        .onAppear {
            guard let id = options.component,
                  let target = Catalog.components.first(where: { $0.id == id })
            else { return }
            path = [target]
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            Text("Your app shouldn't look vibe-coded.")
                .font(SK.Type_.title)
                .foregroundStyle(SK.Palette.label)
            Text("\(Catalog.components.count) components. Every one is a single file that depends on nothing but SwiftKitUI.swift.")
                .font(SK.Type_.callout)
                .foregroundStyle(SK.Palette.labelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, SK.Space.md)
    }

    private func section(_ category: String, _ items: [GalleryComponent]) -> some View {
        VStack(alignment: .leading, spacing: SK.Space.md) {
            Label(category, systemImage: Catalog.symbol(for: category))
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelSecondary)

            VStack(spacing: SK.Space.sm) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        row(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func row(_ item: GalleryComponent) -> some View {
        HStack(spacing: SK.Space.md) {
            VStack(alignment: .leading, spacing: SK.Space.xxs) {
                HStack(spacing: SK.Space.sm) {
                    Text(item.title)
                        .font(SK.Type_.headline)
                        .foregroundStyle(SK.Palette.label)
                    TierBadge(isFree: item.isFree)
                }
                Text(item.summary)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelSecondary)
            }
            Spacer(minLength: SK.Space.sm)
            Text("\(item.variants.count)")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
            Image(systemName: "chevron.right")
                .font(SK.Icon.symbol(SK.Icon.sm))
                .foregroundStyle(SK.Palette.labelTertiary)
        }
        .padding(SK.Space.lg)
        .frame(minHeight: SK.Icon.hitTarget)
        .skSurface(.bordered, radius: SK.Radius.lg)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: SK.Space.xs) {
            Text("theswiftk.it.com/ui")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.accent)
            Text("Point your agent at the registry: /ui/registry.json")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ComponentListView()
}
