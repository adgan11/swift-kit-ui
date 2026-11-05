//
//  SKMarkdownView.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Markdown rendered as real blocks, not one long `Text`.
//
//  `AttributedString(markdown:)` is excellent at *inline* markdown — bold,
//  italic, links, inline code — and useless for block structure: it will
//  happily collapse a heading, three bullets and a fenced code block into a
//  single run-on paragraph. So this parses blocks itself and hands each block's
//  inline content to Foundation. Half the work, none of the bugs, and bold
//  still works inside a bullet.
//
//  It is built to be rendered mid-stream. A fence that has opened and not yet
//  closed is treated as an open code block rather than as literal backticks,
//  which is the difference between a code block that grows as the model writes
//  it and a paragraph that suddenly reflows into one when the closing fence
//  finally arrives. The same goes for a heading still being typed.
//
//  Usage:
//      SKMarkdownView(reply)
//      SKMarkdownView(reply, isStreaming: true)
//

import SwiftUI

public struct SKMarkdownView: View {
    private let markdown: String
    private let isStreaming: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var caretVisible = true

    public init(_ markdown: String, isStreaming: Bool = false) {
        self.markdown = markdown
        self.isStreaming = isStreaming
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.md) {
            let blocks = SKMarkdownBlock.parse(markdown)
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                render(block, isLast: index == blocks.count - 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: isStreaming) {
            guard isStreaming, !reduceMotion else {
                caretVisible = true
                return
            }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(530))
                caretVisible.toggle()
            }
        }
    }

    // MARK: Block rendering

    @ViewBuilder
    private func render(_ block: SKMarkdownBlock, isLast: Bool) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(SKMarkdownBlock.inline(text))
                .font(headingFont(level))
                .foregroundStyle(SK.Palette.label)
                .fixedSize(horizontal: false, vertical: true)
                // Headings need air above them but not below — the block gap
                // already provides that, and doubling it detaches the heading
                // from the paragraph it introduces.
                .padding(.top, level <= 2 ? SK.Space.sm : 0)

        case .paragraph(let text):
            paragraph(text, showsCaret: isLast)

        case .bullet(let items):
            VStack(alignment: .leading, spacing: SK.Space.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    listRow(marker: { bulletDot }, text: item)
                }
            }

        case .numbered(let items):
            VStack(alignment: .leading, spacing: SK.Space.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    listRow(
                        marker: {
                            Text("\(index + 1).")
                                .font(SK.Type_.callout)
                                .foregroundStyle(SK.Palette.labelTertiary)
                                .monospacedDigit()
                                .frame(minWidth: 18, alignment: .trailing)
                        },
                        text: item
                    )
                }
            }

        case .code(let language, let code):
            codeBlock(language: language, code: code)

        case .quote(let text):
            HStack(alignment: .top, spacing: SK.Space.md) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(SK.Palette.accent)
                    .frame(width: 3)
                Text(SKMarkdownBlock.inline(text))
                    .font(SK.Type_.body)
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .fixedSize(horizontal: false, vertical: true)

        case .rule:
            Rectangle()
                .fill(SK.Palette.separator)
                .frame(height: SK.Stroke.hairline)
                .padding(.vertical, SK.Space.xs)
        }
    }

    private func paragraph(_ text: String, showsCaret: Bool) -> some View {
        // The caret is concatenated into the final paragraph so it sits after
        // the last glyph on the last line, where a real cursor would be.
        let wantsCaret = showsCaret && isStreaming && !reduceMotion
        return (
            Text(SKMarkdownBlock.inline(text))
                .font(SK.Type_.body)
                .foregroundStyle(SK.Palette.label)
            + Text(wantsCaret ? " \u{258C}" : "")
                .font(SK.Type_.body)
                .foregroundStyle(caretVisible ? SK.Palette.accent : Color.clear)
        )
        .fixedSize(horizontal: false, vertical: true)
        .textSelection(.enabled)
    }

    private func listRow<Marker: View>(
        @ViewBuilder marker: () -> Marker,
        text: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SK.Space.md) {
            marker()
            Text(SKMarkdownBlock.inline(text))
                .font(SK.Type_.body)
                .foregroundStyle(SK.Palette.label)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var bulletDot: some View {
        Circle()
            .fill(SK.Palette.labelTertiary)
            .frame(width: 5, height: 5)
            // Nudged down to sit on the x-height rather than the baseline,
            // where a raw circle on `.firstTextBaseline` lands.
            .offset(y: -1)
            .frame(minWidth: 18, alignment: .trailing)
    }

    /// A deliberately minimal code surface.
    ///
    /// Not `SKCodeBlock`: every component in this kit compiles against the
    /// foundation and nothing else, so that copying one file can never fail on
    /// a missing sibling. Install `SKCodeBlock` too and you can swap this out
    /// in one line.
    private func codeBlock(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            if let language, !language.isEmpty {
                Text(language.uppercased())
                    .font(SK.Type_.caption)
                    .tracking(0.6)
                    .foregroundStyle(SK.Palette.labelTertiary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(SK.Type_.mono)
                    .foregroundStyle(SK.Palette.label)
                    .textSelection(.enabled)
            }
        }
        .padding(SK.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SK.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .system(.title2, design: .rounded, weight: .bold)
        case 2: .system(.title3, design: .rounded, weight: .bold)
        default: SK.Type_.headline
        }
    }
}

// MARK: - Block model and parser

