//
//  SKButton.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Five button roles on one interruptible press animation. The press uses a
//  spring rather than a duration curve so a rapid double-tap does not queue up
//  two animations and lag behind the finger — the second press retargets the
//  first mid-flight.
//
//  Usage:
//      Button("Continue") { }.buttonStyle(.sk)
//      Button("Delete") { }.buttonStyle(.sk(.destructive))
//      Button("Buy") { }.buttonStyle(.sk(.primary, loading: isLoading))
//

import SwiftUI

public struct SKButtonStyle: ButtonStyle {
    public enum Role: Sendable {
        case primary
        case secondary
        case ghost
        case destructive
        case liquidGlass
    }

    private let role: Role
    private let fullWidth: Bool
    private let loading: Bool

    public init(_ role: Role = .primary, fullWidth: Bool = true, loading: Bool = false) {
        self.role = role
        self.fullWidth = fullWidth
        self.loading = loading
    }

    public func makeBody(configuration: Configuration) -> some View {
        SKButtonBody(
            configuration: configuration,
            role: role,
            fullWidth: fullWidth,
            loading: loading
        )
    }
}

private struct SKButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let role: SKButtonStyle.Role
    let fullWidth: Bool
    let loading: Bool

    @Environment(\.isEnabled) private var isEnabled

    private var isInteractive: Bool { isEnabled && !loading }

    var body: some View {
        ZStack {
            // The label stays in the layout while loading so the button does not
            // resize when it starts — a resizing button mid-tap feels broken.
            label
                .opacity(loading ? 0 : 1)

            if loading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(foreground)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(.vertical, SK.Space.md + 2)
        .padding(.horizontal, SK.Space.xl)
        .background { background }
        .clipShape(RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))
        .overlay { border }
        .compositingGroup()
        .scaleEffect(configuration.isPressed && isInteractive ? 0.97 : 1)
        .opacity(isEnabled ? 1 : 0.45)
        .skAnimation(.micro, value: configuration.isPressed)
        .skAnimation(.snap, value: loading)
        .contentShape(.rect)
        .onChange(of: configuration.isPressed) { _, pressed in
            // Fire on press-down, not on release. Feedback that arrives after
            // the finger lifts reads as lag.
            if pressed && isInteractive { SK.Haptic.play(.light) }
        }
        .accessibilityAddTraits(.isButton)
        // Announce the busy state as a VALUE, not a label — overriding the
        // label here would erase the button's own title for VoiceOver users.
        .accessibilityValue(loading ? "Loading" : "")
    }

    private var label: some View {
        configuration.label
            .font(SK.Type_.headline)
            .foregroundStyle(foreground)
    }

    @ViewBuilder
    private var background: some View {
        switch role {
        case .primary:
            SK.Palette.accent
        case .secondary:
            SK.Palette.fill
        case .ghost:
            Color.clear
        case .destructive:
            SK.Palette.danger
        case .liquidGlass:
            Color.clear.skSurface(.liquidGlass, radius: SK.Radius.md)
        }
    }

    @ViewBuilder
    private var border: some View {
        let shape = RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
        switch role {
        case .secondary:
            shape.strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
        case .ghost:
            shape.strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
        default:
            EmptyView()
        }
    }

    private var foreground: Color {
        switch role {
        case .primary, .destructive: .white
        case .secondary, .ghost, .liquidGlass: SK.Palette.label
        }
    }
}

extension ButtonStyle where Self == SKButtonStyle {
    /// `Button(...).buttonStyle(.sk)`
    public static var sk: SKButtonStyle { SKButtonStyle() }

    /// `Button(...).buttonStyle(.sk(.secondary))`
    public static func sk(
        _ role: SKButtonStyle.Role,
        fullWidth: Bool = true,
        loading: Bool = false
    ) -> SKButtonStyle {
        SKButtonStyle(role, fullWidth: fullWidth, loading: loading)
    }
}

#Preview("SKButton") {
    @Previewable @State var loading = false

    VStack(spacing: SK.Space.md) {
        Button("Primary") { }.buttonStyle(.sk)
        Button("Secondary") { }.buttonStyle(.sk(.secondary))
        Button("Ghost") { }.buttonStyle(.sk(.ghost))
        Button("Destructive") { }.buttonStyle(.sk(.destructive))
        Button("Liquid Glass") { }.buttonStyle(.sk(.liquidGlass))
        Button("Disabled") { }.buttonStyle(.sk).disabled(true)
        Button("Tap to load") { loading.toggle() }
            .buttonStyle(.sk(.primary, loading: loading))
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
