//
//  SKToast.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A transient message, presented as a modifier so it overlays the whole screen
//  instead of being wedged into your layout.
//
//  Swipe up to dismiss early. The auto-dismiss timer is a Task tied to the
//  toast's identity, so replacing a toast cancels the previous timer — without
//  that, a rapid second toast inherits the first one's countdown and vanishes
//  almost immediately.
//
//  Usage:
//      .skToast($toast)
//      toast = SKToast("Saved", style: .success)
//

import SwiftUI

public struct SKToast: Equatable, Identifiable, Sendable {
    public enum Style: Sendable {
        case info, success, warning, error

        var tint: Color {
            switch self {
            case .info: SK.Palette.accent
            case .success: SK.Palette.success
            case .warning: SK.Palette.warning
            case .error: SK.Palette.danger
            }
        }

        var symbol: String {
            switch self {
            case .info: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .error: "xmark.octagon.fill"
            }
        }

        var haptic: SK.Haptic.Style {
            switch self {
            case .info: .light
            case .success: .success
            case .warning: .warning
            case .error: .error
            }
        }
    }

    public let id = UUID()
    public let message: String
    public let style: Style
    public let duration: Double

    public init(_ message: String, style: Style = .info, duration: Double = 2.4) {
        self.message = message
        self.style = style
        self.duration = duration
    }

    public static func == (a: SKToast, b: SKToast) -> Bool { a.id == b.id }
}

public enum SKToastEdge: Sendable { case top, bottom }

private struct SKToastModifier: ViewModifier {
    @Binding var toast: SKToast?
    let edge: SKToastEdge

    func body(content: Content) -> some View {
        content
            .overlay(alignment: edge == .top ? .top : .bottom) {
                if let toast {
                    banner(toast)
                        .padding(.horizontal, SK.Space.lg)
                        .padding(edge == .top ? .top : .bottom, SK.Space.sm)
                        .transition(.move(edge: edge == .top ? .top : .bottom)
                            .combined(with: .opacity))
                }
            }
            .skAnimation(.settle, value: toast)
            // Keyed on the toast id: a new toast starts a fresh timer and the
            // old one is cancelled automatically.
            .task(id: toast?.id) {
                guard let current = toast else { return }
                SK.Haptic.play(current.style.haptic)
                try? await Task.sleep(for: .seconds(current.duration))
                guard !Task.isCancelled else { return }
                toast = nil
            }
    }

    private func banner(_ toast: SKToast) -> some View {
        HStack(spacing: SK.Space.md) {
            Image(systemName: toast.style.symbol)
                .font(SK.Icon.symbol(SK.Icon.md))
                .foregroundStyle(toast.style.tint)
            Text(toast.message)
                .font(SK.Type_.callout)
                .foregroundStyle(SK.Palette.label)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, SK.Space.lg)
        .padding(.vertical, SK.Space.md)
        .skSurface(.elevated, radius: SK.Radius.lg)
        .gesture(
            DragGesture(minimumDistance: 8).onEnded { g in
                let dismissed = edge == .top ? g.translation.height < -20 : g.translation.height > 20
                if dismissed { self.toast = nil }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

extension View {
    /// Presents `toast` over this view, auto-dismissing after its duration.
    public func skToast(_ toast: Binding<SKToast?>, edge: SKToastEdge = .top) -> some View {
        modifier(SKToastModifier(toast: toast, edge: edge))
    }
}

#Preview("SKToast") {
    @Previewable @State var toast: SKToast?

    VStack(spacing: SK.Space.md) {
        Button("Info") { toast = SKToast("Synced 42 items") }
        Button("Success") { toast = SKToast("Saved", style: .success) }
        Button("Warning") { toast = SKToast("Running low on space", style: .warning) }
        Button("Error") { toast = SKToast("Could not connect", style: .error) }
    }
    .buttonStyle(.skPress)
    .font(SK.Type_.callout)
    .foregroundStyle(SK.Palette.accent)
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
    .skToast($toast)
}
