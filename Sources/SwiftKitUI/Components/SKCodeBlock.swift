//
//  SKCodeBlock.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A code block that is legible, copyable, and honest about what it highlights.
//
//  The highlighting here is deliberately shallow — comments, strings, numbers,
//  keywords, and nothing else. A real tokeniser is a large dependency and a
//  maintenance burden, and in a chat transcript it buys almost nothing: at this
//  size the reader needs structure, not semantics. Four token classes give you
//  that. Twelve give you a fruit salad.
//
//  Highlighting runs in priority order and claims character ranges as it goes,
//  so `let x = "// not a comment"` stays a string all the way through. That
//  single rule is what separates a tinter that looks right from one that
//  betrays itself on the first interesting line.
//
//  Long lines scroll horizontally rather than wrapping. Wrapped code is
//  unreadable, and worse, it is uncopyable in a form that still runs.
//
//  Usage:
//      SKCodeBlock(snippet, language: "swift")
//      SKCodeBlock(json, language: "json", showsLineNumbers: true)
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct SKCodeBlock: View {
    private let code: String
    private let language: String?
    private let showsLineNumbers: Bool
    private let showsCopyButton: Bool

    @State private var copied = false

    public init(
        _ code: String,
        language: String? = nil,
        showsLineNumbers: Bool = false,
        showsCopyButton: Bool = true
    ) {
        self.code = code
        self.language = language
        self.showsLineNumbers = showsLineNumbers
        self.showsCopyButton = showsCopyButton
    }

    private var lines: [String] {
        // A trailing newline is a terminator, not an empty final line — without
        // this every fenced block renders one blank row too many.
        var body = code
        if body.hasSuffix("\n") { body.removeLast() }
        return body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if language != nil || showsCopyButton { header }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: SK.Space.md) {
                    if showsLineNumbers { gutter }

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            Text(SKSyntax.highlight(line, language: language))
                                .font(SK.Type_.mono)
                                // An empty line still has to occupy a row or
                                // the gutter numbers drift out of alignment.
                                .frame(minHeight: 18, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, SK.Space.lg)
                .padding(.vertical, SK.Space.md)
            }
        }
        .background(SK.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(language ?? "Code") block")
        .accessibilityValue(code)
    }

    private var header: some View {
        HStack(spacing: SK.Space.sm) {
            if let language {
                Text(language.uppercased())
                    .font(SK.Type_.caption)
                    .tracking(0.6)
                    .foregroundStyle(SK.Palette.labelTertiary)
            }
            Spacer(minLength: 0)
            if showsCopyButton { copyButton }
        }
        .padding(.horizontal, SK.Space.lg)
        .padding(.top, SK.Space.md)
        .padding(.bottom, SK.Space.sm)
    }

    private var copyButton: some View {
        Button {
            SKSyntax.copy(code)
            SK.Haptic.play(.success)
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                copied = false
            }
        } label: {
            HStack(spacing: SK.Space.xs) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                    // Width is reserved for the longer of the two words so the
                    // button does not resize when it confirms.
                Text(copied ? "Copied" : "Copy")
                    .font(SK.Type_.caption)
            }
            .foregroundStyle(copied ? SK.Palette.success : SK.Palette.labelSecondary)
            .frame(minWidth: 58, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.skPress(scale: 0.94, haptic: nil))
        .skAnimation(.snap, value: copied)
        .accessibilityLabel(copied ? "Copied" : "Copy code")
    }

    private var gutter: some View {
        VStack(alignment: .trailing, spacing: 2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                Text("\(index + 1)")
                    .font(SK.Type_.monoCaption)
                    .foregroundStyle(SK.Palette.labelTertiary)
                    .frame(minHeight: 18, alignment: .trailing)
            }
        }
        .frame(minWidth: 18, alignment: .trailing)
    }
}

// MARK: - Shallow syntax tinting

/// Namespaced so a host app can reuse the tinter for its own code surfaces
/// without instantiating a view.
public enum SKSyntax {
    private enum Token {
        case comment, string, number, keyword

        var color: Color {
            switch self {
            case .comment: SK.Palette.labelTertiary
            case .string: SK.Palette.success
            case .number: SK.Palette.warning
            case .keyword: SK.Palette.accent
            }
        }
    }

