//
//  SwiftKitUI.swift
//  Swift Kit UI — the foundation.
//
//  This is the ONLY file every component depends on. Add it once, then each
//  component is a single self-contained file you can drop in beside it.
//
//  That rule is deliberate. A component library with a tangled internal
//  dependency graph is one an AI agent gets wrong: it copies one file, misses
//  three others, and the build breaks. One foundation + one file per component
//  is small enough to fit in an agent's head and in yours.
//
//  Requires iOS 17 / macOS 14. iOS 26 features (Liquid Glass) are behind
//  #available and degrade to a hand-built approximation below that.
//
//  https://theswiftk.it.com/ui
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Namespace

/// Design tokens for Swift Kit UI.
///
/// Every component reads its spacing, radii, colour and type from here, which
/// is what makes forty components look like one product instead of forty
/// snippets. Override these values once and the whole kit re-skins.
public enum SK {}

// MARK: - Spacing

extension SK {
    /// A 4pt base scale. Components never hard-code padding.
    public enum Space {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 48
    }

    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 22
        public static let xxl: CGFloat = 28
        /// Use with `.capsule`-style shapes where a true pill is wanted.
        public static let pill: CGFloat = 999
    }

    /// Stroke widths. Hairlines are expressed in points, not pixels, so they
    /// stay visually consistent across scale factors.
    public enum Stroke {
        public static let hairline: CGFloat = 0.5
        public static let thin: CGFloat = 1
        public static let thick: CGFloat = 2
    }
}

// MARK: - Colour

extension SK {
    /// Semantic colours. Always dynamic — every one resolves correctly in both
    /// light and dark without an asset catalogue, so a single copied file works.
    public enum Palette {
        public static let accent = dynamic(light: 0x7C3AED, dark: 0x9B6BFF)

        /// Tinted backgrounds for badges, icon bubbles and selected states.
        /// Use these rather than `.opacity()` on a solid colour — opacity
        /// composites against whatever is behind it and drifts between screens.
        public static let accentSoft = dynamic(light: 0xEDE7FE, dark: 0x2A1F45)
        public static let successSoft = dynamic(light: 0xDDF5E8, dark: 0x11301F)
        public static let warningSoft = dynamic(light: 0xFDF0DC, dark: 0x33260F)
        public static let dangerSoft = dynamic(light: 0xFCE3E5, dark: 0x3A171B)

        public static let surface = dynamic(light: 0xFFFFFF, dark: 0x101014)
        public static let surfaceElevated = dynamic(light: 0xFFFFFF, dark: 0x1A1A20)
        public static let surfaceSunken = dynamic(light: 0xF4F4F6, dark: 0x0A0A0D)

        public static let label = dynamic(light: 0x0B0B0F, dark: 0xFFFFFF)
        public static let labelSecondary = dynamic(light: 0x5B5B66, dark: 0x9C9CA8)
        public static let labelTertiary = dynamic(light: 0x8E8E99, dark: 0x6B6B78)

        public static let separator = dynamic(light: 0xE2E2E8, dark: 0x2C2C35)
        public static let fill = dynamic(light: 0xEDEDF1, dark: 0x22222A)

        /// Skeleton and placeholder blocks. Deliberately darker than `fill` in
        /// light mode: `fill` is tuned to sit on `surface` (white), and on a
        /// tinted or sunken background it washes out to invisible.
        public static let placeholder = dynamic(light: 0xDDDDE6, dark: 0x2A2A34)

        public static let success = dynamic(light: 0x11A35B, dark: 0x30D158)
        public static let warning = dynamic(light: 0xC77700, dark: 0xFFB340)
        public static let danger = dynamic(light: 0xD62F3E, dark: 0xFF5A65)

        /// Builds a colour that resolves per colour scheme. Hex in, `Color` out.
        public static func dynamic(light: UInt32, dark: UInt32) -> Color {
            #if canImport(UIKit)
            return Color(UIColor { traits in
                UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
            })
            #elseif canImport(AppKit)
            return Color(nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                return NSColor(rgb: isDark ? dark : light)
            })
            #else
            return Color(rgb: light)
            #endif
        }
    }
}

// MARK: - Typography

extension SK {
    /// A type ramp built on Dynamic Type. Every style scales with the user's
    /// text-size setting — a component that ignores that is not shippable.
    public enum Type_ {
        public static let display = Font.system(.largeTitle, design: .rounded, weight: .bold)
        public static let title = Font.system(.title2, design: .rounded, weight: .semibold)
        public static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
        public static let body = Font.system(.body, design: .rounded, weight: .regular)
        public static let callout = Font.system(.callout, design: .rounded, weight: .medium)
        public static let caption = Font.system(.caption, design: .rounded, weight: .medium)
        /// Monospaced digits so counters and timers do not jitter mid-animation.
        public static let numeric = Font.system(.body, design: .rounded, weight: .semibold)
            .monospacedDigit()

