//
//  NoticeRow.swift
//  test
//
//  Figma node `44:269` ("공지사항 글") — one notice list entry: title (up to
//  two lines) + bookmark on top, then "카테고리 · 날짜 · 마감 D-n" below.
//  Figma puts the category badge in front of the title, but that cut most
//  titles off after a few characters, so the category moved to the date
//  line as plain text (and is hidden under a specific category filter).
//
//  The hairline divider under each entry (`I44:269;184:1676`, image asset
//  "Frame 121") is not redrawn as a custom asset — `List` already supplies a
//  row separator, so the parent view relies on that instead (see §10 of the
//  design-to-code guide: don't hand-roll separators `List` gives for free).
//
//  The row's tap target is a real `Button` (`.buttonStyle(.plain)`), not a
//  bare `.contentShape(Rectangle()).onTapGesture` — inside a `List`, a plain
//  tap gesture placed beside a sibling `Button` (here, `BookmarkButton`)
//  doesn't reliably fire; `List` only arbitrates correctly between an
//  *outer* row `Button` and an inner nested one (`BookmarkButton` sitting
//  inside this `Button`'s label), which is the pattern below.
//

import SwiftUI

struct NoticeRow: View {
    let notice: Notice
    /// Shows the category in the date line — the list passes `false` once a
    /// specific category filter is selected, where every row's category
    /// would be the same.
    var showsCategory = true
    let onToggleBookmark: () -> Void
    /// Opens the "2-1 공지글" detail card. `nil` keeps the row static (used
    /// by the standalone preview below).
    var onSelect: (() -> Void)?

    var body: some View {
        Button {
            onSelect?()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Text(notice.title)
                        .font(.noticeTitle).tracking(Tracking.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    BookmarkButton(isBookmarked: notice.isBookmarked, action: onToggleBookmark)
                }

                HStack(spacing: Spacing.xs) {
                    if showsCategory {
                        Text(notice.category.label)
                            .font(.noticeDate).tracking(Tracking.noticeDate)
                            .foregroundStyle(Color.textSecondary)

                        separatorDot
                    }

                    Text(notice.listDateText)
                        .font(.noticeDate).tracking(Tracking.noticeDate)
                        .foregroundStyle(Color.textSecondary)

                    if let deadlineDays = notice.deadlineDays {
                        separatorDot

                        Text(.noticeDeadline(deadlineDays))
                            .font(.noticeDeadline).tracking(Tracking.noticeDeadline)
                            .foregroundStyle(Color.accentRed)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.xxs)
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.gray400)
            .frame(width: 4, height: 4)
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
