//
//  EventDate.swift
//  Cync
//
//  학생회 공지의 "행사 날짜" (시작일·마감일). The server takes and returns
//  plain `yyyy-MM-dd` days (`eventStartDate` / `eventEndDate`); on the app
//  side a day is a `Date` at local midnight, as in the 캘린더 tab.
//
//  Conversion keeps the *day*, not the instant: the picked year/month/day
//  is rebuilt at midnight in Asia/Seoul before formatting (and the other
//  way when reading), so a device outside Korea doesn't send the day
//  before or after.
//

import Foundation

/// What the 학생회 공지 create/update request says about the event date.
enum EventDateChange: Equatable {
    /// No date parameters — create: no date / update: keep the current one.
    case none
    /// `eventStartDate`, plus `eventEndDate` only for a period (end after start).
    case set(start: Date, end: Date?)
    /// `clearEventDate=true` — update only.
    case clear

    /// Multipart fields for this change. `.clear` is dropped on create
    /// (`allowsClear: false`), where there's nothing to clear.
    func formFields(allowsClear: Bool) -> [String: String] {
        switch self {
        case .none:
            return [:]
        case let .set(start, end):
            var fields = ["eventStartDate": EventDateFormat.serverString(from: start)]
            if let end, EventDateFormat.day(end) > EventDateFormat.day(start) {
                fields["eventEndDate"] = EventDateFormat.serverString(from: end)
            }
            return fields
        case .clear:
            return allowsClear ? ["clearEventDate": "true"] : [:]
        }
    }
}

/// The date chosen on the compose screen. `end == nil` is a one-day event.
struct EventDateSelection: Equatable {
    var start: Date
    var end: Date?

    var isRange: Bool { end != nil }

    /// Same day for start and end counts as one day, so "period on, end =
    /// start" equals the one-day selection it came from.
    var normalized: EventDateSelection {
        let start = EventDateFormat.day(start)
        guard let end else { return EventDateSelection(start: start) }
        let endDay = EventDateFormat.day(end)
        return EventDateSelection(start: start, end: endDay > start ? endDay : nil)
    }
}

/// Which row's calendar is open.
enum EventDateField: Hashable {
    case start
    case end
}

enum EventDateFormat {
    private static let seoul = TimeZone(identifier: "Asia/Seoul")!

    private static let seoulCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = seoul
        return calendar
    }()

    /// Local wall-clock calendar for reading/writing year-month-day.
    private static var localCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private static let serverFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = seoulCalendar
        formatter.timeZone = seoul
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Local midnight of `date`'s day.
    static func day(_ date: Date) -> Date {
        localCalendar.startOfDay(for: date)
    }

    /// `"2026-11-20"` for the local day of `date`.
    static func serverString(from date: Date) -> String {
        let parts = localCalendar.dateComponents([.year, .month, .day], from: date)
        let seoulMidnight = seoulCalendar.date(from: parts) ?? date
        return serverFormatter.string(from: seoulMidnight)
    }

    /// Local midnight of a server `yyyy-MM-dd` day; nil for nil/garbage.
    static func date(fromServer string: String?) -> Date? {
        guard let string, let seoulMidnight = serverFormatter.date(from: string) else { return nil }
        let parts = seoulCalendar.dateComponents([.year, .month, .day], from: seoulMidnight)
        return localCalendar.date(from: parts)
    }

    /// On-screen day — "2026. 11. 20. (목)" in Korean, "Fri, 11/20/2026" in English.
    static func displayString(from date: Date) -> String {
        date.formatted(
            .dateTime.year().month(.defaultDigits).day().weekday(.abbreviated)
                .locale(AppLanguage.currentLocale)
        )
    }
}