        /// Code. Ligatures off is deliberate: in a code block `!=` rendering as
        /// a single glyph is a nice touch in an editor and a liability in a
        /// snippet someone is about to retype.
        public static let mono = Font.system(.callout, design: .monospaced, weight: .regular)
        public static let monoCaption = Font.system(.caption, design: .monospaced, weight: .regular)
    }

    /// Icon and control sizing.
    ///
    /// Exists because SF Symbols are sized in points, not Dynamic Type styles,
    /// so `Type_` cannot express them. Without this scale every component
    /// invents its own `.system(size:)` and the icons drift out of alignment.
    public enum Icon {
        public static let xs: CGFloat = 11
        public static let sm: CGFloat = 13
        public static let md: CGFloat = 15
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 26

        /// Apple's minimum comfortable touch target. Anything interactive
        /// should reach this, padding included.
        public static let hitTarget: CGFloat = 44

        /// `Image(systemName: "star").font(SK.Icon.symbol(SK.Icon.md))`
        public static func symbol(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .system(size: size, weight: weight)
        }
    }
}

// MARK: - Motion

/// A named animation curve.
///
/// The kit uses five. Consistency of *motion* is what makes a set of components
/// feel like one product — the moment one button eases and another springs, the
/// illusion breaks. Reach for a preset; do not hand-roll `.easeInOut` in a
/// component.
public struct SKMotion: Equatable, Sendable {
    public let standard: Animation
    /// Substituted when the user has Reduce Motion on. `nil` means "no
    /// animation at all", which is the right answer for anything that moves
    /// across the screen.
    public let reduced: Animation?

    public init(_ standard: Animation, reduced: Animation? = nil) {
        self.standard = standard
        self.reduced = reduced
    }

    /// Press states and other sub-100ms feedback. Never bounces — overshoot on
    /// a press feels like lag.
    public static let micro = SKMotion(
        .spring(duration: 0.18, bounce: 0),
        reduced: .easeOut(duration: 0.1)
    )

    /// The workhorse. Toggles, selection, tab changes. A 0.12 bounce reads as
    /// "brisk" rather than "bouncy".
    public static let snap = SKMotion(
        .spring(duration: 0.32, bounce: 0.12),
        reduced: .easeOut(duration: 0.15)
    )

    /// Cards, sheets, anything with mass. Slightly more overshoot so it feels
    /// like it settles rather than stops.
    public static let settle = SKMotion(
        .spring(duration: 0.48, bounce: 0.18),
        reduced: .easeOut(duration: 0.2)
    )

    /// Large or ambient movement. No bounce — at this distance overshoot looks
    /// like a mistake.
    public static let glide = SKMotion(
        .spring(duration: 0.65, bounce: 0),
        reduced: .easeOut(duration: 0.2)
    )

    /// Delight only: success ticks, celebrations, attention pulls. Use sparingly.
    public static let pop = SKMotion(
        .spring(duration: 0.4, bounce: 0.42),
        reduced: nil
    )

    /// Resolves to the curve that should actually run.
    public func resolved(reduceMotion: Bool) -> Animation? {
        reduceMotion ? reduced : standard
    }
}

private struct SKAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let motion: SKMotion
    let value: V

    func body(content: Content) -> some View {
        content.animation(motion.resolved(reduceMotion: reduceMotion), value: value)
    }
}

extension View {
    /// Animates on `value` using a kit motion preset, honouring Reduce Motion.
    ///
    /// Prefer this over `.animation(_:value:)` everywhere in the kit — it is the
    /// single place accessibility is handled, so no component can forget.
    public func skAnimation<V: Equatable>(_ motion: SKMotion, value: V) -> some View {
        modifier(SKAnimationModifier(motion: motion, value: value))
    }
}

// MARK: - Haptics

extension SK {
    /// Thin wrapper so components can add feedback without importing UIKit or
    /// breaking on platforms that have no haptics.
    ///
    /// `@MainActor` because UIFeedbackGenerator is main-actor isolated under
    /// Swift 6. Every call site is SwiftUI view code, which is already on the
    /// main actor, so this costs callers nothing — and it keeps the kit building
    /// warning-free in strict-concurrency projects.
    @MainActor
    public enum Haptic {
        public enum Style { case light, medium, heavy, soft, rigid, success, warning, error, selection }

        public static func play(_ style: Style) {
            #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
            switch style {
            case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .error:   UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .selection: UISelectionFeedbackGenerator().selectionChanged()
            case .light:  UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .heavy:  UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .soft:   UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            case .rigid:  UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            #endif
        }
    }
}

// MARK: - Surfaces

extension SK {
    /// How a raised surface is drawn. `.liquidGlass` uses Apple's native iOS 26
    /// effect where available and falls back to a hand-built approximation, so
    /// it is safe to leave on with a deployment target of 17.
    public enum Surface: Sendable {
        case flat
        case bordered
        case elevated
        /// Translucent bar with a top hairline. For pinned footers and toolbars
        /// that sit over scrolling content.
        case bar
        case liquidGlass
    }
}

private struct SKSurfaceModifier: ViewModifier {
    let style: SK.Surface
    let radius: CGFloat

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    func body(content: Content) -> some View {
        switch style {
        case .flat:
            content.background(SK.Palette.surface, in: shape)

        case .bordered:
            content
                .background(SK.Palette.surface, in: shape)
                .overlay(shape.strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin))

        case .elevated:
            content
                .background(SK.Palette.surfaceElevated, in: shape)
                .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)

