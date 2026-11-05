//
//  SKChatBubble.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A message bubble with a real tail.
//
//  Most hand-rolled bubbles draw the tail as a separate triangle sitting next
//  to a rounded rectangle. It reads as cheap immediately, and it breaks the
//  moment you put a border on it, because the border runs around two shapes
//  instead of one silhouette. Here the body and the tail are a single `Path`,
//  so a stroke follows the outline the way it does in Messages, and the tail
//  hooks back into the body on a curve rather than spiking out of it.
//
//  Consecutive messages from one sender are a *group*: pass `.first`,
//  `.middle` and `.last` and the corners tighten on the sender's side while
//  only the final bubble keeps its tail. Without that, five quick messages look
//  like five unrelated objects instead of one turn in a conversation.
//
//  Usage:
//      SKChatBubble("Can you summarise this thread?", role: .user)
//      SKChatBubble(reply, role: .assistant, position: .last, timestamp: date)
//

import SwiftUI

// MARK: - Model

public enum SKChatRole: Sendable, Hashable {
    case user, assistant
}

/// Where this bubble sits inside a run of messages from the same sender.
public enum SKChatPosition: Sendable, Hashable {
    /// A lone message: full corners, tail.
    case only
    /// Opens a group: full corners, no tail.
    case first
    /// Inside a group: tightened corners, no tail.
    case middle
    /// Closes a group: tightened top corner, tail.
    case last

    var hasTail: Bool { self == .only || self == .last }
    var tightTop: Bool { self == .middle || self == .last }
    var tightBottom: Bool { self == .first || self == .middle }
}

public enum SKChatStatus: Sendable, Hashable {
    case sent
    /// Optimistically shown while the request is in flight.
    case sending
    case failed
}

// MARK: - Shape

/// Bubble body + tail as one continuous path.
///
/// Public because a chat screen often wants the same silhouette for a
/// typing indicator or an attachment preview, and re-deriving the geometry in
/// two places is how two bubbles end up subtly different.
public struct SKBubbleShape: InsettableShape {
    public enum Tail: Sendable { case none, leading, trailing }

    public var radius: CGFloat
    public var tail: Tail
    public var tailSize: CGFloat
    public var tightTop: Bool
    public var tightBottom: Bool
    private var insetAmount: CGFloat = 0

    public init(
        radius: CGFloat = SK.Radius.xl,
        tail: Tail = .none,
        tailSize: CGFloat = 7,
        tightTop: Bool = false,
        tightBottom: Bool = false
    ) {
        self.radius = radius
        self.tail = tail
        self.tailSize = tailSize
        self.tightTop = tightTop
        self.tightBottom = tightBottom
    }

