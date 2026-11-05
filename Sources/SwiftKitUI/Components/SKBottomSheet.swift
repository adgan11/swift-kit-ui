//
//  SKBottomSheet.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A draggable bottom sheet you can actually style — grabber, corner radius,
//  backdrop and detents all yours.
//
//  TWO THINGS THAT ARE EASY TO GET WRONG, BOTH HANDLED HERE
//  --------------------------------------------------------
//  1. The sheet must RISE, not fade. A `.transition(.move(edge: .bottom))` only
//     works if it is on a DIRECT child of the container carrying the animation.
//     Wrap the sheet in a `GeometryReader` inside the `if`, and SwiftUI has no
//     transition on the thing being inserted, so it cross-fades the whole
//     container instead. Height comes from `containerRelativeFrame` precisely so
//     no GeometryReader is needed.
//  2. The drag must not be animated. An `.animation(_:value:)` anywhere above
//     the offset re-times every frame of the gesture, which reads as snapping
//     and lag. The animation here is scoped to `isPresented` alone; the drag
//     offset is raw, and only the release is animated.
//
//  Usage:
//      .skBottomSheet(isPresented: $show) { SheetContent() }
//      .skBottomSheet(isPresented: $show, detent: .large) { ... }
//

import SwiftUI

public enum SKSheetDetent: Sendable {
    case small, medium, large

    var fraction: CGFloat {
        switch self {
        case .small: 0.32
        case .medium: 0.55
        case .large: 0.88
        }
    }
}

private struct SKBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detent: SKSheetDetent
    let showsGrabber: Bool
    let sheetContent: SheetContent

    @State private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motion: Animation? {
        SKMotion.settle.resolved(reduceMotion: reduceMotion)
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if isPresented {
                Color.black
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { close() }
                    .zIndex(1)

                // A direct child of the animated ZStack, so the move transition
                // is the thing SwiftUI actually animates.
                sheet
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
        }
        // Scoped to isPresented ONLY. Widen this and the drag starts snapping.
        .animation(motion, value: isPresented)
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            if showsGrabber {
                Capsule()
                    .fill(SK.Palette.labelTertiary.opacity(0.6))
                    .frame(width: 36, height: 5)
                    .padding(.top, SK.Space.sm)
                    .padding(.bottom, SK.Space.xs)
                    .accessibilityHidden(true)
            }

            sheetContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .containerRelativeFrame(.vertical) { height, _ in height * detent.fraction }
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: SK.Radius.xxl,
                topTrailingRadius: SK.Radius.xxl,
                style: .continuous
            )
            .fill(SK.Palette.surfaceElevated)
            .ignoresSafeArea(edges: .bottom)
            .shadow(color: .black.opacity(0.22), radius: 22, y: -6)
        }
        .offset(y: drag)
        // Raw, unanimated during the gesture so the sheet tracks the finger.
        .gesture(dragGesture)
        .accessibilityAddTraits(.isModal)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { g in
                // 1:1 downward; heavily damped upward so the top feels like a
                // limit rather than a wall.
                drag = g.translation.height > 0
                    ? g.translation.height
                    : g.translation.height / 6
            }
            .onEnded { g in
                // Projected, so a short fast flick dismisses like a long drag.
                if g.predictedEndTranslation.height > 150 {
                    close()
                } else {
                    withAnimation(motion) { drag = 0 }
                }
            }
    }

    private func close() {
        SK.Haptic.play(.light)
        withAnimation(motion) {
            isPresented = false
        }
        // Reset AFTER the dismissal so the sheet does not jump back to its
        // resting offset on the way out.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            drag = 0
        }
    }
}

extension View {
    public func skBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detent: SKSheetDetent = .medium,
        showsGrabber: Bool = true,
        @ViewBuilder content: () -> SheetContent
    ) -> some View {
        modifier(SKBottomSheetModifier(
            isPresented: isPresented, detent: detent,
            showsGrabber: showsGrabber, sheetContent: content()
        ))
    }
}

#Preview("SKBottomSheet") {
    @Previewable @State var medium = false
    @Previewable @State var large = false

    VStack(spacing: SK.Space.md) {
        Button("Medium sheet") { medium = true }
        Button("Large sheet") { large = true }
    }
    .font(SK.Type_.callout)
    .foregroundStyle(SK.Palette.accent)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
    .skBottomSheet(isPresented: $medium) {
        VStack(alignment: .leading, spacing: SK.Space.md) {
            Text("Share").font(SK.Type_.title).foregroundStyle(SK.Palette.label)
            Text("Drag the grabber down, or flick, to dismiss.")
                .font(SK.Type_.callout).foregroundStyle(SK.Palette.labelSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SK.Space.xl)
    }
    .skBottomSheet(isPresented: $large, detent: .large) {
        ScrollView {
            VStack(alignment: .leading, spacing: SK.Space.md) {
                ForEach(0..<14, id: \.self) { i in
                    Text("Row \(i + 1)").font(SK.Type_.body).foregroundStyle(SK.Palette.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SK.Space.xl)
        }
    }
}
