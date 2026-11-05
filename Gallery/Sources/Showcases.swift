//
//  Showcases.swift
//  Swift Kit UI Gallery
//
//  Live demos — real components with real state. Drag the toggle, mash the
//  button, flick the tab bar, pull the list.
//
//  Each showcase takes the registry's variant id so the picker on the detail
//  screen drives the actual component rather than a lookalike.
//

import SwiftUI
import SwiftKitUI

struct ComponentShowcase: View {
    let componentID: String
    let variantID: String

    var body: some View {
        switch componentID {
        case "sk-toggle": ToggleShow(v: variantID)
        case "sk-button": ButtonShow(v: variantID)
        case "sk-tab-bar": TabBarShow(v: variantID)
        case "sk-card": CardShow(v: variantID)
        case "sk-row": RowShow(v: variantID)
        case "sk-section": SectionShow(v: variantID)
        case "sk-badge": BadgeShow(v: variantID)
        case "sk-icon-bubble": IconBubbleShow(v: variantID)
        case "sk-chip": ChipShow(v: variantID)
        case "sk-segmented-control": SegmentedShow()
        case "sk-slider": SliderShow(v: variantID)
        case "sk-stepper": StepperShow()
        case "sk-wheel-picker": WheelShow()
        case "sk-color-swatch-picker": SwatchShow()
        case "sk-rating": RatingShow()
        case "sk-text-field": TextFieldShow(v: variantID)
        case "sk-search-bar": SearchShow()
        case "sk-o-t-p-field", "sk-otp-field": OTPShow()
        case "sk-gauge": GaugeShow()
        case "sk-progress-ring": RingShow(v: variantID)
        case "sk-activity-indicator": ActivityShow(v: variantID)
        case "sk-toast": ToastShow(v: variantID)
        case "sk-tooltip": TooltipShow(v: variantID)
        case "sk-alert": AlertShow(v: variantID)
        case "sk-bottom-sheet": SheetShow(v: variantID)
        case "sk-skeleton": SkeletonShow(v: variantID)
        case "sk-empty-state": EmptyShow(v: variantID)
        case "sk-navigation-bar": NavBarShow()
        case "sk-side-menu": SideMenuShow(v: variantID)
        case "sk-accordion": AccordionShow()
        case "sk-carousel": CarouselShow()
        case "sk-page-indicator": PageIndicatorShow(v: variantID)
        case "sk-timeline": TimelineShow()
        case "sk-glass-panel": GlassShow(v: variantID)
        case "sk-neumorphic-card": NeumorphicShow(v: variantID)
        case "sk-confetti": ConfettiShow()
        case "sk-avatar": AvatarShow(v: variantID)
        case "sk-pull-to-refresh": PullShow()
        case "sk-sparkline": SparkShow(v: variantID)
        case "sk-floating-action-button": FABShow(v: variantID)

        // Wave 1 — AI / Assistant
        case "sk-chat-bubble": ChatBubbleShow(v: variantID)
        case "sk-streaming-text": StreamingTextShow()
        case "sk-chat-composer": ChatComposerShow()
        case "sk-markdown-view": MarkdownShow()
        case "sk-code-block": CodeBlockShow(v: variantID)
        case "sk-reasoning-block": ReasoningShow(v: variantID)
        case "sk-tool-call-card": ToolCallShow(v: variantID)
        case "sk-citation-chip": CitationShow(v: variantID)
        case "sk-token-meter": TokenMeterShow(v: variantID)
        case "sk-model-picker": ModelPickerShow(v: variantID)
        case "sk-prompt-suggestions": PromptSuggestionsShow(v: variantID)
        case "sk-voice-orb": VoiceOrbShow(v: variantID)
        case "sk-message-actions": MessageActionsShow()
        case "sk-attachment-tray": AttachmentTrayShow()
        case "sk-conversation-row": ConversationRowShow()
        default:
            Text("No preview for \(componentID)")
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelTertiary)
        }
    }
}


// MARK: - Full-screen stage