    /// `InsettableShape` so the bubble can `strokeBorder` — a centred
    /// `stroke` would put half the hairline outside the silhouette and make
    /// the border sit a hair proud of the fill along the tail.
    public func inset(by amount: CGFloat) -> SKBubbleShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    public func path(in bounds: CGRect) -> Path {
        let rect = bounds.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = max(0, self.radius - insetAmount)
        let tight = max(0, SK.Radius.sm - insetAmount)

        // The tail lives *outside* the body, so the body gives up that width.
        // Doing it this way means the caller's padding is the padding around
        // the text, not around the text plus a tail.
        let inset = tail == .none ? 0 : tailSize
        let body = CGRect(
            x: rect.minX + (tail == .leading ? inset : 0),
            y: rect.minY,
            width: max(0, rect.width - inset),
            height: rect.height
        )

        // A tightened corner is the one facing the neighbouring bubble in the
        // group — small, not square, so the run still reads as rounded.
        let onLeading = tail == .leading
        let senderTop = tightTop ? tight : radius
        let senderBottom = tightBottom ? tight : radius
        let topLeading = onLeading ? senderTop : radius
        let bottomLeading = onLeading ? senderBottom : radius
        let topTrailing = onLeading ? radius : senderTop
        let bottomTrailing = onLeading ? radius : senderBottom

        // ONE closed outline, walked clockwise, with the tail substituted for
        // the corner it replaces.
        //
        // The obvious construction — a rounded rect plus a separate tail
        // subpath — is wrong in two ways that only show up on screen. Filled
        // with the non-zero rule the tail subtracts rather than adds wherever
        // it overlaps, punching a hole through to the background; and stroked,
        // it traces the seam where the tail re-enters the body, drawing a
        // diagonal line across the inside of the bubble. A single outline has
        // neither problem, which is the whole reason this is a `Shape` rather
        // than two overlaid ones.
        var path = Path()
        path.move(to: CGPoint(x: body.minX + topLeading, y: body.minY))

        // Top edge, top-trailing corner.
        path.addLine(to: CGPoint(x: body.maxX - topTrailing, y: body.minY))
        corner(&path,
               through: CGPoint(x: body.maxX, y: body.minY),
               to: CGPoint(x: body.maxX, y: body.minY + topTrailing),
               radius: topTrailing)

        // Trailing edge down to the bottom-trailing corner, or the tail.
        if tail == .trailing {
            // Arrived travelling DOWN the trailing edge: edge -> tip -> bottom.
            let x = body.maxX, y = body.maxY
            path.addLine(to: CGPoint(x: x, y: y - radius * 0.92))
            path.addQuadCurve(
                to: CGPoint(x: x + tailSize, y: y),
                control: CGPoint(x: x, y: y - radius * 0.20)
            )
            path.addQuadCurve(
                to: CGPoint(x: x - radius * 0.88, y: y),
                control: CGPoint(x: x - radius * 0.12, y: y - radius * 0.40)
            )
        } else {
            path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - bottomTrailing))
            corner(&path,
                   through: CGPoint(x: body.maxX, y: body.maxY),
                   to: CGPoint(x: body.maxX - bottomTrailing, y: body.maxY),
                   radius: bottomTrailing)
        }

        // Bottom edge to the bottom-leading corner, or the tail.
        if tail == .leading {
            // Arrived travelling ALONG the bottom edge, so the same three
            // steps run in reverse: bottom -> tip -> edge. Mirroring the
            // coordinates without reversing the order is what sends the
            // outline diagonally across the bubble.
            let x = body.minX, y = body.maxY
            path.addLine(to: CGPoint(x: x + radius * 0.88, y: y))
            path.addQuadCurve(
                to: CGPoint(x: x - tailSize, y: y),
                control: CGPoint(x: x + radius * 0.12, y: y - radius * 0.40)
            )
            path.addQuadCurve(
                to: CGPoint(x: x, y: y - radius * 0.92),
                control: CGPoint(x: x, y: y - radius * 0.20)
            )
        } else {
            path.addLine(to: CGPoint(x: body.minX + bottomLeading, y: body.maxY))
            corner(&path,
                   through: CGPoint(x: body.minX, y: body.maxY),
                   to: CGPoint(x: body.minX, y: body.maxY - bottomLeading),
                   radius: bottomLeading)
        }

        // Leading edge, top-leading corner, close.
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + topLeading))
        corner(&path,
               through: CGPoint(x: body.minX, y: body.minY),
               to: CGPoint(x: body.minX + topLeading, y: body.minY),
               radius: topLeading)
        path.closeSubpath()
        return path
    }

    /// Rounds the corner at `through`, arriving at `to`.
    ///
    /// A zero radius is a real case — a fully tightened corner in the middle of
    /// a group — and `addArc` with radius 0 is undefined, so square it off.
    private func corner(_ path: inout Path, through: CGPoint, to: CGPoint, radius: CGFloat) {
        if radius < 0.5 {
            path.addLine(to: through)
            path.addLine(to: to)
        } else {
            path.addArc(tangent1End: through, tangent2End: to, radius: radius)
        }
    }

}

// MARK: - Bubble

public struct SKChatBubble<Content: View>: View {
    private let role: SKChatRole
    private let position: SKChatPosition
    private let status: SKChatStatus
    private let timestamp: Date?
    private let onRetry: (() -> Void)?
    private let content: Content

