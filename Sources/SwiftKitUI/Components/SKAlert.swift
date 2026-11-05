//
//  SKAlert.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A styled alert that can carry a text field — the thing the system alert
//  technically supports but gives you no control over.
//
//  Presented as an overlay rather than a `.sheet`, so it can be branded and so
//  the backdrop dims the actual app instead of the system's flat scrim.
//
//  Usage:
//      .skAlert(isPresented: $show, title: "Delete?",
//               message: "This cannot be undone.",
//               confirm: .init(title: "Delete", role: .destructive) { delete() })
//
//      .skAlert(isPresented: $rename, title: "Rename",
//               text: $name, placeholder: "New name",
//               confirm: .init(title: "Save") { save(name) })
//

import SwiftUI

public struct SKAlertAction {
    public enum Role: Sendable { case normal, destructive }

    public let title: String
    public let role: Role
    public let handler: () -> Void

    public init(title: String, role: Role = .normal, handler: @escaping () -> Void = {}) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}

private struct SKAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let systemImage: String?
    var text: Binding<String>?
    let placeholder: String
    let confirm: SKAlertAction
    let cancelTitle: String?

    @FocusState private var fieldFocused: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.38)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { dismiss() }

                    card
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
                .skAnimation(.settle, value: isPresented)
                .zIndex(10)
            }
        }
        .skAnimation(.settle, value: isPresented)
    }

    private var card: some View {
        VStack(spacing: SK.Space.lg) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(SK.Icon.symbol(SK.Icon.xl))
                    .foregroundStyle(confirm.role == .destructive ? SK.Palette.danger : SK.Palette.accent)
            }

            VStack(spacing: SK.Space.xs) {
                Text(title)
                    .font(SK.Type_.headline)
                    .foregroundStyle(SK.Palette.label)
                if let message {
                    Text(message)
                        .font(SK.Type_.callout)
                        .foregroundStyle(SK.Palette.labelSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let text {
                TextField(placeholder, text: text)
                    .font(SK.Type_.body)
                    .padding(.horizontal, SK.Space.md)
                    .frame(height: SK.Icon.hitTarget)
                    .background(SK.Palette.fill, in: RoundedRectangle(cornerRadius: SK.Radius.sm, style: .continuous))
                    .focused($fieldFocused)
                    .submitLabel(.done)
                    .onSubmit(run)
            }

            HStack(spacing: SK.Space.sm) {
                if let cancelTitle {
                    Button(cancelTitle) { dismiss() }
                        .buttonStyle(SKButtonStyleShim.secondary)
                }
                Button(confirm.title, action: run)
                    .buttonStyle(confirm.role == .destructive
                                 ? SKButtonStyleShim.destructive
                                 : SKButtonStyleShim.primary)
            }
        }
        .padding(SK.Space.xl)
        .frame(maxWidth: 320)
        .skSurface(.elevated, radius: SK.Radius.xl)
        .padding(SK.Space.xl)
        // Focus the field after the entry animation, not during it — focusing
        // mid-transition makes the keyboard race the alert on screen.
        .task {
            guard text != nil else { return }
            try? await Task.sleep(for: .milliseconds(320))
            fieldFocused = true
        }
    }

    private func run() {
        confirm.handler()
        dismiss()
    }

    private func dismiss() {
        fieldFocused = false
        isPresented = false
    }
}

/// Minimal local button styling.
///
/// SKAlert deliberately does NOT reuse SKButton: a component may depend only on
/// the foundation, never on a sibling, or it stops being installable on its own.
private struct SKButtonStyleShim: ButtonStyle {
    enum Kind { case primary, secondary, destructive }
    let kind: Kind

    static let primary = SKButtonStyleShim(kind: .primary)
    static let secondary = SKButtonStyleShim(kind: .secondary)
    static let destructive = SKButtonStyleShim(kind: .destructive)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SK.Type_.headline)
            .foregroundStyle(kind == .secondary ? SK.Palette.label : Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SK.Space.md)
            .background {
                let shape = RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                switch kind {
                case .primary: shape.fill(SK.Palette.accent)
                case .destructive: shape.fill(SK.Palette.danger)
                case .secondary: shape.fill(SK.Palette.fill)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .skAnimation(.micro, value: configuration.isPressed)
    }
}

extension View {
    /// Confirmation alert.
    public func skAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        systemImage: String? = nil,
        confirm: SKAlertAction,
        cancelTitle: String? = "Cancel"
    ) -> some View {
        modifier(SKAlertModifier(
            isPresented: isPresented, title: title, message: message,
            systemImage: systemImage, text: nil, placeholder: "",
            confirm: confirm, cancelTitle: cancelTitle
        ))
    }

    /// Alert with a text field.
    public func skAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        systemImage: String? = nil,
        text: Binding<String>,
        placeholder: String = "",
        confirm: SKAlertAction,
        cancelTitle: String? = "Cancel"
    ) -> some View {
        modifier(SKAlertModifier(
            isPresented: isPresented, title: title, message: message,
            systemImage: systemImage, text: text, placeholder: placeholder,
            confirm: confirm, cancelTitle: cancelTitle
        ))
    }
}

#Preview("SKAlert") {
    @Previewable @State var confirmShown = false
    @Previewable @State var renameShown = false
    @Previewable @State var name = "Untitled"

    VStack(spacing: SK.Space.md) {
        Button("Destructive confirm") { confirmShown = true }
        Button("With a text field") { renameShown = true }
        Text(name).font(SK.Type_.caption).foregroundStyle(SK.Palette.labelSecondary)
    }
    .font(SK.Type_.callout)
    .foregroundStyle(SK.Palette.accent)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
    .skAlert(
        isPresented: $confirmShown,
        title: "Delete project?",
        message: "This removes every file. It cannot be undone.",
        systemImage: "trash.fill",
        confirm: .init(title: "Delete", role: .destructive)
    )
    .skAlert(
        isPresented: $renameShown,
        title: "Rename",
        text: $name,
        placeholder: "Project name",
        confirm: .init(title: "Save")
    )
}
