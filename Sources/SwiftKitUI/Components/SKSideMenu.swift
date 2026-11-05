//
//  SKSideMenu.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A drawer that slides in from the edge, with the main content pushed and
//  scaled behind it.
//
//  Scaling the content rather than only dimming it is what sells the depth —
//  it reads as the app stepping back rather than a panel landing on top.
//
//  Usage:
//      .skSideMenu(isOpen: $menuOpen) { MenuContent() }
//

import SwiftUI

private struct SKSideMenuModifier<Menu: View>: ViewModifier {
    @Binding var isOpen: Bool
    let width: CGFloat
    let edge: HorizontalEdge
    let menu: Menu

    @State private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sign: CGFloat { edge == .leading ? 1 : -1 }

    private var offset: CGFloat {
        let base = isOpen ? width * sign : 0
        return base + drag
    }

    /// 0 closed, 1 fully open — drives the backdrop and the content scale.
    private var progress: CGFloat {
        min(max(abs(offset) / width, 0), 1)
    }

    func body(content: Content) -> some View {
        ZStack(alignment: edge == .leading ? .leading : .trailing) {
            content
                .scaleEffect(1 - progress * 0.10, anchor: edge == .leading ? .trailing : .leading)
                .offset(x: offset)
                .overlay {
                    if progress > 0.01 {
                        Color.black.opacity(0.35 * progress)
                            .ignoresSafeArea()
                            .onTapGesture { close() }
                    }
                }
                .disabled(isOpen)

            drawer
        }
        .skAnimation(.settle, value: isOpen)
        .gesture(edgeDrag)
    }

    private var drawer: some View {
        menu
            .frame(width: width)
            .frame(maxHeight: .infinity)
            .background(SK.Palette.surfaceElevated)
            .ignoresSafeArea()
            .offset(x: (isOpen ? 0 : -width * sign) + drag)
            .shadow(color: .black.opacity(0.25), radius: 20)
            .accessibilityHidden(!isOpen)
    }

    private var edgeDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { g in
                let raw = g.translation.width
                // Only allow dragging in the direction that makes sense for the
                // current state, so the drawer cannot be dragged past open.
                if isOpen {
                    drag = edge == .leading ? min(raw, 0) : max(raw, 0)
                } else {
                    drag = edge == .leading ? max(raw, 0) : min(raw, 0)
                }
                drag = min(max(drag, -width), width)
            }
            .onEnded { g in
                let predicted = g.predictedEndTranslation.width * sign
                withAnimation(SKMotion.settle.resolved(reduceMotion: reduceMotion)) {
                    if isOpen && predicted < -width / 3 {
                        isOpen = false
                    } else if !isOpen && predicted > width / 3 {
                        isOpen = true
                        SK.Haptic.play(.light)
                    }
                    drag = 0
                }
            }
    }

    private func close() {
        SK.Haptic.play(.light)
        withAnimation(SKMotion.settle.resolved(reduceMotion: reduceMotion)) {
            isOpen = false
            drag = 0
        }
    }
}

extension View {
    public func skSideMenu<Menu: View>(
        isOpen: Binding<Bool>,
        width: CGFloat = 280,
        edge: HorizontalEdge = .leading,
        @ViewBuilder menu: () -> Menu
    ) -> some View {
        modifier(SKSideMenuModifier(isOpen: isOpen, width: width, edge: edge, menu: menu()))
    }
}

#Preview("SKSideMenu") {
    @Previewable @State var open = false

    VStack(spacing: SK.Space.lg) {
        Button("Open menu") { open = true }
            .font(SK.Type_.callout)
            .foregroundStyle(SK.Palette.accent)
        Text("Or drag in from the left edge")
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
    .skSideMenu(isOpen: $open) {
        VStack(alignment: .leading, spacing: SK.Space.lg) {
            Text("Menu").font(SK.Type_.title).foregroundStyle(SK.Palette.label)
            ForEach(["Home", "Library", "Downloads", "Settings"], id: \.self) { item in
                Text(item).font(SK.Type_.body).foregroundStyle(SK.Palette.labelSecondary)
            }
            Spacer()
        }
        .padding(SK.Space.xl)
        .padding(.top, SK.Space.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
