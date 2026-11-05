//
//  Catalog.swift
//  Swift Kit UI Gallery
//
//  The component list is DECODED FROM THE REGISTRY, not typed out here.
//
//  A hand-written catalogue drifts: you add a component, forget the gallery,
//  and the app quietly ships a shorter list than the product. Reading
//  `Resources/registry/registry.json` — the same file the website and the MCP
//  server serve — makes that impossible.
//

import SwiftUI

struct GalleryComponent: Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let summary: String
    let isFree: Bool
    let variants: [Variant]
    let searchVolume: Int?

    struct Variant: Identifiable, Hashable {
        let id: String
        let title: String
    }
}

enum Catalog {
    // MARK: Registry decoding

    private struct Index: Decodable {
        struct Item: Decodable {
            let name: String
            let type: String
            let title: String
            let description: String
            let tier: String
            let categories: [String]
            let variants: [String]
        }
        let count: Int
        let items: [Item]
    }

    /// Per-item JSON carries the variant titles and search volume; the index
    /// only has variant ids.
    private struct Detail: Decodable {
        struct Variant: Decodable { let id: String; let title: String }
        struct Meta: Decodable { let searchVolume: Int? }
        let variants: [Variant]?
        let meta: Meta?
    }

    static let components: [GalleryComponent] = load()

    private static func load() -> [GalleryComponent] {
        guard
            let url = bundled("registry"),
            let data = try? Data(contentsOf: url),
            let index = try? JSONDecoder().decode(Index.self, from: data)
        else {
            assertionFailure("registry.json missing — run scripts/build_registry.py")
            return []
        }

        return index.items
            // The foundation is a library, not something to preview.
            .filter { $0.type == "registry:component" }
            .map { item in
                let detail = detail(for: item.name)
                let variants = detail?.variants?.map {
                    GalleryComponent.Variant(id: $0.id, title: $0.title)
                } ?? item.variants.map { .init(id: $0, title: $0.capitalized) }

                return GalleryComponent(
                    id: item.name,
                    title: item.title,
                    category: item.categories.first?.capitalized ?? "Other",
                    summary: firstSentence(of: item.description),
                    isFree: item.tier == "free",
                    variants: variants,
                    searchVolume: detail?.meta?.searchVolume
                )
            }
    }

    private static func detail(for name: String) -> Detail? {
        guard
            let url = bundled(name),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(Detail.self, from: data)
    }

    private static func bundled(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "registry")
            ?? Bundle.main.url(forResource: name, withExtension: "json")
    }

    /// Row subtitles get one sentence; the full description lives on the detail
    /// screen. Markdown emphasis is stripped since rows render plain text.
    private static func firstSentence(of text: String) -> String {
        let cleaned = text.replacingOccurrences(of: "*", with: "")
        guard let end = cleaned.firstIndex(where: { $0 == "." }) else { return cleaned }
        return String(cleaned[..<end])
    }

    // MARK: Grouping

    static func grouped() -> [(String, [GalleryComponent])] {
        let byCategory = Dictionary(grouping: components, by: \.category)
        // Biggest sections first, so the list opens on substance.
        return byCategory
            .map { ($0.key, $0.value.sorted { ($0.searchVolume ?? 0) > ($1.searchVolume ?? 0) }) }
            .sorted { lhs, rhs in
                lhs.1.count == rhs.1.count ? lhs.0 < rhs.0 : lhs.1.count > rhs.1.count
            }
    }

    static func symbol(for category: String) -> String {
        switch category.lowercased() {
        case "ai": "sparkles"
        case "controls": "switch.2"
        case "actions": "hand.tap.fill"
        case "navigation": "square.split.bottomrightquarter.fill"
        case "inputs": "keyboard.fill"
        case "feedback": "bell.badge.fill"
        case "overlays": "square.stack.fill"
        case "surfaces": "rectangle.on.rectangle.angled.fill"
        case "lists": "list.bullet"
        case "layout": "square.grid.2x2.fill"
        case "data": "chart.line.uptrend.xyaxis"
        case "display": "person.crop.circle.fill"
        case "decoration": "sparkles"
        case "delight": "party.popper.fill"
        case "interaction": "hand.draw.fill"
        default: "square.dashed"
        }
    }
}
