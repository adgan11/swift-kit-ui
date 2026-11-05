//
//  SKRow.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A list row: optional leading symbol, title, optional subtitle, and whatever
//  you want on the trailing edge.
//
//  The separator is inset to line up under the title rather than the icon,
//  which is what iOS does and what makes a stack of rows read as a list instead
//  of a pile of boxes.
//
//  Usage:
//      SKRow(title: "Wi-Fi", subtitle: "Home", systemImage: "wifi") { Text("On") }
//      SKRow(title: "Account", systemImage: "person.fill", onTap: { })
//      SKRow(title: "Last", showsSeparator: false)
//

import SwiftUI

public struct SKRow<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String?
    private let tint: Color
    private let showsSeparator: Bool
    private let onTap: (() -> Void)?
    private let trailing: Trailing

    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        tint: Color = SK.Palette.accent,
        showsSeparator: Bool = true,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.showsSeparator = showsSeparator
        self.onTap = onTap
        self.trailing = trailing()
    }

    public var body: some View {
        if let onTap {
            Button(action: onTap) { row }
                .buttonStyle(.skPress(scale: 0.99, haptic: .light))
        } else {
            row
        }
    }

    private var row: some View {
        VStack(spacing: 0) {
            HStack(spacing: SK.Space.md) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(SK.Icon.symbol(SK.Icon.md))
                        .foregroundStyle(tint)
                        .frame(width: SK.Icon.lg)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(SK.Type_.body)
                        .foregroundStyle(SK.Palette.label)
                    if let subtitle {
                        Text(subtitle)
                            .font(SK.Type_.caption)
                            .foregroundStyle(SK.Palette.labelSecondary)
                    }
                }

                Spacer(minLength: SK.Space.sm)
                trailing
            }
            .padding(.horizontal, SK.Space.lg)
            .padding(.vertical, SK.Space.md)
            .frame(minHeight: SK.Icon.hitTarget)

            if showsSeparator {
                Rectangle()
                    .fill(SK.Palette.separator)
                    .frame(height: SK.Stroke.hairline)
                    // Inset to the title, not the icon — the detail that makes
                    // a stack of rows read as one list.
                    .padding(.leading, systemImage == nil
                             ? SK.Space.lg
                             : SK.Space.lg + SK.Icon.lg + SK.Space.md)
            }
        }
        .contentShape(.rect)
    }
}

extension SKRow where Trailing == EmptyView {
    /// Row with no trailing content.
    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        tint: Color = SK.Palette.accent,
        showsSeparator: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.init(
            title: title, subtitle: subtitle, systemImage: systemImage,
            tint: tint, showsSeparator: showsSeparator, onTap: onTap
        ) { EmptyView() }
    }
}

/// The usual trailing affordance for a row that pushes a screen.
public struct SKChevron: View {
    public init() {}
    public var body: some View {
        Image(systemName: "chevron.right")
            .font(SK.Icon.symbol(SK.Icon.sm))
            .foregroundStyle(SK.Palette.labelTertiary)
    }
}

#Preview("SKRow") {
    VStack(spacing: 0) {
        SKRow(title: "Wi-Fi", subtitle: "HomeNetwork", systemImage: "wifi") {
            Text("On").font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
        }
        SKRow(title: "Account", systemImage: "person.fill", onTap: {}) { SKChevron() }
        SKRow(title: "Storage", systemImage: "internaldrive.fill") {
            Text("42 GB").font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
        }
        SKRow(title: "Sign Out", systemImage: "arrow.right.square",
              tint: SK.Palette.danger, showsSeparator: false, onTap: {})
    }
    .skSurface(.bordered, radius: SK.Radius.lg)
    .padding(SK.Space.lg)
    .frame(maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