/// Some components own the whole screen — overlays, drawers, anything with its
/// own ScrollView. Nesting those inside the detail page's ScrollView and its
/// preview card is why they looked broken: a nested vertical scroll view never
/// gets the gesture, and an overlay is clipped to the card instead of covering
/// the app. These get a real stage instead.
struct DemoLauncher<Demo: View>: View {
    let note: String
    @ViewBuilder var demo: () -> Demo
    @State private var open = false

    var body: some View {
        VStack(spacing: SK.Space.md) {
            Image(systemName: "arrow.down.left.and.arrow.up.right")
                .font(SK.Icon.symbol(SK.Icon.xl))
                .foregroundStyle(SK.Palette.accent)
            Button("Open full-screen demo") { open = true }
                .buttonStyle(.sk(.primary, fullWidth: false))
            Text(note)
                .font(SK.Type_.caption)
                .foregroundStyle(SK.Palette.labelSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, SK.Space.lg)
        .fullScreenCover(isPresented: $open) { DemoStage { demo() } }
    }
}

private struct DemoStage<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SK.Palette.surfaceSunken.ignoresSafeArea()
            content
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(SK.Icon.symbol(SK.Icon.sm, weight: .bold))
                    .foregroundStyle(SK.Palette.label)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(SK.Palette.fill))
            }
            .padding(SK.Space.lg)
            .zIndex(999)
        }
    }
}

// MARK: - Controls

private struct ToggleShow: View {
    let v: String
    @State private var a = true
    @State private var b = false
    var body: some View {
        VStack(spacing: SK.Space.md) {
            Toggle("Push Notifications", isOn: $a)
            Toggle("Face ID", isOn: $b)
            Toggle("Unavailable", isOn: .constant(true)).disabled(true)
        }
        .toggleStyle(v == "liquid-glass" ? SKToggleStyle(.liquidGlass) : SKToggleStyle())
        .font(SK.Type_.body)
        .foregroundStyle(SK.Palette.label)
        .padding(SK.Space.lg)
        .skSurface(.bordered, radius: SK.Radius.lg)
    }
}

private struct ButtonShow: View {
    let v: String
    @State private var loading = false
    private var role: SKButtonStyle.Role {
        switch v {
        case "secondary": .secondary
        case "ghost": .ghost
        case "destructive": .destructive
        case "liquid-glass": .liquidGlass
        default: .primary
        }
    }
    var body: some View {
        VStack(spacing: SK.Space.md) {
            Button(role == .destructive ? "Delete Account" : "Start Free Trial") {}
                .buttonStyle(SKButtonStyle(role))
            Button("Tap to load") {
                loading = true
                Task { try? await Task.sleep(for: .seconds(1.5)); loading = false }
            }
            .buttonStyle(SKButtonStyle(role, loading: loading))
            Button("Disabled") {}.buttonStyle(SKButtonStyle(role)).disabled(true)
        }
    }
}

private struct SegmentedShow: View {
    @State private var billing = "Annual"
    @State private var mode = "Grid"
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            SKSegmentedControl(selection: $billing, options: ["Monthly", "Annual"]) { $0 }
            SKSegmentedControl(selection: $mode, options: ["List", "Grid", "Map"]) { $0 }
        }
    }
}

private struct SliderShow: View {
    let v: String
    @State private var value = 0.45
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            if v == "stepped" {
                SKSlider(value: $value, in: 0...10, step: 1) {
                    Text("Steps of 1 — feel the ticks")
                        .font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
                }
            } else {
                SKSlider(value: $value) {
                    Text("Volume").font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
                }
            }
        }
    }
}

private struct StepperShow: View {
    @State private var qty = 2
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            SKStepper(value: $qty, in: 0...20)
            Text("Hold + or − to repeat")
                .font(SK.Type_.caption).foregroundStyle(SK.Palette.labelTertiary)
        }
    }
}

private struct WheelShow: View {
    @State private var weight = 72
    var body: some View {
        SKWheelPicker(selection: $weight, values: Array(40...120)) { "\($0)" }
    }
}

