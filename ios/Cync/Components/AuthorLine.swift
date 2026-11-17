//
//  AuthorLine.swift
//  test
//
//  Figma node `236:2150` ("닉네임") — "익명 · 3분 전". Appears once on the
//  post header and once per comment/reply on "5-1 게시글", so it's a
//  shared small component rather than duplicated 5×.
//
//  The time is relative (`RelativeTime`, same as the community feed), not
//  the old fixed "MM/dd HH:mm" — that didn't match the notice board's
//  "2026.09.01." style. `nameColor` lets a comment by the post's author
//  ("글쓴이") stand out in the accent color.
//

import SwiftUI

struct AuthorLine: View {
    enum Style {
        /// Post header (Semibold 16 name).
        case standard
        /// The admin report card's preview box (Semibold 14 name, Figma
        /// `729:3891`).
        case compact
        /// A comment row on "5-1 게시글" (Semibold 14 name, 10pt meta).
        case comment
    }

    private var nameFont: Font {
        switch style {
        case .standard: .commentAuthor
        case .compact: .adminReportAuthor
        case .comment: .commentRowAuthor
        }
    }

    private var nameTracking: CGFloat {
        switch style {
        case .standard: Tracking.commentAuthor
        case .compact: Tracking.adminReportAuthor
        case .comment: Tracking.commentRowAuthor
        }
    }

    /// Date, separator and badge.
    private var metaFont: Font { style == .comment ? .commentRowMeta : .calendarCaption }
    private var metaTracking: CGFloat { style == .comment ? Tracking.commentRowMeta : Tracking.calendarCaption }

    let authorName: String
    let createdAt: Date
    /// A tag after the name — "글쓴이" on a comment by the post's author,
    /// so it reads "익명 글쓴이 · 9/15": the same name the post shows,
    /// marked as the author (see `badge(_:)`).
    var badgeKey: LocalizedStringResource? = nil
    var style: Style = .standard

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(authorName)
                .font(nameFont).tracking(nameTracking)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            if let badgeKey {
                badge(badgeKey)
            }

            // Separator is punctuation, identical in every language.
            Text(verbatim: "·")
                .font(metaFont).tracking(metaTracking)
                .foregroundStyle(Color.textSecondary)

            Text(RelativeTime.text(for: createdAt))
                .font(metaFont).tracking(metaTracking)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }
}

extension AuthorLine {
    /// "글쓴이" as plain dark-blue text right after the name — no box or
    /// tint, so it doesn't outweigh the name next to it (a tinted box made
    /// "익명" look smaller than a plain "익명1"). Same size as the date.
    private func badge(_ key: LocalizedStringResource) -> some View {
        Text(key)
            .font(metaFont).tracking(metaTracking)
            .foregroundStyle(Color.accentStrong)
            .lineLimit(1)
    }
}

#Preview {
    VStack(alignment: .leading) {
        AuthorLine(authorName: "익명1", createdAt: Date().addingTimeInterval(-180))
        AuthorLine(authorName: "익명", createdAt: Date().addingTimeInterval(-7200), badgeKey: "글쓴이")
    }
    .padding()
}
