//
//  ShowcasesAI.swift
//  Swift Kit UI Gallery
//
//  Live demos for the AI / Assistant components.
//
//  These are driven by fake streams rather than static props on purpose. A
//  streaming component photographed mid-render proves nothing; the point of
//  every one of these is what it does over time, so each demo feeds it a
//  signal with the same shape a real one has — uneven token bursts, speech
//  with pauses in it, uploads at different speeds.
//

import SwiftUI
import SwiftKitUI

// MARK: - Shared fixtures

enum AIFixture {
    static let reply = """
    Revenue grew 12% this quarter and churn fell to 1.8%. The gain is \
    concentrated in annual plans, which now account for 61% of new \
    subscriptions — up from 44% in Q2. Monthly conversion was flat, so the \
    shift looks like pricing rather than demand.
    """

    static let markdown = """
    ## Migration report

    The overnight run finished at **04:12**. Two rows were rejected for a null
    `tenant_id`; everything else moved cleanly.

    ### What moved

    - 1,284,003 records in 38 minutes
    - Peak throughput of *9,400 rows/sec*
    - Zero lock escalations

    > The rejected rows are in `migration_errors`, not lost.

    ```swift
    let failed = try await store.rejected(batch: 42)
    try await store.retry(failed, policy: .exponential)
    ```

    1. Re-run the batch
    2. Verify the row count
    3. Drop the staging table
    """

    static let reasoningSteps = [
        "Looking at the Q3 revenue table.",
        "Annual plans are 61% of new subscriptions, up from 44%.",
        "Checking whether monthly conversion moved at all.",
        "Monthly is flat at 3.1% — so this is a mix shift, not demand.",
        "Confirming churn: 1.8%, down from 2.4%.",
    ]

    static let models = [
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

    static let sources = [
        SKCitationSource(
            title: "SaaS Benchmarks 2026: Retention and Expansion",
            domain: "openviewpartners.com",
            snippet: "Median annual-plan mix rose to 58% among companies above $1M ARR, with churn concentrated in month-to-month cohorts.",
            url: URL(string: "https://example.com")
        ),
        SKCitationSource(
            title: "Quarterly revenue teardown",
            domain: "chartmogul.com",
            snippet: "A mix shift toward annual billing typically depresses reported MRR growth for a single quarter."
        ),
    ]

    /// Feeds `text` from `full` in uneven bursts — what a real stream looks like.
    ///
    /// `@MainActor` because it mutates a SwiftUI binding and calls back into
    /// view code; as a nonisolated async function Swift 6 correctly refuses to
    /// let the completion closure cross actors.
    @MainActor
    static func stream(
        _ full: String,
        into text: Binding<String>,
        done: (() -> Void)? = nil
    ) async {
        var index = full.startIndex
        while index < full.endIndex {
            let burst = [1, 1, 2, 14, 1, 3, 28, 1, 1, 9].randomElement() ?? 3
            let next = full.index(index, offsetBy: burst, limitedBy: full.endIndex) ?? full.endIndex
            text.wrappedValue += String(full[index..<next])
            index = next
            try? await Task.sleep(for: .milliseconds([40, 60, 90, 260].randomElement() ?? 60))
        }
        done?()
    }
}

// MARK: - Chat bubble

struct ChatBubbleShow: View {
    let v: String

    var body: some View {
        VStack(spacing: SK.Space.xs) {
            if v == "states" {
                SKChatBubble("Retry the two rejected rows", role: .user, status: .sent, timestamp: .now)
                SKChatBubble("Queued — I'll report back.", role: .assistant, timestamp: .now)
                SKChatBubble("And export the errors", role: .user, status: .sending)
                SKChatBubble("Send this when you get a chance", role: .user, status: .failed) {}
            } else {
                SKChatBubble("Morning — did the migration finish?", role: .user, position: .first)
                SKChatBubble("Anything fail overnight?", role: .user, position: .last, timestamp: .now)
                SKChatBubble("It finished at 04:12.", role: .assistant, position: .first)
                SKChatBubble(
                    "Two rows were rejected for a null tenant id. Everything else moved cleanly — 1,284,003 records in 38 minutes.",
                    role: .assistant, position: .last, timestamp: .now
                )
            }
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Streaming text

struct StreamingTextShow: View {
    @State private var received = ""
    @State private var streaming = true
    @State private var run = 0

    var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.lg) {
            SKStreamingText(received, isStreaming: streaming)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Replay") {
                received = ""
                streaming = true
                run += 1
            }
            .font(SK.Type_.callout)
            .foregroundStyle(SK.Palette.accent)
            .buttonStyle(.skPress)
        }
        .padding(SK.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .skSurface(.bordered, radius: SK.Radius.lg)
        .task(id: run) {
            await AIFixture.stream(AIFixture.reply, into: $received) { streaming = false }
        }
    }
}

// MARK: - Composer (full screen — it owns a keyboard)

struct ChatComposerShow: View {
    var body: some View {
        DemoLauncher(note: "The composer owns the keyboard and the bottom of the screen, so it needs a real one.") {
            MiniChat()
        }
    }
}

private struct MiniChat: View {
    struct Turn: Identifiable {
        let id = UUID()
        let role: SKChatRole
        var text: String
    }