private struct SwatchShow: View {
    @State private var color = Color.purple
    private let palette: [Color] = [.purple, .blue, .teal, .green, .yellow,
                                    .orange, .red, .pink, .indigo, .mint, .brown, .gray]
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            SKColorSwatchPicker(selection: $color, colors: palette)
            RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous)
                .fill(color).frame(height: 56).skAnimation(.settle, value: color)
        }
    }
}

private struct RatingShow: View {
    @State private var stars = 3
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            SKRating(value: $stars, size: SK.Icon.xl)
            Text("Drag across the stars")
                .font(SK.Type_.caption).foregroundStyle(SK.Palette.labelTertiary)
        }
    }
}

private struct ChipShow: View {
    let v: String
    @State private var selected: Set<String> = ["SwiftUI"]
    private let tags = ["SwiftUI", "UIKit", "Metal"]
    var body: some View {
        VStack(spacing: SK.Space.md) {
            HStack(spacing: SK.Space.sm) {
                ForEach(tags, id: \.self) { tag in
                    if v == "removable" {
                        SKChip(tag, isSelected: true, onRemove: {})
                    } else {
                        SKChip(tag, isSelected: selected.contains(tag)) {
                            if selected.contains(tag) { selected.remove(tag) } else { selected.insert(tag) }
                        }
                    }
                }
            }
            SKChip("With icon", systemImage: "star.fill")
        }
    }
}

// MARK: - Inputs

private struct TextFieldShow: View {
    let v: String
    @State private var text = ""
    var body: some View {
        VStack(spacing: SK.Space.sm) {
            switch v {
            case "secure":
                SKTextField("Password", text: $text, systemImage: "lock.fill", isSecure: true)
            case "error":
                SKTextField("Username", text: .constant("taken"),
                            error: "That username is already in use.")
            default:
                SKTextField("Email", text: $text, systemImage: "envelope.fill",
                            autocapitalization: .never)
            }
        }
    }
}

private struct SearchShow: View {
    @State private var query = ""
    var body: some View {
        VStack(spacing: SK.Space.md) {
            SKSearchBar(text: $query, placeholder: "Search components")
            Text("Tap to see Cancel slide in")
                .font(SK.Type_.caption).foregroundStyle(SK.Palette.labelTertiary)
        }
    }
}

private struct OTPShow: View {
    @State private var code = ""
    @State private var invalid = false
    var body: some View {
        VStack(spacing: SK.Space.md) {
            SKOTPField(code: $code, isInvalid: invalid) { invalid = $0 != "123456" }
            Text(invalid ? "That code is not right." : "Try 123456")
                .font(SK.Type_.caption)
                .foregroundStyle(invalid ? SK.Palette.danger : SK.Palette.labelTertiary)
        }
    }
}

// MARK: - Surfaces

private struct CardShow: View {
    let v: String
    private var style: SK.Surface {
        switch v {
        case "elevated": .elevated
        case "liquid-glass": .liquidGlass
        default: .bordered
        }
    }
    var body: some View {
        VStack(spacing: SK.Space.md) {
            SKCard(style: style) {
                VStack(alignment: .leading, spacing: SK.Space.xs) {
                    Text("Swift Kit UI").font(SK.Type_.headline)
                    Text("One padding scale, everywhere.")
                        .font(SK.Type_.caption).foregroundStyle(SK.Palette.labelSecondary)
                }
            }
            SKCard(style: style, onTap: {}) {
                Text("Tappable — press me").font(SK.Type_.headline)
            }
        }
    }
}

private struct GlassShow: View {
    let v: String
    private var intensity: SKGlassPanel<AnyView>.Intensity {
        switch v {
        case "subtle": .subtle
        case "strong": .strong
        default: .regular
        }
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .blue, .teal],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous))
            SKGlassPanel(tint: v == "strong" ? .purple : nil, intensity: intensity) {
                AnyView(
                    VStack(alignment: .leading, spacing: SK.Space.xs) {
                        Text("Now Playing").font(SK.Type_.caption).foregroundStyle(.white.opacity(0.75))
                        Text("Liquid Glass").font(SK.Type_.title).foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
            }
            .padding(SK.Space.lg)
        }
        .frame(height: 180)
    }
}

