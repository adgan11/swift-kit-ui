//
//  SKConversationRow.swift
//  Swift Kit UI
//
//  Requires: SwiftKitUI.swift
//
//  A row in the conversation list — the screen people actually live in once
//  they have used an assistant for a week.
//
//  The timestamp adapts to age rather than printing a date: a time for today,
//  a weekday inside the last week, a date beyond that. It is a small thing and
//  it is the difference between a list you can scan and a column of
//  "28/09/2026" that all looks the same.
//
//  Unread is carried by weight and a dot, never by colour alone — a
//  colour-only unread state is invisible to a meaningful share of users, and
//  this is precisely the kind of state that must not be.
//
//  Swiping is left to the list. `List` already has `.swipeActions` with the
//  correct physics and accessibility, and a hand-rolled swipe inside the row
//  fights it.
//
//  Usage:
//      SKConversationRow(title: "Q3 revenue", preview: "…", date: date,
//                        isUnread: true) { open() }
//

import SwiftUI

public struct SKConversationRow: View {
    private let title: String
    private let preview: String?
    private let date: Date?
    private let isUnread: Bool
    private let isPinned: Bool
    private let isSelected: Bool
    private let systemImage: String?
    private let onTap: (() -> Void)?

    public init(
        title: String,
        preview: String? = nil,
        date: Date? = nil,
        isUnread: Bool = false,
        isPinned: Bool = false,
        isSelected: Bool = false,
        systemImage: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.preview = preview
        self.date = date
        self.isUnread = isUnread
        self.isPinned = isPinned
        self.isSelected = isSelected
        self.systemImage = systemImage
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
            SK.Haptic.play(.light)
        } label: {
            HStack(alignment: .top, spacing: SK.Space.md) {
                if let systemImage {
                    ZStack {
                        RoundedRectangle(cornerRadius: SK.Radius.sm, style: .continuous)
                            .fill(isSelected ? SK.Palette.accent : SK.Palette.fill)
                            .frame(width: 34, height: 34)
                        Image(systemName: systemImage)
                            .font(SK.Icon.symbol(SK.Icon.sm))
                            .foregroundStyle(isSelected ? Color.white : SK.Palette.labelSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: SK.Space.xs) {
                        if isPinned {
                            Image(systemName: "pin.fill")
                                .font(SK.Icon.symbol(SK.Icon.xs))
                                .foregroundStyle(SK.Palette.labelTertiary)
                                .accessibilityLabel("Pinned")
                        }
                        Text(title)
                            .font(SK.Type_.callout)
                            // Weight, not just colour — unread has to survive
                            // a greyscale screenshot.
                            .fontWeight(isUnread ? .bold : .medium)
                            .foregroundStyle(SK.Palette.label)
                            .lineLimit(1)
                    }

                    if let preview {
                        Text(preview)
                            .font(SK.Type_.caption)
                            .foregroundStyle(isUnread ? SK.Palette.labelSecondary : SK.Palette.labelTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: SK.Space.sm)

                VStack(alignment: .trailing, spacing: SK.Space.xs + 2) {
                    if let date {
                        Text(stamp(for: date))
                            .font(SK.Type_.caption)
                            .foregroundStyle(SK.Palette.labelTertiary)
                            .monospacedDigit()
                    }
                    if isUnread {
                        Circle()
                            .fill(SK.Palette.accent)
                            .frame(width: 8, height: 8)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.vertical, SK.Space.md)
            .padding(.horizontal, SK.Space.lg)
            .background(
                isSelected ? SK.Palette.accentSoft : Color.clear,
                in: RoundedRectangle(cornerRadius: SK.Radius.md, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.skPress(scale: 0.99, haptic: nil))
        .skAnimation(.snap, value: isUnread)
        .skAnimation(.snap, value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isUnread ? "Unread. \(preview ?? "")" : (preview ?? ""))
    }

    /// Time today, weekday this week, date beyond. Printing a full date on
    /// every row makes the column unscannable.
    private func stamp(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return date.formatted(.dateTime.hour().minute())
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        if let week = calendar.date(byAdding: .day, value: -7, to: .now), date > week {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

#Preview("SKConversationRow") {
    ScrollView {
        VStack(spacing: SK.Space.xxs) {
            SKConversationRow(
                title: "Q3 revenue teardown",
                preview: "Annual plans are 61% of new subscriptions — the mix shifted, demand did not.",
                date: .now,
                isUnread: true,
                isPinned: true,
                systemImage: "chart.line.uptrend.xyaxis"
            )
            SKConversationRow(
                title: "Migration rollback plan",
                preview: "Two rows rejected for a null tenant id; everything else moved cleanly.",
                date: Date(timeIntervalSinceNow: -3600 * 30),
                isSelected: true,
                systemImage: "arrow.triangle.2.circlepath"
            )
            SKConversationRow(
                title: "Onboarding copy",
                preview: "Shorter second screen, and the permission ask moves after the first win.",
                date: Date(timeIntervalSinceNow: -3600 * 96),
                systemImage: "text.bubble"
            )
        }
        .padding(SK.Space.sm)
    }
    .background(SK.Palette.surface)
}
