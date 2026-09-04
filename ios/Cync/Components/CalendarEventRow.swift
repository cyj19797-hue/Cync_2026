//
//  CalendarEventRow.swift
//  test
//
//  Figma node `240:1688` ("캘린더 세부 일정") — one row in the "등록된 일정"
//  card: a colored accent bar, title + bookmark, then a plain-text category
//  + optional "마감 D-n" tag line. Visually close to `NoticeRow`, but the
//  leading element is a solid accent bar instead of a pill badge, so it's
//  its own component rather than reusing NoticeRow.
//

import SwiftUI

struct CalendarEventRow: View {
    let event: CalendarEvent
    let onToggleBookmark: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.eventAccent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(event.title)
                        .font(.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    BookmarkButton(isBookmarked: event.isBookmarked, action: onToggleBookmark)
                }

                HStack(spacing: Spacing.xs) {
                    Text(event.category.localizedKey)
                        .font(.noticeDate)
                        .foregroundStyle(Color.textPrimary)

                    if let deadlineDays = event.deadlineDays {
                        Circle()
                            .fill(Color.gray400)
                            .frame(width: 4, height: 4)

                        Text("마감 D-\(deadlineDays)")
                            .font(.noticeDeadline)
                            .foregroundStyle(Color.accentRed)
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    VStack {
        ForEach(CalendarEvent.mockList) { event in
            CalendarEventRow(event: event) {}
        }
    }
    .padding()
}
