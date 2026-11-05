//
//  Support.swift
//  Swift Kit UI Gallery
//
//  Source loading, the code panel, the preview canvas and its controls.
//
//  The source shown in this app is NOT retyped — it is loaded from the same
//  generated registry JSON the website and the MCP server read. One source of
//  truth means the code you copy here is byte-identical to the code you ship.
//

import SwiftUI
import SwiftKitUI

// MARK: - Registry source loading

struct RegistrySource {
    let swift: String
    let usage: String
    let lineCount: Int
    let target: String
    let description: String
}

enum SourceLoader {
    private struct Item: Decodable {
        struct File: Decodable {
            let target: String
            let content: String?
            let lines: Int
        }
        let files: [File]
        let usage: String
        let description: String
    }

    /// Loads `Resources/registry/<id>.json`. Returns nil rather than throwing —
    /// a missing source panel should never take the whole gallery down.
    static func load(_ id: String) -> RegistrySource? {
        guard
            let url = Bundle.main.url(forResource: id, withExtension: "json", subdirectory: "registry")
                ?? Bundle.main.url(forResource: id, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let item = try? JSONDecoder().decode(Item.self, from: data),
            let file = item.files.first
        else { return nil }

        return RegistrySource(
            swift: file.content ?? "// Pro component — source ships with your licence.",
            usage: item.usage,
            lineCount: file.lines,
            target: file.target,
            description: item.description
        )
    }
}

// MARK: - Preview canvas

/// The stage a component performs on.
///
/// Appearance and Dynamic Type are applied *here only*, not to the whole app,
/// so you can flip the component to dark mode or crank the text size and still
/// read the controls you are flipping it with.
struct PreviewCanvas<Content: View>: View {
    var scheme: ColorScheme?
    var typeSize: DynamicTypeSize
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(SK.Space.xl)
            .frame(maxWidth: .infinity, minHeight: 240)
            .background {
                LinearGradient(
                    colors: [SK.Palette.accentSoft, SK.Palette.surfaceSunken],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: SK.Radius.xl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SK.Radius.xl, style: .continuous)
                    .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.hairline)
            }
            // `.environment(\.colorScheme,)` scopes to this subtree.
            // `.preferredColorScheme` must NOT be used here: it sets the whole
            // WINDOW's scheme regardless of nesting, which dragged the entire
            // screen light and made the canvas control a global switch.
            .environment(\.colorScheme, scheme ?? .light)
            .dynamicTypeSize(typeSize)
    }
}

// MARK: - Canvas controls

struct CanvasControls: View {
    @Binding var scheme: ColorScheme
    @Binding var typeSize: DynamicTypeSize

    var body: some View {
        HStack(spacing: SK.Space.md) {
            Picker("Appearance", selection: $scheme) {
                Label("Light", systemImage: "sun.max.fill").tag(ColorScheme.light)
                Label("Dark", systemImage: "moon.fill").tag(ColorScheme.dark)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 170)

            Spacer(minLength: SK.Space.sm)

            Button {
                typeSize = typeSize.previousStep
            } label: {
                Image(systemName: "textformat.size.smaller")
                    .font(SK.Icon.symbol(SK.Icon.md))
            }
            .disabled(typeSize == .xSmall)

            Text(typeSize.shortLabel)
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelSecondary)
                .frame(minWidth: 42)

            Button {
                typeSize = typeSize.nextStep
            } label: {
                Image(systemName: "textformat.size.larger")
                    .font(SK.Icon.symbol(SK.Icon.md))
            }
            .disabled(typeSize == .accessibility5)
        }
        .tint(SK.Palette.accent)
    }
}

extension DynamicTypeSize {
    var shortLabel: String {
        switch self {
        case .xSmall: "XS"
        case .small: "S"
        case .medium: "M"
        case .large: "L"
        case .xLarge: "XL"
        case .xxLarge: "2XL"
        case .xxxLarge: "3XL"
        case .accessibility1: "AX1"
        case .accessibility2: "AX2"
        case .accessibility3: "AX3"
        case .accessibility4: "AX4"
        case .accessibility5: "AX5"
        @unknown default: "?"
        }
    }

    var nextStep: DynamicTypeSize {
        let all = DynamicTypeSize.allCases
        guard let i = all.firstIndex(of: self), i + 1 < all.count else { return self }
        return all[i + 1]
    }

    var previousStep: DynamicTypeSize {
        let all = DynamicTypeSize.allCases
        guard let i = all.firstIndex(of: self), i > 0 else { return self }
        return all[i - 1]
    }
}

// MARK: - Code panel

struct CodeBlock: View {
    let title: String
    let code: String
    var subtitle: String?

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: SK.Space.sm) {
                Text(title)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelTertiary)
                }
                Spacer()
                Button {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = code
                    #endif
                    SK.Haptic.play(.success)
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.6))
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(SK.Type_.caption)
                        .labelStyle(.titleAndIcon)
                }
                .tint(copied ? SK.Palette.success : SK.Palette.accent)
                .skAnimation(.snap, value: copied)
            }
            .padding(.horizontal, SK.Space.lg)
            .padding(.vertical, SK.Space.md)

            Divider().overlay(SK.Palette.separator)

            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(SK.Palette.label)
                    .textSelection(.enabled)
                    .padding(SK.Space.lg)
            }
            .frame(maxHeight: 340)
        }
        .background(SK.Palette.surfaceSunken)
        .clipShape(RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous)
                .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.hairline)
        }
    }
}

// MARK: - Small pieces

struct TierBadge: View {
    let isFree: Bool

    var body: some View {
        Text(isFree ? "Free" : "Pro")
            .font(SK.Type_.caption)
            .foregroundStyle(isFree ? SK.Palette.success : SK.Palette.accent)
            .padding(.horizontal, SK.Space.sm)
            .padding(.vertical, SK.Space.xxs)
            .background(
                Capsule().fill(isFree ? SK.Palette.successSoft : SK.Palette.accentSoft)
            )
    }
}