/// Public so a host app can reuse the parse without the view — useful for
/// search indexing, or for rendering the same reply into a different surface.
public enum SKMarkdownBlock: Equatable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bullet([String])
    case numbered([String])
    case code(language: String?, code: String)
    case quote(String)
    case rule

    /// Splits markdown into block-level elements.
    ///
    /// Single pass, no lookbehind. An unterminated fence deliberately runs to
    /// the end of input rather than being discarded, which is what makes the
    /// output stable while a reply is still arriving.
    public static func parse(_ source: String) -> [SKMarkdownBlock] {
        var blocks: [SKMarkdownBlock] = []
        var paragraph: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(.paragraph(paragraph.joined(separator: " ")))
            paragraph.removeAll()
        }

        let lines = source.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code.
            if trimmed.hasPrefix("```") {
                flushParagraph()
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var body: [String] = []
                i += 1
                while i < lines.count,
                      !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    body.append(lines[i])
                    i += 1
                }
                // Step over the closing fence when there is one. When there is
                // not, we have consumed to EOF and the block still renders.
                if i < lines.count { i += 1 }
                blocks.append(.code(language: language.isEmpty ? nil : language,
                                    code: body.joined(separator: "\n")))
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                i += 1
                continue
            }

            // Horizontal rule.
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                blocks.append(.rule)
                i += 1
                continue
            }

            // ATX heading.
            if let hashes = leadingHashes(trimmed), hashes >= 1, hashes <= 6 {
                flushParagraph()
                let text = String(trimmed.dropFirst(hashes)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: hashes, text: text))
                i += 1
                continue
            }

            // Blockquote — consecutive lines fold into one quote.
            if trimmed.hasPrefix(">") {
                flushParagraph()
                var body: [String] = []
                while i < lines.count {
                    let candidate = lines[i].trimmingCharacters(in: .whitespaces)
                    guard candidate.hasPrefix(">") else { break }
                    body.append(String(candidate.dropFirst()).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.quote(body.joined(separator: " ")))
                continue
            }

            // Unordered list.
            if isBullet(trimmed) {
                flushParagraph()
                var items: [String] = []
                while i < lines.count {
                    let candidate = lines[i].trimmingCharacters(in: .whitespaces)
                    guard isBullet(candidate) else { break }
                    items.append(String(candidate.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.bullet(items))
                continue
            }

            // Ordered list.
            if let stripped = strippedOrderedMarker(trimmed) {
                flushParagraph()
                var items: [String] = [stripped]
                i += 1
                while i < lines.count,
                      let next = strippedOrderedMarker(lines[i].trimmingCharacters(in: .whitespaces)) {
                    items.append(next)
                    i += 1
                }
                blocks.append(.numbered(items))
                continue
            }

            paragraph.append(trimmed)
            i += 1
        }

        flushParagraph()
        return blocks
    }

    private static func leadingHashes(_ line: String) -> Int? {
        var count = 0
        for character in line {
            if character == "#" { count += 1 } else { break }
        }
        guard count > 0 else { return nil }
        // "#hashtag" is not a heading; ATX requires a space after the run.
        let rest = line.dropFirst(count)
        guard rest.first == " " else { return nil }
        return count
    }

    private static func isBullet(_ line: String) -> Bool {
        guard line.count >= 2 else { return false }
        let first = line.first
        guard first == "-" || first == "*" || first == "+" else { return false }
        return line.dropFirst().first == " "
    }

    private static func strippedOrderedMarker(_ line: String) -> String? {
        var digits = 0
        for character in line {
            if character.isNumber { digits += 1 } else { break }
        }
        guard digits > 0 else { return nil }
        let rest = line.dropFirst(digits)
        guard rest.first == ".", rest.dropFirst().first == " " else { return nil }
        return String(rest.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }

    /// Inline markdown via Foundation, with inline code restyled.
    ///
    /// `.returnPartiallyParsedIfPossible` matters while streaming: a half-typed
    /// `**bold` would otherwise throw and drop the whole paragraph for a frame.
    public static func inline(_ text: String) -> AttributedString {
        guard var attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) else {
            return AttributedString(text)
        }

        // Collected first: mutating an AttributedString while iterating its own
        // runs invalidates the iteration.
        let codeRanges = attributed.runs.compactMap { run -> Range<AttributedString.Index>? in
            (run.inlinePresentationIntent?.contains(.code) ?? false) ? run.range : nil
        }
        for range in codeRanges {
            attributed[range].font = SK.Type_.monoCaption
            attributed[range].foregroundColor = SK.Palette.accent
            attributed[range].backgroundColor = SK.Palette.fill
        }

        let linkRanges = attributed.runs.compactMap { run -> Range<AttributedString.Index>? in
            run.link != nil ? run.range : nil
        }
        for range in linkRanges {
            attributed[range].foregroundColor = SK.Palette.accent
            attributed[range].underlineStyle = .single
        }

        return attributed
    }
}

#Preview("SKMarkdownView") {
    ScrollView {
        SKMarkdownView(
            """
            ## Migration report

            The overnight run finished at **04:12**. Two rows were rejected for a
            null `tenant_id`; everything else moved cleanly.

            ### What moved

            - 1,284,003 records in 38 minutes
            - Peak throughput of *9,400 rows/sec*
            - Zero lock escalations

            > The rejected rows are in `migration_errors`, not lost.

            Retry them with:

            ```swift
            let failed = try await store.rejected(batch: 42)
            try await store.retry(failed, policy: .exponential)
            ```

            1. Re-run the batch
            2. Verify the row count
            3. Drop the staging table
            """
        )
        .padding(SK.Space.lg)
    }
    .background(SK.Palette.surface)
}
