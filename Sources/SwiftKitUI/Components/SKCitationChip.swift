//
//  SKCitationChip.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  An inline source marker that opens the source.
//
//  Citations are the difference between an assistant people check and one they
//  either trust blindly or not at all. The constraint is that the marker has to
//  sit *inside* a sentence without wrecking its rhythm — so it is sized to the
//  caption ramp, given a fixed minimum width so `1` and `12` do not jitter the
//  line, and raised slightly to sit like a superscript rather than a button
//  dropped into the paragraph.
//
//  Tapping opens a popover rather than pushing a screen. A citation is a
//  glance, and a glance should not cost a navigation stack — on iPhone
//  `presentationCompactAdaptation` keeps it a popover instead of letting it
//  become a full sheet.
//
//  Usage:
//      SKCitationChip(index: 1, source: source)
//      SKCitationChip(source: source, style: .domain)
//

import SwiftUI

public struct SKCitationSource: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let domain: String
    public let snippet: String?
    public let url: URL?

    public init(
        id: String = UUID().uuidString,
        title: String,
        domain: String,
        snippet: String? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.domain = domain
        self.snippet = snippet
        self.url = url
    }
}

public struct SKCitationChip: View {
    public enum Style: Sendable { case numbered, domain }

    private let index: Int?
    private let source: SKCitationSource
    private let style: Style

    @State private var showing = false

    public init(index: Int? = nil, source: SKCitationSource, style: Style = .numbered) {
        self.index = index
        self.source = source
        self.style = style
    }

    public var body: some View {
        Button {
            showing = true
            SK.Haptic.play(.light)
        } label: {
            label
        }
        .buttonStyle(.skPress(scale: 0.9, haptic: nil))
        .popover(isPresented: $showing) {
            card
                .frame(idealWidth: 280)
                .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("Source: \(source.title), \(source.domain)")
    }

    @ViewBuilder
    private var label: some View {
        switch style {
        case .numbered:
            Text(index.map(String.init) ?? "\u{2022}")
                .font(SK.Type_.caption)
                .monospacedDigit()
                .foregroundStyle(SK.Palette.accent)
                // Fixed width so a two-digit citation does not shove the
                // sentence around it.
                .frame(minWidth: 17, minHeight: 17)
                .background(SK.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .baselineOffset(3)

        case .domain:
            HStack(spacing: SK.Space.xs) {
                Image(systemName: "link")
                    .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                Text(source.domain)
                    .font(SK.Type_.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(SK.Palette.accent)
            .padding(.horizontal, SK.Space.sm)
            .padding(.vertical, SK.Space.xxs + 1)
            .background(SK.Palette.accentSoft, in: Capsule())
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            HStack(spacing: SK.Space.xs) {
                Image(systemName: "globe")
                    .font(SK.Icon.symbol(SK.Icon.xs))
                Text(source.domain)
                    .font(SK.Type_.caption)
            }
            .foregroundStyle(SK.Palette.labelTertiary)

            Text(source.title)
                .font(SK.Type_.headline)
                .foregroundStyle(SK.Palette.label)
                .fixedSize(horizontal: false, vertical: true)

            if let snippet = source.snippet {
                Text(snippet)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let url = source.url {
                Link(destination: url) {
                    HStack(spacing: SK.Space.xs) {
                        Text("Open")
                        Image(systemName: "arrow.up.right")
                            .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                    }
                    .font(SK.Type_.callout)
                    .foregroundStyle(SK.Palette.accent)
                }
            }
        }
        .padding(SK.Space.lg)
        .frame(maxWidth: 300, alignment: .leading)
    }
}

#Preview("SKCitationChip") {
    let sources = [
        SKCitationSource(
            title: "SaaS Benchmarks 2026: Retention and Expansion",
            domain: "openviewpartners.com",
            snippet: "Median annual-plan mix rose to 58% among companies above $1M ARR, with churn concentrated in month-to-month cohorts.",
            url: URL(string: "https://example.com")
        ),
        SKCitationSource(
            title: "Quarterly revenue teardown",
            domain: "chartmogul.com",
            snippet: "Mix shift toward annual billing typically depresses reported MRR growth for one quarter."
        ),
    ]

    VStack(alignment: .leading, spacing: SK.Space.xl) {
        Text("Annual plans now account for 61% of new subscriptions, up from 44% in Q2.")
            .font(SK.Type_.body)
            .foregroundStyle(SK.Palette.label)
            .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: SK.Space.xs) {
            Text("Cited:")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
            SKCitationChip(index: 1, source: sources[0])
            SKCitationChip(index: 2, source: sources[1])
        }

        SKCitationChip(source: sources[0], style: .domain)
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(SK.Palette.surface)
}
