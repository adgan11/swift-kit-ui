//
//  SKGlassPanel.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  iOS 26 Liquid Glass, with a fallback that is actually worth shipping below
//  iOS 26 rather than a flat rectangle.
//
//  The pre-26 path is a material plus a specular rim: a gradient border that is
//  bright on the top-left and fades to nothing bottom-right, which is what
//  reads as "light catching an edge". Without the rim, `.ultraThinMaterial`
//  alone just looks like grey.
//
//  Usage:
//      SKGlassPanel { Text("Now playing") }
//      SKGlassPanel(tint: .purple, intensity: .strong) { ... }
//

import SwiftUI

public struct SKGlassPanel<Content: View>: View {
    public enum Intensity: Sendable {
        case subtle, regular, strong

        var rimOpacity: Double {
            switch self {
            case .subtle: 0.25
            case .regular: 0.45
            case .strong: 0.7
            }
        }

        var tintOpacity: Double {
            switch self {
            case .subtle: 0.06
            case .regular: 0.12
            case .strong: 0.2
            }
        }
    }

    private let tint: Color?
    private let intensity: Intensity
    private let radius: CGFloat
    private let padding: CGFloat
    private let content: Content

    public init(
        tint: Color? = nil,
        intensity: Intensity = .regular,
        radius: CGFloat = SK.Radius.xl,
        padding: CGFloat = SK.Space.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.intensity = intensity
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    public var body: some View {
        content
            .padding(padding)
            .background { glass }
            .clipShape(shape)
            .overlay { rim }
            .shadow(color: .black.opacity(0.16), radius: 20, y: 10)
    }

    @ViewBuilder
    private var glass: some View {
        if #available(iOS 26, macOS 26, *) {
            Color.clear
                .glassEffect(.regular, in: shape)
                .overlay { if let tint { shape.fill(tint.opacity(intensity.tintOpacity)) } }
        } else {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                if let tint { Rectangle().fill(tint.opacity(intensity.tintOpacity)) }
            }
        }
    }

    /// The specular edge. Bright top-leading, gone by bottom-trailing.
    private var rim: some View {
        shape.strokeBorder(
            LinearGradient(
                colors: [
                    .white.opacity(intensity.rimOpacity),
                    .white.opacity(intensity.rimOpacity * 0.25),
                    .clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: SK.Stroke.thin
        )
    }
}

#Preview("SKGlassPanel") {
    ZStack {
        // Glass needs something behind it or there is nothing to refract.
        LinearGradient(
            colors: [.purple, .blue, .teal],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: SK.Space.lg) {
            SKGlassPanel(intensity: .subtle) {
                Text("Subtle").font(SK.Type_.headline).foregroundStyle(.white)
            }
            SKGlassPanel {
                VStack(alignment: .leading, spacing: SK.Space.xs) {
                    Text("Now Playing").font(SK.Type_.caption).foregroundStyle(.white.opacity(0.75))
                    Text("Liquid Glass").font(SK.Type_.title).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            SKGlassPanel(tint: .purple, intensity: .strong) {
                Text("Strong, tinted").font(SK.Type_.headline).foregroundStyle(.white)
            }
        }
        .padding(SK.Space.xl)
    }
}