        case .bar:
            content
                .background(.ultraThinMaterial, in: Rectangle())
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(SK.Palette.separator)
                        .frame(height: SK.Stroke.hairline)
                }

        case .liquidGlass:
            if #available(iOS 26, macOS 26, *) {
                content.glassEffect(.regular, in: shape)
            } else {
                content
                    .background(.ultraThinMaterial, in: shape)
                    .overlay(
                        shape.strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: SK.Stroke.thin
                        )
                    )
                    .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
            }
        }
    }
}

extension View {
    /// Applies a kit surface treatment.
    public func skSurface(_ style: SK.Surface, radius: CGFloat = SK.Radius.lg) -> some View {
        modifier(SKSurfaceModifier(style: style, radius: radius))
    }
}

// MARK: - Colour helpers

#if canImport(UIKit)
extension UIColor {
    fileprivate convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
#elseif canImport(AppKit)
extension NSColor {
    fileprivate convenience init(rgb: UInt32) {
        self.init(
            srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
#else
extension Color {
    fileprivate init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
#endif


// MARK: - Shared press interaction

/// Scale-on-press with an optional haptic, for anything tappable that is not a
/// `SKButton` — cards, rows, chips, tiles.
///
/// Wrap the content in a `Button` and apply this. Using a real `Button` rather
/// than `.onTapGesture` is deliberate: it gets VoiceOver, keyboard focus,
/// pointer hover and the correct accessibility traits for free.
public struct SKPressStyle: ButtonStyle {
    private let scale: CGFloat
    private let haptic: SK.Haptic.Style?

    public init(scale: CGFloat = 0.98, haptic: SK.Haptic.Style? = .light) {
        self.scale = scale
        self.haptic = haptic
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .skAnimation(.micro, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed, let haptic { SK.Haptic.play(haptic) }
            }
    }
}

extension ButtonStyle where Self == SKPressStyle {
    /// `Button { } label: { }.buttonStyle(.skPress)`
    public static var skPress: SKPressStyle { SKPressStyle() }

    public static func skPress(scale: CGFloat = 0.98, haptic: SK.Haptic.Style? = .light) -> SKPressStyle {
        SKPressStyle(scale: scale, haptic: haptic)
    }
}

// MARK: - Shimmer

/// A travelling highlight, for skeleton placeholders.
///
/// Lives in the foundation rather than in the skeleton component because
/// several components want it (skeleton rows, loading cards, placeholder
/// avatars) and duplicating the animation would let them drift out of sync.
public struct SKShimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1
    public var active: Bool = true

    public func body(content: Content) -> some View {
        if active && !reduceMotion {
            content
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.75), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: phase * geo.size.width * 1.6)
                    }
                }
                .mask(content)
                .onAppear {
                    withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    /// Applies a shimmering highlight. No-ops under Reduce Motion.
    public func skShimmer(_ active: Bool = true) -> some View {
        modifier(SKShimmer(active: active))
    }
}


// MARK: - Cross-platform text input

extension SK {
    /// Autocapitalisation, expressed once so components do not each carry
    /// `#if os(iOS)`. `TextInputAutocapitalization` does not exist on macOS,
    /// and a component riddled with platform conditionals is a component an
    /// agent copies wrong.
    public enum Capitalization: Sendable {
        case never, words, sentences, characters
    }

    /// Keyboard types the kit actually uses.
    public enum Keyboard: Sendable {
        case `default`, email, number, phone, url
    }
}

extension View {
    @ViewBuilder
    public func skCapitalization(_ mode: SK.Capitalization?) -> some View {
        #if os(iOS) || os(tvOS)
        switch mode {
        case .never: self.textInputAutocapitalization(.never)
        case .words: self.textInputAutocapitalization(.words)
        case .sentences: self.textInputAutocapitalization(.sentences)
        case .characters: self.textInputAutocapitalization(.characters)
        case nil: self
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    public func skKeyboard(_ type: SK.Keyboard) -> some View {
        #if os(iOS)
        switch type {
        case .default: self.keyboardType(.default)
        case .email: self.keyboardType(.emailAddress)
        case .number: self.keyboardType(.numberPad)
        case .phone: self.keyboardType(.phonePad)
        case .url: self.keyboardType(.URL)
        }
        #else
        self
        #endif
    }

    /// One-time-code content type, for SMS autofill. No-op off iOS.
    @ViewBuilder
    public func skOneTimeCode() -> some View {
        #if os(iOS)
        self.textContentType(.oneTimeCode)
        #else
        self
        #endif
    }
}