private struct NeumorphicShow: View {
    let v: String
    var body: some View {
        let bg = SK.Palette.surfaceSunken
        return VStack(spacing: SK.Space.lg) {
            SKNeumorphicCard(style: v == "pressed" ? .pressed : .raised, background: bg) {
                Text(v == "pressed" ? "Pressed" : "Raised")
                    .font(SK.Type_.headline).foregroundStyle(SK.Palette.label)
            }
            HStack(spacing: SK.Space.md) {
                ForEach(["backward.fill", "play.fill", "forward.fill"], id: \.self) { s in
                    SKNeumorphicCard(background: bg, radius: SK.Radius.pill, padding: SK.Space.md) {
                        Image(systemName: s).font(SK.Icon.symbol(SK.Icon.md))
                            .foregroundStyle(SK.Palette.accent)
                    }
                }
            }
        }
        .padding(SK.Space.lg)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous))
    }
}

// MARK: - Lists

private struct RowShow: View {
    let v: String
    var body: some View {
        VStack(spacing: 0) {
            SKRow(title: "Wi-Fi", subtitle: "HomeNetwork", systemImage: "wifi") {
                Text("On").font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
            }
            SKRow(title: "Account", systemImage: "person.fill",
                  onTap: v == "tappable" ? {} : nil) { SKChevron() }
            SKRow(title: "Sign Out", systemImage: "arrow.right.square",
                  tint: SK.Palette.danger, showsSeparator: false, onTap: {})
        }
        .skSurface(.bordered, radius: SK.Radius.lg)
        .clipShape(RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous))
    }
}

private struct SectionShow: View {
    let v: String
    var body: some View {
        SKSection("Preferences", footer: "Synced across your devices.",
                  style: v == "elevated" ? .elevated : .bordered) {
            SKRow(title: "Wi-Fi", systemImage: "wifi")
            SKRow(title: "Bluetooth", systemImage: "dot.radiowaves.right")
            SKRow(title: "Airplane Mode", systemImage: "airplane", showsSeparator: false)
        }
    }
}

// MARK: - Feedback

private struct BadgeShow: View {
    let v: String
    var body: some View {
        VStack(spacing: SK.Space.md) {
            if v == "circle" {
                HStack(spacing: SK.Space.md) {
                    SKBadge("3", tone: .danger, shape: .circle)
                    SKBadge("12", tone: .accent, shape: .circle)
                    SKBadge("9", tone: .success, shape: .circle)
                }
            } else {
                HStack(spacing: SK.Space.sm) {
                    SKBadge("Neutral"); SKBadge("Pro", tone: .accent)
                    SKBadge("Live", tone: .success, systemImage: "dot.radiowaves.left.and.right")
                }
                HStack(spacing: SK.Space.sm) {
                    SKBadge("Beta", tone: .warning); SKBadge("Expired", tone: .danger)
                }
            }
        }
    }
}

private struct IconBubbleShow: View {
    let v: String
    private var shape: SKIconBubble.Shape_ { v == "circle" ? .circle : .rounded }
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            HStack(spacing: SK.Space.md) {
                SKIconBubble("star.fill", shape: shape)
                SKIconBubble("checkmark", tone: .success, shape: shape)
                SKIconBubble("exclamationmark.triangle.fill", tone: .warning, shape: shape)
                SKIconBubble("trash.fill", tone: .danger, shape: shape)
                SKIconBubble("gear", tone: .neutral, shape: shape)
            }
            HStack(spacing: SK.Space.md) {
                ForEach([SK.Icon.sm, SK.Icon.md, SK.Icon.lg, SK.Icon.xl], id: \.self) { size in
                    SKIconBubble("bolt.fill", shape: shape, size: size)
                }
            }
        }
    }
}

private struct ActivityShow: View {
    let v: String
    private var style: SKActivityIndicator.Style {
        switch v { case "arc": .arc; case "bars": .bars; default: .dots }
    }
    var body: some View {
        HStack(spacing: SK.Space.xxl) {
            SKActivityIndicator(style: style, size: 28)
            SKActivityIndicator(style: style, size: 44)
            SKActivityIndicator(style: style, tint: SK.Palette.success, size: 56)
        }
    }
}