    /// Minimum gutter on the opposite side. This is what caps bubble width —
    /// a percentage would need a `GeometryReader`, and wrapping every message
    /// in one is both slower and a well-known way to break lazy stacks.
    private let gutter: CGFloat = 56

    public init(
        role: SKChatRole,
        position: SKChatPosition = .only,
        status: SKChatStatus = .sent,
        timestamp: Date? = nil,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.role = role
        self.position = position
        self.status = status
        self.timestamp = timestamp
        self.onRetry = onRetry
        self.content = content()
    }

    private var isUser: Bool { role == .user }

    private var shape: SKBubbleShape {
        SKBubbleShape(
            radius: SK.Radius.xl,
            tail: position.hasTail ? (isUser ? .trailing : .leading) : .none,
            tightTop: position.tightTop,
            tightBottom: position.tightBottom
        )
    }

    private var fill: Color {
        if status == .failed { return SK.Palette.dangerSoft }
        return isUser ? SK.Palette.accent : SK.Palette.fill
    }

    private var textColor: Color {
        if status == .failed { return SK.Palette.label }
        return isUser ? Color.white : SK.Palette.label
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: SK.Space.xs) {
            if isUser {
                Spacer(minLength: gutter)
                if status == .failed { retryButton }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: SK.Space.xs) {
                content
                    .font(SK.Type_.body)
                    .foregroundStyle(textColor)
                    // Without this a long message is laid out on one line and
                    // then compressed, instead of wrapping.
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .padding(.horizontal, SK.Space.lg)
                    .padding(.vertical, SK.Space.md)
                    .background(fill, in: shape)
                    .overlay {
                        // Assistant bubbles sit on a surface of nearly the same
                        // value, so they need an edge to separate from it.
                        if !isUser && status != .failed {
                            shape.strokeBorder(SK.Palette.separator, lineWidth: SK.Stroke.thin)
                        }
                    }
                    .opacity(status == .sending ? 0.55 : 1)
                    .skAnimation(.snap, value: status)

                if let timestamp, position.hasTail {
                    Text(timestamp, format: .dateTime.hour().minute())
                        .font(SK.Type_.caption)
                        .foregroundStyle(SK.Palette.labelTertiary)
                        .padding(.horizontal, SK.Space.xs)
                }
            }
            .frame(maxWidth: 560, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer(minLength: gutter) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isUser ? "You said" : "Assistant said")
        .accessibilityValue(status == .failed ? "Failed to send" : "")
    }

    private var retryButton: some View {
        Button {
            onRetry?()
            SK.Haptic.play(.light)
        } label: {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(SK.Icon.symbol(SK.Icon.lg))
                .foregroundStyle(SK.Palette.danger)
        }
        .buttonStyle(.skPress(scale: 0.9, haptic: nil))
        .accessibilityLabel("Retry sending")
        .padding(.bottom, SK.Space.xs)
    }
}

// MARK: - Text convenience

extension SKChatBubble where Content == Text {
    /// The common case: a plain-text message.
    public init(
        _ text: String,
        role: SKChatRole,
        position: SKChatPosition = .only,
        status: SKChatStatus = .sent,
        timestamp: Date? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.init(
            role: role,
            position: position,
            status: status,
            timestamp: timestamp,
            onRetry: onRetry
        ) {
            Text(text)
        }
    }
}

#Preview("SKChatBubble") {
    ScrollView {
        VStack(spacing: SK.Space.xs) {
            SKChatBubble("Morning — did the migration finish?", role: .user, position: .first)
            SKChatBubble("And did anything fail overnight?", role: .user, position: .last,
                         timestamp: .now)

            SKChatBubble("It finished at 04:12.", role: .assistant, position: .first)
            SKChatBubble(
                "Two rows were rejected for a null tenant id. Everything else moved cleanly — 1,284,003 records in 38 minutes.",
                role: .assistant, position: .last, timestamp: .now
            )

            SKChatBubble("Can you retry those two?", role: .user, status: .sending)
            SKChatBubble("Send this when you get a chance", role: .user, status: .failed) {}
        }
        .padding(SK.Space.lg)
    }
    .background(SK.Palette.surface)
}
