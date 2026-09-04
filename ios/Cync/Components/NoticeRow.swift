//
//  NoticeRow.swift
//  test
//
//  Figma node `44:269` ("공지사항 글") — one notice list entry: category badge
//  + title + bookmark on the first line, date (+ optional "마감 D-n") below.
//
//  The hairline divider under each entry (`I44:269;184:1676`, image asset
//  "Frame 121") is not redrawn as a custom asset — `List` already supplies a
//  row separator, so the parent view relies on that instead (see §10 of the
//  design-to-code guide: don't hand-roll separators `List` gives for free).
//

import SwiftUI

struct NoticeRow: View {
    let notice: Notice
    let onToggleBookmark: () -> Void
    /// Opens the "2-1 공지글" detail card. `nil` keeps the row static (used
    /// by the standalone preview below).
    var onSelect: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    NoticeCategoryBadge(category: notice.category)
                    Text(notice.title)
                        .font(.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture { onSelect?() }

                Spacer(minLength: 0)

                BookmarkButton(isBookmarked: notice.isBookmarked, action: onToggleBookmark)
            }

            HStack(spacing: Spacing.xs) {
                Text(notice.dateText)
                    .font(.noticeDate)
                    .foregroundStyle(Color.textPrimary)

                if let deadlineDays = notice.deadlineDays {
                    Circle()
                        .fill(Color.gray400)
                        .frame(width: 4, height: 4)

                    Text("마감 D-\(deadlineDays)")
                        .font(.noticeDeadline)
                        .foregroundStyle(Color.accentRed)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelect?() }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    List {
        ForEach(Notice.mockList) { notice in
            NoticeRow(notice: notice) {}
        }
    }
    .listStyle(.plain)
}
