//
//  AuthorLine.swift
//  test
//
//  Figma node `236:2150` ("닉네임") — "익명 · 08/21 17:04". Appears once on
//  the post header and once per comment/reply on "5-1 게시글", so it's a
//  shared small component rather than duplicated 5×.
//

import SwiftUI

struct AuthorLine: View {
    let authorName: String
    let createdAt: Date

    // Fixed "MM/dd HH:mm" — a timestamp format like this is conventionally
    // shown the same way regardless of locale (compare Twitter/Instagram),
    // so `en_US_POSIX` pins the digits/24h format rather than reformatting
    // per-locale like the rest of the app's user-facing text.
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(authorName)
                .font(.commentAuthor)
            Text(Self.formatter.string(from: createdAt))
                .font(.calendarCaption)
        }
        .foregroundStyle(Color.textPrimary)
    }
}

#Preview {
    AuthorLine(authorName: "익명", createdAt: Date())
        .padding()
}
