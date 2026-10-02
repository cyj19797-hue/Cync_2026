//
//  CalendarEventRow.swift
//  test
//
//  Figma node `240:1688` ("캘린더 세부 일정") — one row in the "등록된 일정"
//  card: a category-colored accent bar, title + bookmark, then a meta line.
//  Title and meta follow `NoticeRow`'s rules (title up to two lines, gray
//  "카테고리 • …" line) since these are often the same notices, but the meta
//  line carries schedule info instead of a posting date:
//  "학사 • 오전 10:00 • 마감 D-3" / "학사 • 9월 20일~24일" / "학사".
//  The date itself isn't repeated — the card/section header already shows it.
//

import SwiftUI

struct CalendarEventRow: View {
    let event: CalendarEvent
    /// Hidden once a specific category chip is selected, same as `NoticeRow`.
    var showsCategory = true
    /// Past-event styling on the monthly list: bar, title and meta fade to
    /// `dimmedOpacity`, while the bookmark keeps full color and stays
    /// tappable so it never looks disabled.
    var isDimmed = false
    let onToggleBookmark: () -> Void

    private static let dimmedOpacity = 0.45
    private var contentOpacity: Double { isDimmed ? Self.dimmedOpacity : 1 }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.category.accentColor)
                .frame(width: 4)
                .opacity(contentOpacity)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Text(event.title)
                        .font(.noticeTitle).tracking(Tracking.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(contentOpacity)

                    BookmarkButton(isBookmarked: event.isBookmarked, action: onToggleBookmark)
                }

                metaLine
                    .opacity(contentOpacity)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    private var metaLine: some View {
        HStack(spacing: Spacing.xs) {
            if showsCategory {
                metaText(Text(event.category.label))
            }

            if let when = whenText {
                if showsCategory { separatorDot }
                metaText(Text(verbatim: when))
            }

            if let kind = event.kind {
                if showsCategory || whenText != nil { separatorDot }
                kindLabel(kind)
            }
        }
    }

    /// Range for multi-day entries, time of day for timed ones, otherwise
    /// nothing — the meta line then shows just the category.
    private var whenText: String? {
        if event.isMultiDay {
            return (event.startDate..<event.endDate).formatted(.interval.month().day().locale(AppLanguage.currentLocale))
        }
        if event.hasTime {
            return event.startDate.formatted(.dateTime.hour().minute().locale(AppLanguage.currentLocale))
        }
        return nil
    }

    @ViewBuilder
    private func kindLabel(_ kind: CalendarEvent.Kind) -> some View {
        switch kind {
        case .deadline:
            if let days = event.deadlineDays() {
                Text(.noticeDeadline(days))
                    .font(.noticeDeadline).tracking(Tracking.noticeDeadline)
                    .foregroundStyle(Color.accentRed)
            } else {
                metaText(Text(.calendarKindDeadline))
            }
        case .event:
            metaText(Text(.calendarKindEvent))
        }
    }

    private func metaText(_ text: Text) -> some View {
        text
            .font(.noticeDate).tracking(Tracking.noticeDate)
            .foregroundStyle(Color.textSecondary)
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.gray400)
            .frame(width: 4, height: 4)
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