private struct RingShow: View {
    let v: String
    @State private var progress = 0.35
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            HStack(spacing: SK.Space.xl) {
                if v == "indeterminate" {
                    SKProgressRing().frame(width: 72)
                    SKProgressRing(tint: SK.Palette.success).frame(width: 48)
                } else {
                    SKProgressRing(value: progress, showsPercentage: true).frame(width: 92)
                    SKProgressRing(value: 0.8, tint: SK.Palette.success).frame(width: 56)
                }
            }
            if v != "indeterminate" {
                Slider(value: $progress, in: 0...1).tint(SK.Palette.accent)
            }
        }
    }
}

private struct GaugeShow: View {
    @State private var value = 0.72
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            SKGauge(value: value) {
                VStack(spacing: -2) {
                    Text("\(Int(value * 100))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(SK.Palette.label)
                        .contentTransition(.numericText())
                    Text("SCORE")
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelTertiary)
                }
            }
            .frame(width: 168)
            Slider(value: $value, in: 0...1).tint(SK.Palette.accent)
        }
    }
}

private struct ToastShow: View {
    let v: String
    private var style: SKToast.Style {
        switch v { case "success": .success; case "warning": .warning; case "error": .error; default: .info }
    }
    private var message: String {
        switch v {
        case "success": "Saved to your library"
        case "warning": "Running low on space"
        case "error": "Could not connect"
        default: "Synced 42 items"
        }
    }
    var body: some View {
        DemoLauncher(note: "A toast overlays the whole app, so it needs the full screen to land correctly.") {
            ToastStage(style: style, message: message)
        }
    }
}

private struct ToastStage: View {
    let style: SKToast.Style
    let message: String
    @State private var toast: SKToast?

