//
//  KoreanHoliday.swift
//  Cync
//
//  Korean public holidays (공휴일) shown on the calendar grid in red and
//  next to the selected date. There's no holiday API on the backend, so
//  this is a fixed table — lunar holidays (설날/추석/부처님 오신 날) and
//  substitute holidays (대체공휴일) move every year and can't be computed
//  with `Calendar(.gregorian)` alone. Extend the table each year.
//

import Foundation

struct KoreanHoliday {
    let name: LocalizedStringResource
}

enum KoreanHolidayCalendar {
    /// Keyed by `yyyyMMdd` as an Int.
    private static let table: [Int: LocalizedStringResource] = [
        // 2026
        20260101: .calendarHolidayNewYear,
        20260216: .calendarHolidaySeollal,
        20260217: .calendarHolidaySeollal,
        20260218: .calendarHolidaySeollal,
        20260301: .calendarHolidayIndependenceMovement,
        20260302: .calendarHolidaySubstitute,
        20260505: .calendarHolidayChildrensDay,
        20260524: .calendarHolidayBuddhasBirthday,
        20260525: .calendarHolidaySubstitute,
        20260603: .calendarHolidayLocalElection,
        20260606: .calendarHolidayMemorialDay,
        20260815: .calendarHolidayLiberationDay,
        20260817: .calendarHolidaySubstitute,
        20260924: .calendarHolidayChuseok,
        20260925: .calendarHolidayChuseok,
        20260926: .calendarHolidayChuseok,
        20261003: .calendarHolidayNationalFoundation,
        20261005: .calendarHolidaySubstitute,
        20261009: .calendarHolidayHangulDay,
        20261225: .calendarHolidayChristmas,
        // 2027
        20270101: .calendarHolidayNewYear,
        20270206: .calendarHolidaySeollal,
        20270207: .calendarHolidaySeollal,
        20270208: .calendarHolidaySeollal,
        20270209: .calendarHolidaySubstitute,
        20270301: .calendarHolidayIndependenceMovement,
        20270505: .calendarHolidayChildrensDay,
        20270513: .calendarHolidayBuddhasBirthday,
        20270606: .calendarHolidayMemorialDay,
        20270815: .calendarHolidayLiberationDay,
        20270816: .calendarHolidaySubstitute,
        20270914: .calendarHolidayChuseok,
        20270915: .calendarHolidayChuseok,
        20270916: .calendarHolidayChuseok,
        20271003: .calendarHolidayNationalFoundation,
        20271004: .calendarHolidaySubstitute,
        20271009: .calendarHolidayHangulDay,
        20271011: .calendarHolidaySubstitute,
        20271225: .calendarHolidayChristmas,
        20271227: .calendarHolidaySubstitute
    ]

    static func holiday(on date: Date, calendar: Calendar = .current) -> KoreanHoliday? {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }
        return table[year * 10_000 + month * 100 + day].map(KoreanHoliday.init(name:))
    }
}
