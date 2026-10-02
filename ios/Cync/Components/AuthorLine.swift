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
    let authorName: String
    let createdAt: Date
    var nameColor: Color = .textPrimary

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(authorName)
                .font(.commentAuthor).tracking(Tracking.commentAuthor)
                .foregroundStyle(nameColor)
                .lineLimit(1)

            // Separator is punctuation, identical in every language.
            Text(verbatim: "·")
                .font(.calendarCaption).tracking(Tracking.calendarCaption)
                .foregroundStyle(Color.gray400)

            Text(RelativeTime.text(for: createdAt))
                .font(.calendarCaption).tracking(Tracking.calendarCaption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        AuthorLine(authorName: "익명1", createdAt: Date().addingTimeInterval(-180))
        AuthorLine(authorName: "글쓴이", createdAt: Date().addingTimeInterval(-7200), nameColor: .eventAccent)
    }
    .padding()
}
