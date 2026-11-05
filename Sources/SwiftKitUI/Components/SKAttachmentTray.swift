//
//  SKAttachmentTray.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  Files staged for sending, with their uploads visible.
//
//  The detail that matters is the progress ring on the thumbnail itself rather
//  than a separate bar somewhere else. Three files uploading at different
//  speeds is the normal case, and one shared bar cannot describe it — you end
//  up with an aggregate percentage that is true of nothing the user can see.
//
//  Removal animates the remaining tiles closed. That sounds cosmetic and is
//  not: without it, tapping the X on the second of four attachments makes the
//  other three teleport, and the user cannot tell which one they actually
//  removed.
//
//  Usage:
//      SKAttachmentTray(attachments: $files, onRemove: { files.removeAll { $0.id == $1.id } })
//

import SwiftUI

public struct SKAttachment: Identifiable, Sendable {
    public enum Kind: Sendable {
        case image
        case file(ext: String)
        case audio
    }

    public let id: String
    public let name: String
    public let kind: Kind
    /// `nil` once the upload has finished. 0...1 while it is in flight.
    public let progress: Double?

    public init(
        id: String = UUID().uuidString,
        name: String,
        kind: Kind,
        progress: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.progress = progress
    }

    var symbol: String {
        switch kind {
        case .image: "photo"
        case .audio: "waveform"
        case .file: "doc.text"
        }
    }

    var badge: String? {
        if case let .file(ext) = kind { return ext.uppercased() }
        return nil
    }
}

public struct SKAttachmentTray: View {
    private let attachments: [SKAttachment]
    private let onRemove: ((SKAttachment) -> Void)?
    private let onAdd: (() -> Void)?

    private let tile: CGFloat = 62

    public init(
        attachments: [SKAttachment],
        onRemove: ((SKAttachment) -> Void)? = nil,
        onAdd: (() -> Void)? = nil
    ) {
        self.attachments = attachments
        self.onRemove = onRemove
        self.onAdd = onAdd
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SK.Space.sm) {
                if let onAdd {
                    addTile(onAdd)
                }
                ForEach(attachments) { attachment in
                    tileView(attachment)
                        // Scale + opacity on both edges, so a tile leaves the
                        // way it arrived instead of being cut out.
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .padding(.horizontal, SK.Space.lg)
            .padding(.vertical, SK.Space.sm)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .skAnimation(.settle, value: attachments.map(\.id))
    }

    private func addTile(_ action: @escaping () -> Void) -> some View {
        Button {
            action()
            SK.Haptic.play(.light)
        } label: {
            RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                .strokeBorder(SK.Palette.separator, style: StrokeStyle(lineWidth: SK.Stroke.thin, dash: [4, 4]))
                .frame(width: tile, height: tile)
                .overlay {
                    Image(systemName: "plus")
                        .font(SK.Icon.symbol(SK.Icon.lg, weight: .medium))
                        .foregroundStyle(SK.Palette.labelTertiary)
                }
        }
        .buttonStyle(.skPress(scale: 0.94, haptic: nil))
        .accessibilityLabel("Add attachment")
    }

    private func tileView(_ attachment: SKAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                .fill(SK.Palette.fill)
                .frame(width: tile, height: tile)
                .overlay {
                    VStack(spacing: SK.Space.xs) {
                        Image(systemName: attachment.symbol)
                            .font(SK.Icon.symbol(SK.Icon.lg, weight: .regular))
                            .foregroundStyle(SK.Palette.labelSecondary)
                        if let badge = attachment.badge {
                            Text(badge)
                                .font(SK.Type_.monoCaption)
                                .foregroundStyle(SK.Palette.labelTertiary)
                        }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
                        .strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
                }
                .overlay {
                    if let progress = attachment.progress {
                        uploadOverlay(progress)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous))

            if onRemove != nil, attachment.progress == nil {
                removeButton(attachment)
            }
        }
        // Padding on the ZStack, not the tile, so the remove button can sit
        // proud of the corner without being clipped by the scroll view.
        .padding(.top, 6)
        .padding(.trailing, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(attachment.name)
        .accessibilityValue(attachment.progress.map { "Uploading, \(Int($0 * 100)) percent" } ?? "Ready")
    }

    private func uploadOverlay(_ progress: Double) -> some View {
        ZStack {
            // A scrim, because a ring drawn straight onto the thumbnail is
            // unreadable over a light image.
            Color.black.opacity(0.45)

            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 3)
                .frame(width: 26, height: 26)

            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(-90))
                .skAnimation(.glide, value: progress)
        }
    }

    private func removeButton(_ attachment: SKAttachment) -> some View {
        Button {
            onRemove?(attachment)
            SK.Haptic.play(.light)
        } label: {
            Image(systemName: "xmark")
                .font(SK.Icon.symbol(SK.Icon.xs, weight: .bold))
                .foregroundStyle(SK.Palette.surface)
                .frame(width: 19, height: 19)
                .background(SK.Palette.label, in: Circle())
                .overlay { Circle().strokeBorder(SK.Palette.surface, lineWidth: 1.5) }
        }
        .buttonStyle(.skPress(scale: 0.85, haptic: nil))
        .offset(x: 6, y: -6)
        .accessibilityLabel("Remove \(attachment.name)")
    }
}

#Preview("SKAttachmentTray") {
    @Previewable @State var files: [SKAttachment] = [
        SKAttachment(name: "q3-revenue.png", kind: .image),
        SKAttachment(name: "contract.pdf", kind: .file(ext: "pdf")),
        SKAttachment(name: "standup.m4a", kind: .audio, progress: 0.15),
        SKAttachment(name: "schema.json", kind: .file(ext: "json")),
    ]

    VStack(alignment: .leading, spacing: SK.Space.lg) {
        SKAttachmentTray(
            attachments: files,
            onRemove: { target in files.removeAll { $0.id == target.id } },
            onAdd: {
                files.append(SKAttachment(name: "new.png", kind: .image, progress: 0.05))
            }
        )

        Text("Tap × to remove. The upload ring fills on the third tile.")
            .font(SK.Type_.caption)
            .foregroundStyle(SK.Palette.labelTertiary)
            .padding(.horizontal, SK.Space.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(.top, SK.Space.xl)
    .background(SK.Palette.surface)
    .task {
        // Drive any in-flight uploads to completion so the ring is visibly live.
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(260))
            files = files.map { file in
                guard let progress = file.progress else { return file }
                let next = progress + 0.12
                return SKAttachment(
                    id: file.id, name: file.name, kind: file.kind,
                    progress: next >= 1 ? nil : next
                )
            }
        }
    }
}