    @State private var turns: [Turn] = [
        .init(role: .assistant, text: "Ask me about the Q3 numbers.")
    ]
    @State private var draft = ""
    @State private var streaming = false
    @State private var streamTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: SK.Space.sm) {
                        ForEach(turns) { turn in
                            if turn.role == .assistant, turn.id == turns.last?.id, streaming {
                                SKChatBubble(role: .assistant) {
                                    SKStreamingText(turn.text, isStreaming: true)
                                }
                                .id(turn.id)
                            } else {
                                SKChatBubble(turn.text, role: turn.role)
                                    .id(turn.id)
                            }
                        }
                    }
                    .padding(SK.Space.lg)
                }
                .onChange(of: turns.last?.text) { _, _ in
                    withAnimation { proxy.scrollTo(turns.last?.id, anchor: .bottom) }
                }
            }

            SKChatComposer(
                text: $draft,
                isStreaming: streaming,
                onSend: send,
                onStop: {
                    streamTask?.cancel()
                    streaming = false
                },
                onAttach: {},
                onVoice: {}
            )
        }
        .background(SK.Palette.surface)
    }

    private func send() {
        turns.append(.init(role: .user, text: draft))
        draft = ""
        turns.append(.init(role: .assistant, text: ""))
        streaming = true

        streamTask = Task {
            let full = AIFixture.reply
            var index = full.startIndex
            while index < full.endIndex, !Task.isCancelled {
                let burst = [1, 2, 14, 3, 28, 9].randomElement() ?? 3
                let next = full.index(index, offsetBy: burst, limitedBy: full.endIndex) ?? full.endIndex
                turns[turns.count - 1].text += String(full[index..<next])
                index = next
                try? await Task.sleep(for: .milliseconds([50, 80, 240].randomElement() ?? 70))
            }
            streaming = false
        }
    }
}

// MARK: - Markdown

struct MarkdownShow: View {
    var body: some View {
        SKMarkdownView(AIFixture.markdown)
            .padding(SK.Space.md)
    }
}

// MARK: - Code block

struct CodeBlockShow: View {
    let v: String

    var body: some View {
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
                showsLineNumbers: v == "line-numbers"
            )

