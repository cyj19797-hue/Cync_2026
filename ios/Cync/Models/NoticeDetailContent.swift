//
//  NoticeDetailContent.swift
//  Cync
//
//  What the "2-1 공지글" detail card (`NoticeDetailView`) shows, built from
//  either of its two sources:
//
//  - a `Notice` (공지사항 tab, or a 캘린더 entry that came from a bookmarked
//    notice): body, AI translation, photo, "원문 보기" link — everything.
//  - a server schedule (`CalendarEvent` from `GET /api/academic-schedule`,
//    which has no notice behind it): only title, category and its date or
//    period. `body == nil` tells the card to drop the body, the
//    원문/AI번역 toggle and the link.
//

import Foundation

struct NoticeDetailContent {
    var category: NoticeCategory
    var title: String
    /// Next to the category badge: the posting date for a notice, the
    /// schedule's day or period for a schedule.
    var dateText: String
    var deadlineDays: Int?
    var isBookmarked: Bool
    /// `nil` = a schedule (no body at all). An empty string is a notice
    /// whose body couldn't be fetched ("원문을 불러올 수 없어요").
    var body: String?
    var translatedText: String?
    var sourceURL: URL?
    var imageURL: URL?
}

extension NoticeDetailContent {
    init(notice: Notice) {
        self.init(
            category: notice.category,
            title: notice.title,
            dateText: notice.dateText,
            deadlineDays: notice.deadlineDays,
            isBookmarked: notice.isBookmarked,
            body: notice.originalText,
            translatedText: notice.translatedText,
            sourceURL: notice.sourceURL,
            imageURL: notice.imageURL
        )
    }

    /// "11월 20일 (목)" for a single day (plus the time when it has one),
    /// "11월 20일 (목) ~ 11월 22일 (토)" for a period — in the app's language.
    init(schedule event: CalendarEvent) {
        self.init(
            category: event.category,
            title: event.title,
            dateText: Self.periodText(for: event),
            deadlineDays: event.deadlineDays(),
            isBookmarked: event.isBookmarked,
            body: nil
        )
    }

    private static func periodText(for event: CalendarEvent) -> String {
        let locale = AppLanguage.currentLocale
        let day = Date.FormatStyle.dateTime.month(.wide).day().weekday(.abbreviated).locale(locale)
        if event.isMultiDay {
            return String(appLocalized: .calendarDetailPeriod(
                event.startDate.formatted(day),
                event.endDate.formatted(day)
            ))
        }
        if event.hasTime {
            return event.startDate.formatted(day.hour().minute())
        }
        return event.startDate.formatted(day)
    }
}