    private static let keywords: [String: Set<String>] = [
        "swift": ["let", "var", "func", "struct", "class", "enum", "protocol", "extension",
                  "if", "else", "guard", "return", "for", "in", "while", "switch", "case",
                  "import", "public", "private", "internal", "static", "some", "await",
                  "async", "try", "throws", "init", "self", "nil", "true", "false", "where"],
        "json": ["true", "false", "null"],
        "bash": ["if", "then", "fi", "for", "do", "done", "echo", "export", "cd", "set", "source"],
        "python": ["def", "class", "import", "from", "return", "if", "elif", "else", "for",
                   "in", "while", "with", "as", "try", "except", "None", "True", "False",
                   "lambda", "yield", "async", "await"],
        "javascript": ["const", "let", "var", "function", "return", "if", "else", "for",
                       "while", "class", "import", "export", "from", "async", "await",
                       "new", "null", "undefined", "true", "false"],
    ]

    private static func keywordSet(for language: String?) -> Set<String> {
        guard let key = language?.lowercased() else { return [] }
        if let exact = keywords[key] { return exact }
        switch key {
        case "sh", "zsh", "shell", "console": return keywords["bash"] ?? []
        case "js", "ts", "typescript", "tsx", "jsx": return keywords["javascript"] ?? []
        case "py": return keywords["python"] ?? []
        default: return []
        }
    }

    /// Tints one line. Line-at-a-time keeps the cost proportional to what is on
    /// screen and means a streaming block can be re-tinted as it grows without
    /// re-scanning everything above it.
    public static func highlight(_ line: String, language: String?) -> AttributedString {
        var out = AttributedString(line)
        out.foregroundColor = SK.Palette.label

        let ns = line as NSString
        var claimed = IndexSet()

        // Priority order is the whole trick: whatever matches first owns those
        // characters, so keywords inside a string are never re-tinted.
        let passes: [(Token, String)] = [
            (.comment, #"(//|#).*$"#),
            (.string, #""([^"\\]|\\.)*"|'([^'\\]|\\.)*'"#),
            (.number, #"\b\d+(\.\d+)?\b"#),
        ]

        for (token, pattern) in passes {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { continue }
            for match in regex.matches(in: line, range: NSRange(location: 0, length: ns.length)) {
                apply(token, match.range, to: &out, line: line, claimed: &claimed)
            }
        }

        let words = keywordSet(for: language)
        if !words.isEmpty,
           let regex = try? NSRegularExpression(pattern: #"\b[A-Za-z_][A-Za-z0-9_]*\b"#) {
            for match in regex.matches(in: line, range: NSRange(location: 0, length: ns.length)) {
                guard words.contains(ns.substring(with: match.range)) else { continue }
                apply(.keyword, match.range, to: &out, line: line, claimed: &claimed)
            }
        }

        return out
    }

    private static func apply(
        _ token: Token,
        _ nsRange: NSRange,
        to out: inout AttributedString,
        line: String,
        claimed: inout IndexSet
    ) {
        guard nsRange.location != NSNotFound, nsRange.length > 0 else { return }
        let span = nsRange.location..<(nsRange.location + nsRange.length)
        // Already owned by a higher-priority pass — leave it alone.
        guard claimed.intersection(IndexSet(integersIn: span)).isEmpty else { return }

        guard
            let range = Range(nsRange, in: line),
            let lower = AttributedString.Index(range.lowerBound, within: out),
            let upper = AttributedString.Index(range.upperBound, within: out)
        else { return }

        out[lower..<upper].foregroundColor = token.color
        if token == .keyword || token == .comment {
            out[lower..<upper].font = SK.Type_.mono
        }
        claimed.insert(integersIn: span)
    }

    /// Cross-platform clipboard write.
    public static func copy(_ text: String) {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

#Preview("SKCodeBlock") {
    ScrollView {
        VStack(spacing: SK.Space.lg) {
            SKCodeBlock(
                """
                // Streaming is just a sequence of partial strings.
                func stream(_ prompt: String) async throws {
                    var reply = ""
                    for try await chunk in client.send(prompt) {
                        reply += chunk          // append, never replace
                        await render(reply)
                    }
                }
                """,
                language: "swift",
                showsLineNumbers: true
            )

            SKCodeBlock(
                """
                {
                  "model": "claude-opus-5",
                  "stream": true,
                  "max_tokens": 1024
                }
                """,
                language: "json"
            )
        }
        .padding(SK.Space.lg)
    }
    .background(SK.Palette.surface)
}