            if v != "line-numbers" {
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
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Reasoning

struct ReasoningShow: View {
    let v: String
    @State private var trace = ""
    @State private var thinking = true
    @State private var run = 0

    var body: some View {
        Group {
            if v == "finished" {
                SKReasoningBlock(
                    AIFixture.reasoningSteps.joined(separator: "\n"),
                    isThinking: false,
                    duration: 4.2
                )
            } else {
                VStack(spacing: SK.Space.md) {
                    SKReasoningBlock(trace, isThinking: thinking)
                    Button("Replay") {
                        trace = ""
                        thinking = true
                        run += 1
                    }
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.accent)
                    .buttonStyle(.skPress)
                }
                .task(id: run) {
                    for step in AIFixture.reasoningSteps {
                        try? await Task.sleep(for: .milliseconds(1100))
                        if Task.isCancelled { return }
                        trace += (trace.isEmpty ? "" : "\n") + step
                    }
                    try? await Task.sleep(for: .milliseconds(600))
                    thinking = false
                }
            }
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Tool call

struct ToolCallShow: View {
    let v: String

    private var state: SKToolCallState {
        switch v {
        case "success": .success
        case "failure": .failure
        default: .running
        }
    }

    var body: some View {
        VStack(spacing: SK.Space.md) {
            switch state {
            case .running:
                SKToolCallCard("search_web", summary: "q3 saas churn benchmarks 2026",
                               state: .running,
                               detail: #"{ "query": "q3 saas churn benchmarks 2026", "top_k": 5 }"#)
                SKToolCallCard("read_file", summary: "Sources/Billing/Renewals.swift",
                               state: .running)
            case .success:
                SKToolCallCard("read_file", summary: "Sources/Billing/Renewals.swift",
                               state: .success, detail: "418 lines · 14.2 KB", duration: 0.42)
                SKToolCallCard("run_query", summary: "3 rows", state: .success,
                               detail: "SELECT plan, count(*) FROM subs GROUP BY 1", duration: 1.08)
            case .failure:
                SKToolCallCard("run_query", summary: "connection refused on replica-2",
                               state: .failure,
                               detail: "psql: error: connection to server at \"replica-2\" failed",
                               duration: 8.01)
            }
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Citation

struct CitationShow: View {
    let v: String

    var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.lg) {
            Text("Annual plans now account for 61% of new subscriptions, up from 44% in Q2.")
                .font(SK.Type_.body)
                .foregroundStyle(SK.Palette.label)
                .fixedSize(horizontal: false, vertical: true)

            if v == "domain" {
                VStack(alignment: .leading, spacing: SK.Space.sm) {
                    SKCitationChip(source: AIFixture.sources[0], style: .domain)
                    SKCitationChip(source: AIFixture.sources[1], style: .domain)
                }
            } else {
                HStack(spacing: SK.Space.xs) {
                    Text("Sources")
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelTertiary)
                    SKCitationChip(index: 1, source: AIFixture.sources[0])
                    SKCitationChip(index: 2, source: AIFixture.sources[1])
                }
            }

            Text("Tap a source to open it.")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Token meter

struct TokenMeterShow: View {
    let v: String
    @State private var used = 4_200

    var body: some View {
        VStack(spacing: SK.Space.lg) {
            if v == "compact" {
                SKTokenMeter(used: used, limit: 25_000, style: .compact)
            } else {
                SKTokenMeter(used: used, limit: 25_000, onUpgrade: {})
            }

            HStack(spacing: SK.Space.md) {
                Button("Spend 6K") { used = min(25_000, used + 6_000) }
                Button("Reset") { used = 4_200 }
            }
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.accent)
            .buttonStyle(.skPress)
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Model picker

struct ModelPickerShow: View {
    let v: String
    @State private var selection = "claude-sonnet-5"
    @State private var lockedNote = ""

    var body: some View {
        VStack(spacing: SK.Space.md) {
            SKModelPicker(
                models: AIFixture.models,
                selection: $selection,
                style: v == "list" ? .list : .button,
                onLocked: { lockedNote = "\($0.name) needs Pro" }
            )
            if !lockedNote.isEmpty {
                Text(lockedNote)
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.warning)
            }
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Prompt suggestions

struct PromptSuggestionsShow: View {
    let v: String
    @State private var picked = "Nothing yet"

    var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.lg) {
            if v == "rail" {
                SKPromptSuggestions(["Explain", "Shorten", "Add sources", "Make it formal"],
                                    layout: .rail) { picked = $0 }
            } else {
                SKPromptSuggestions([
                    SKPrompt("Summarise this thread", systemImage: "text.alignleft"),
                    SKPrompt("Draft a reply", systemImage: "arrowshape.turn.up.left"),
                    SKPrompt("Find the contract terms", systemImage: "magnifyingglass"),
                    SKPrompt("What changed since Friday?", systemImage: "clock.arrow.circlepath"),
                ]) { picked = $0.text }
                .padding(.horizontal, SK.Space.md)
            }

            Text(picked)
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
                .padding(.horizontal, SK.Space.md)
        }
        .padding(.vertical, SK.Space.md)
    }
}

// MARK: - Voice orb

struct VoiceOrbShow: View {
    let v: String
    @State private var state: SKVoiceState = .listening
    @State private var level: Double = 0

    var body: some View {
        VStack(spacing: SK.Space.xl) {
            SKVoiceOrb(state: state, level: level) {
                state = state == .listening ? .idle : .listening
            }

            Text(String(describing: state).capitalized)
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
        }
        .padding(SK.Space.lg)
        .onAppear {
            switch v {
            case "idle": state = .idle
            case "processing": state = .processing
            default: state = .listening
            }
        }
        // Speech-shaped, not a sine wave: a sine makes any orb look good and
        // proves nothing about how it tracks a real voice.
        .task {
            while !Task.isCancelled {
                let syllables = Int.random(in: 3...7)
                for _ in 0..<syllables {
                    level = Double.random(in: 0.45...1.0)
                    try? await Task.sleep(for: .milliseconds(Int.random(in: 90...170)))
                    level = Double.random(in: 0.10...0.35)
                    try? await Task.sleep(for: .milliseconds(Int.random(in: 60...110)))
                }
                level = 0.04
                try? await Task.sleep(for: .milliseconds(Int.random(in: 500...900)))
            }
        }
    }
}

// MARK: - Message actions

struct MessageActionsShow: View {
    @State private var rating: SKMessageFeedback = .none

    var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            Text(AIFixture.reply)
                .font(SK.Type_.body)
                .foregroundStyle(SK.Palette.label)
                .fixedSize(horizontal: false, vertical: true)

            SKMessageActions(
                copyText: AIFixture.reply,
                feedback: $rating,
                onRegenerate: {},
                onShare: {}
            )
            .padding(.leading, -SK.Space.sm)
        }
        .padding(SK.Space.md)
    }
}

// MARK: - Attachment tray

struct AttachmentTrayShow: View {
    @State private var files: [SKAttachment] = [
        SKAttachment(name: "q3-revenue.png", kind: .image),
        SKAttachment(name: "contract.pdf", kind: .file(ext: "pdf")),
        SKAttachment(name: "standup.m4a", kind: .audio, progress: 0.15),
        SKAttachment(name: "schema.json", kind: .file(ext: "json")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.sm) {
            SKAttachmentTray(
                attachments: files,
                onRemove: { target in files.removeAll { $0.id == target.id } },
                onAdd: { files.append(SKAttachment(name: "new.png", kind: .image, progress: 0.05)) }
            )
            Text("Tap × to remove. The ring fills on anything still uploading.")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
                .padding(.horizontal, SK.Space.lg)
        }
        .padding(.vertical, SK.Space.sm)
        // Slow enough that the ring is actually visible, and restarted once
        // everything lands — a demo of an upload indicator that has finished
        // uploading is a demo of nothing.
        .task {
            var idle = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(300))
                let anyUploading = files.contains { $0.progress != nil }
                if anyUploading {
                    idle = 0
                    files = files.map { file in
                        guard let progress = file.progress else { return file }
                        let next = progress + 0.05
                        return SKAttachment(id: file.id, name: file.name, kind: file.kind,
                                            progress: next >= 1 ? nil : next)
                    }
                } else {
                    idle += 1
                    if idle > 6, let target = files.indices.last {
                        idle = 0
                        let file = files[target]
                        files[target] = SKAttachment(id: file.id, name: file.name,
                                                     kind: file.kind, progress: 0.04)
                    }
                }
            }
        }
    }
}

// MARK: - Conversation row

struct ConversationRowShow: View {
    @State private var selected = "migration"

    var body: some View {
        VStack(spacing: SK.Space.xxs) {
            SKConversationRow(
                title: "Q3 revenue teardown",
                preview: "Annual plans are 61% of new subscriptions — the mix shifted, demand did not.",
                date: .now, isUnread: true, isPinned: true,
                isSelected: selected == "revenue",
                systemImage: "chart.line.uptrend.xyaxis"
            ) { selected = "revenue" }

            SKConversationRow(
                title: "Migration rollback plan",
                preview: "Two rows rejected for a null tenant id; everything else moved cleanly.",
                date: Date(timeIntervalSinceNow: -3600 * 30),
                isSelected: selected == "migration",
                systemImage: "arrow.triangle.2.circlepath"
            ) { selected = "migration" }

            SKConversationRow(
                title: "Onboarding copy",
                preview: "Shorter second screen, and the permission ask moves after the first win.",
                date: Date(timeIntervalSinceNow: -3600 * 96),
                isSelected: selected == "onboarding",
                systemImage: "text.bubble"
            ) { selected = "onboarding" }
        }
        .padding(.vertical, SK.Space.sm)
    }
}