    var body: some View {
        VStack(spacing: SK.Space.md) {
            Button("Show toast") { toast = SKToast(message, style: style) }
                .buttonStyle(.sk(.primary, fullWidth: false))
            Text("Swipe it up to dismiss early")
                .font(SK.Type_.caption).foregroundStyle(SK.Palette.labelTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .skToast($toast)
    }
}

private struct SkeletonShow: View {
    let v: String
    var body: some View {
        VStack(alignment: .leading, spacing: SK.Space.lg) {
            if v == "text" {
                SKSkeleton(.text(lines: 3))
                SKSkeleton(.rect, size: 90, cornerRadius: SK.Radius.lg)
            } else {
                SKSkeletonRow(); SKSkeletonRow(); SKSkeletonRow()
            }
        }
    }
}

private struct EmptyShow: View {
    let v: String
    var body: some View {
        if v == "plain" {
            SKEmptyState(systemImage: "wifi.slash", title: "You're offline",
                         message: "Check your connection and try again.",
                         tint: SK.Palette.warning)
        } else {
            SKEmptyState(systemImage: "tray", title: "No messages yet",
                         message: "When someone writes, it lands here.",
                         actionTitle: "Refresh") {}
        }
    }
}

// MARK: - Overlays

private struct TooltipShow: View {
    let v: String
    @State private var shown = true
    var body: some View {
        VStack {
            if v == "top" { Spacer().frame(height: 70) }
            Image(systemName: "questionmark.circle.fill")
                .font(SK.Icon.symbol(SK.Icon.xl))
                .foregroundStyle(SK.Palette.accent)
                .onTapGesture { shown.toggle() }
                .skTooltip(isPresented: $shown, edge: v == "top" ? .top : .bottom) {
                    Text("Tap the icon to toggle this tip.")
                }
            if v != "top" { Spacer().frame(height: 70) }
        }
    }
}

private struct AlertShow: View {
    let v: String
    var body: some View {
        DemoLauncher(note: "An alert dims the whole app behind it — clipped to a card it reads as a box, not an alert.") {
            AlertStage(v: v)
        }
    }
}

private struct AlertStage: View {
    let v: String
    @State private var shown = false
    @State private var name = "Untitled"

    var body: some View {
        VStack(spacing: SK.Space.md) {
            Button(v == "text-field" ? "Rename…" : "Delete project…") { shown = true }
                .buttonStyle(.sk(v == "text-field" ? .secondary : .destructive, fullWidth: false))
            if v == "text-field" {
                Text(name).font(SK.Type_.caption).foregroundStyle(SK.Palette.labelSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AlertVariant(v: v, shown: $shown, name: $name))
    }
}

/// Two alert overloads with different signatures cannot sit in one ternary,
/// so the variant choice is made by a modifier instead.
private struct AlertVariant: ViewModifier {
    let v: String
    @Binding var shown: Bool
    @Binding var name: String

    func body(content: Content) -> some View {
        if v == "text-field" {
            content.skAlert(isPresented: $shown, title: "Rename",
                            text: $name, placeholder: "Project name",
                            confirm: .init(title: "Save"))
        } else {
            content.skAlert(isPresented: $shown, title: "Delete project?",
                            message: "This removes every file. It cannot be undone.",
                            systemImage: "trash.fill",
                            confirm: .init(title: "Delete", role: .destructive))
        }
    }
}

private struct SheetShow: View {
    let v: String
    var body: some View {
        DemoLauncher(note: "A sheet rises from the bottom of the screen. Drag it down, or flick, to dismiss.") {
            SheetStage(v: v)
        }
    }
}

private struct SheetStage: View {
    let v: String
    @State private var shown = false

    var body: some View {
        Button("Open \(v) sheet") { shown = true }
            .buttonStyle(.sk(.primary, fullWidth: false))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .skBottomSheet(isPresented: $shown, detent: v == "large" ? .large : .medium) {
                VStack(alignment: .leading, spacing: SK.Space.md) {
                    Text("Share").font(SK.Type_.title).foregroundStyle(SK.Palette.label)
                    Text("Drag the grabber down, or flick, to dismiss.")
                        .font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
                    ForEach(["Copy link", "Add to favourites", "Export"], id: \.self) { row in
                        HStack(spacing: SK.Space.md) {
                            SKIconBubble("square.and.arrow.up", size: SK.Icon.sm)
                            Text(row).font(SK.Type_.body).foregroundStyle(SK.Palette.label)
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SK.Space.xl)
            }
    }
}

// MARK: - Navigation

private struct TabBarShow: View {
    let v: String
    private enum Tab: Hashable { case home, search, saved, profile }
    @State private var selection: Tab = .home
    private let items: [SKTabItem<Tab>] = [
        .init(tab: .home, title: "Home", systemImage: "house.fill"),
        .init(tab: .search, title: "Search", systemImage: "magnifyingglass"),
        .init(tab: .saved, title: "Saved", systemImage: "bookmark.fill"),
        .init(tab: .profile, title: "Profile", systemImage: "person.fill"),
    ]
    var body: some View {
        VStack(spacing: SK.Space.xl) {
            Image(systemName: items.first { $0.tab == selection }?.systemImage ?? "house.fill")
                .font(SK.Icon.symbol(40, weight: .regular))
                .foregroundStyle(SK.Palette.accent)
                .frame(height: 48)
                .contentTransition(.symbolEffect(.replace))
                .skAnimation(.snap, value: selection)
            SKTabBar(selection: $selection, tabs: items,
                     style: v == "liquid-glass" ? .liquidGlass : .floating)
        }
    }
}

private struct NavBarShow: View {
    var body: some View {
        DemoLauncher(note: "The bar fades its background in as content scrolls under it. That needs a real scroll view, which cannot nest inside this page.") {
            NavBarStage()
        }
    }
}

private struct NavBarStage: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            SKNavigationBar(title: "Settings", scrollOffset: offset) {
                Image(systemName: "chevron.left")
                    .font(SK.Icon.symbol(SK.Icon.md, weight: .semibold))
                    .foregroundStyle(SK.Palette.accent)
            } trailing: {
                Image(systemName: "ellipsis.circle")
                    .font(SK.Icon.symbol(SK.Icon.md)).foregroundStyle(SK.Palette.accent)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SK.Space.lg) {
                    Text("Settings").font(SK.Type_.display).foregroundStyle(SK.Palette.label)
                    Text("Scroll up — the title and background fade in as the large title leaves.")
                        .font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
                    ForEach(0..<20, id: \.self) { i in
                        Text("Row \(i + 1)")
                            .font(SK.Type_.body)
                            .foregroundStyle(SK.Palette.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(SK.Space.md)
                            .skSurface(.bordered, radius: SK.Radius.md)
                    }
                }
                .padding(SK.Space.lg)
                .background {
                    GeometryReader { g in
                        Color.clear.preference(key: SKScrollOffsetKey.self,
                                               value: -g.frame(in: .named("nav")).minY)
                    }
                }
            }
            .coordinateSpace(name: "nav")
            .onPreferenceChange(SKScrollOffsetKey.self) { offset = $0 }
        }
    }
}

private struct SideMenuShow: View {
    let v: String
    var body: some View {
        DemoLauncher(note: "The drawer pushes and scales the whole app behind it. Drag in from the edge, or tap the button.") {
            SideMenuStage(v: v)
        }
    }
}

private struct SideMenuStage: View {
    let v: String
    @State private var open = false

    var body: some View {
        VStack(spacing: SK.Space.md) {
            Button("Open menu") { open = true }
                .buttonStyle(.sk(.primary, fullWidth: false))
            Text("Or drag in from the \(v == "trailing" ? "right" : "left") edge")
                .font(SK.Type_.caption).foregroundStyle(SK.Palette.labelTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .skSideMenu(isOpen: $open, edge: v == "trailing" ? .trailing : .leading) {
            VStack(alignment: .leading, spacing: SK.Space.lg) {
                Text("Menu").font(SK.Type_.title).foregroundStyle(SK.Palette.label)
                ForEach(["Home", "Library", "Downloads", "Settings"], id: \.self) {
                    Text($0).font(SK.Type_.body).foregroundStyle(SK.Palette.labelSecondary)
                }
                Spacer()
            }
            .padding(SK.Space.xl)
            .padding(.top, SK.Space.xxxl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PageIndicatorShow: View {
    let v: String
    @State private var page = 0
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            RoundedRectangle(cornerRadius: SK.Radius.lg, style: .continuous)
                .fill(SK.Palette.accentSoft)
                .overlay(Text("Page \(page + 1)").font(SK.Type_.title))
                .frame(height: 130)
            SKPageIndicator(count: 4, index: $page, style: v == "bars" ? .bars : .dots)
            Text("Tap a dot").font(SK.Type_.caption).foregroundStyle(SK.Palette.labelTertiary)
        }
    }
}

// MARK: - Layout

private struct AccordionShow: View {
    var body: some View {
        VStack(spacing: SK.Space.sm) {
            SKAccordion("What is included?", systemImage: "shippingbox.fill", initiallyExpanded: true) {
                Text("Every component, every variant, the full source, and a year of updates.")
            }
            SKAccordion("Can I use it commercially?", systemImage: "briefcase.fill") {
                Text("Yes. One licence per developer, unlimited apps.")
            }
        }
    }
}

private struct CarouselItem: Identifiable { let id: Int; let title: String; let tint: Color }

private struct CarouselShow: View {
    private let cards = [
        CarouselItem(id: 0, title: "Components", tint: .purple),
        CarouselItem(id: 1, title: "Animations", tint: .blue),
        CarouselItem(id: 2, title: "Screens", tint: .teal),
    ]
    var body: some View {
        SKCarousel(items: cards, cardWidth: 200, height: 220) { card in
            VStack(alignment: .leading) {
                Spacer()
                Text(card.title).font(SK.Type_.title).foregroundStyle(.white)
            }
            .padding(SK.Space.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [card.tint, card.tint.opacity(0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: SK.Radius.xl, style: .continuous))
        }
    }
}

private struct TimelineShow: View {
    var body: some View {
        SKTimeline(steps: [
            .init(title: "Order placed", subtitle: "Monday, 9:14", state: .done),
            .init(title: "Payment confirmed", subtitle: "Monday, 9:15", state: .done),
            .init(title: "Out for delivery", subtitle: "Arriving today", state: .current),
            .init(title: "Delivered", state: .upcoming),
        ])
    }
}

// MARK: - Data / display / delight

private struct SparkShow: View {
    let v: String
    @State private var data: [Double] = [3, 5, 4, 8, 6, 11, 9, 14]
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            VStack(alignment: .leading, spacing: SK.Space.xs) {
                Text("Revenue").font(SK.Type_.caption).foregroundStyle(SK.Palette.labelSecondary)
                Text("$4,280").font(SK.Type_.title).foregroundStyle(SK.Palette.label)
                SKSparkline(values: data, tint: SK.Palette.success,
                            showsFill: v != "line").frame(height: 44)
            }
            .padding(SK.Space.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .skSurface(.bordered, radius: SK.Radius.lg)

            Button("Shuffle") { data = (0..<8).map { _ in Double.random(in: 1...15) } }
                .buttonStyle(.sk(.secondary, fullWidth: false))
        }
    }
}

private struct AvatarShow: View {
    let v: String
    var body: some View {
        VStack(spacing: SK.Space.xl) {
            if v == "group" {
                SKAvatarGroup(names: ["Ada", "Alan", "Grace", "Katherine", "Margaret"], size: 44)
            } else {
                HStack(spacing: SK.Space.lg) {
                    SKAvatar(name: "Ahmed Gagan", presence: .online)
                    SKAvatar(name: "Ada Lovelace", presence: .away)
                    SKAvatar(name: "Grace Hopper", presence: .offline)
                }
                HStack(spacing: SK.Space.lg) {
                    SKAvatar(name: "Alan Turing", size: 30)
                    SKAvatar(name: "Alan Turing", size: 48)
                    SKAvatar(name: "Alan Turing", size: 64, presence: .online)
                }
            }
        }
    }
}

private struct ConfettiShow: View {
    @State private var count = 0
    var body: some View {
        VStack(spacing: SK.Space.lg) {
            Image(systemName: "party.popper.fill")
                .font(SK.Icon.symbol(48)).foregroundStyle(SK.Palette.accent)
            Button("Celebrate") { count += 1 }
                .buttonStyle(.sk(.primary, fullWidth: false))
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .skConfetti(trigger: count)
    }
}

private struct PullShow: View {
    var body: some View {
        DemoLauncher(note: "Pull-to-refresh needs to own the scroll view. Nested inside this page it never receives the gesture.") {
            PullStage()
        }
    }
}

private struct PullStage: View {
    @State private var items = Array(1...14)

    var body: some View {
        if #available(iOS 18.0, *) {
            stage
        } else {
            Text("Pull-to-refresh requires iOS 18.")
                .font(SK.Type_.callout)
                .foregroundStyle(SK.Palette.labelSecondary)
        }
    }

    @available(iOS 18.0, *)
    private var stage: some View {
        SKRefreshableScrollView {
            try? await Task.sleep(for: .seconds(1.2))
            items = items.map { $0 + 14 }
        } content: {
            VStack(spacing: SK.Space.sm) {
                Text("Pull down to refresh")
                    .font(SK.Type_.caption)
                    .foregroundStyle(SK.Palette.labelTertiary)
                    .padding(.top, SK.Space.xxxl)
                ForEach(items, id: \.self) { i in
                    Text("Item \(i)").font(SK.Type_.body)
                        .foregroundStyle(SK.Palette.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SK.Space.md)
                        .skSurface(.bordered, radius: SK.Radius.md)
                }
            }
            .padding(SK.Space.lg)
        }
    }
}

private struct FABShow: View {
    let v: String
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
            if v == "single" {
                SKFloatingActionButton(onTap: {})
            } else {
                SKFloatingActionButton(actions: [
                    .init(symbol: "camera.fill", title: "Photo") {},
                    .init(symbol: "mic.fill", title: "Audio") {},
                    .init(symbol: "doc.fill", title: "Document") {},
                ])
            }
        }
        .frame(height: 280)
        .padding(SK.Space.sm)
    }
}
