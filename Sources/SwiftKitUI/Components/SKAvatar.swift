//
//  SKAvatar.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Avatar with an initials fallback, an optional presence dot, and a stacked
//  group variant.
//
//  Initials are coloured deterministically from the name, so the same person is
//  always the same colour across the app — random colours per render is the
//  usual bug and it makes people look like different users.
//
//  Usage:
//      SKAvatar(name: "Ahmed Gagan")
//      SKAvatar(name: "Ada Lovelace", image: img, presence: .online)
//      SKAvatarGroup(names: ["Ada", "Alan", "Grace", "Katherine"])
//

import SwiftUI

public struct SKAvatar: View {
    public enum Presence: Sendable {
        case online, away, offline, none

        var color: Color? {
            switch self {
            case .online: SK.Palette.success
            case .away: SK.Palette.warning
            case .offline: SK.Palette.labelTertiary
            case .none: nil
            }
        }
    }

    private let name: String
    private let image: Image?
    private let size: CGFloat
    private let presence: Presence

    public init(name: String, image: Image? = nil, size: CGFloat = 44, presence: Presence = .none) {
        self.name = name
        self.image = image
        self.size = size
        self.presence = presence
    }

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init)
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }

    /// Stable hue from the name. Same person, same colour, every time.
    private var tint: Color {
        let hash = name.unicodeScalars.reduce(UInt32(7)) { ($0 &* 31) &+ $1.value }
        return Color(hue: Double(hash % 360) / 360, saturation: 0.55, brightness: 0.72)
    }

    public var body: some View {
        ZStack {
            if let image {
                image.resizable().scaledToFill()
            } else {
                tint
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(.white.opacity(0.25), lineWidth: SK.Stroke.hairline) }
        .overlay(alignment: .bottomTrailing) { presenceDot }
        .accessibilityLabel(name)
    }

    @ViewBuilder
    private var presenceDot: some View {
        if let color = presence.color {
            Circle()
                .fill(color)
                .frame(width: size * 0.28, height: size * 0.28)
                // Ring in the surface colour so the dot reads as cut out of the
                // avatar rather than floating on top of it.
                .overlay { Circle().strokeBorder(SK.Palette.surface, lineWidth: size * 0.06) }
                .offset(x: size * 0.02, y: size * 0.02)
        }
    }
}

/// Overlapping avatars with a +N overflow badge.
public struct SKAvatarGroup: View {
    private let names: [String]
    private let size: CGFloat
    private let maxVisible: Int

    public init(names: [String], size: CGFloat = 36, maxVisible: Int = 3) {
        self.names = names
        self.size = size
        self.maxVisible = maxVisible
    }

    public var body: some View {
        HStack(spacing: -size * 0.32) {
            ForEach(Array(names.prefix(maxVisible).enumerated()), id: \.offset) { _, name in
                SKAvatar(name: name, size: size)
                    .overlay { Circle().strokeBorder(SK.Palette.surface, lineWidth: 2) }
            }
            if names.count > maxVisible {
                Text("+\(names.count - maxVisible)")
                    .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                    .foregroundStyle(SK.Palette.labelSecondary)
                    .frame(width: size, height: size)
                    .background(Circle().fill(SK.Palette.fill))
                    .overlay { Circle().strokeBorder(SK.Palette.surface, lineWidth: 2) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(names.count) people")
    }
}

#Preview("SKAvatar") {
    VStack(spacing: SK.Space.xl) {
        HStack(spacing: SK.Space.lg) {
            SKAvatar(name: "Ahmed Gagan", presence: .online)
            SKAvatar(name: "Ada Lovelace", presence: .away)
            SKAvatar(name: "Grace Hopper", presence: .offline)
            SKAvatar(name: "Katherine Johnson")
        }
        HStack(spacing: SK.Space.lg) {
            SKAvatar(name: "Alan Turing", size: 28)
            SKAvatar(name: "Alan Turing", size: 44)
            SKAvatar(name: "Alan Turing", size: 64, presence: .online)
        }
        SKAvatarGroup(names: ["Ada", "Alan", "Grace", "Katherine", "Margaret"])
    }
    .padding(SK.Space.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SK.Palette.surfaceSunken)
}
