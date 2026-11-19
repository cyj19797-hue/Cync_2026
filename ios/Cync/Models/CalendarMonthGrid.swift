//
//  CalendarMonthGrid.swift
//  Cync
//
//  The month's day grid, shared by the 캘린더 tab (`CalendarViewModel`)
//  and the 행사 날짜 picker on the 학생회 공지 compose screen
//  (`EventDatePickerCalendar`).
//

import Foundation

enum CalendarMonthGrid {
    /// Full weeks (7-day rows) covering `month`, trimmed so a trailing week
    /// made up entirely of next-month days is dropped — matches how Apple's
    /// own Calendar app sizes the grid (5 or 6 rows depending on the
    /// month), rather than always rendering 6.
    static func days(for month: Date, calendar: Calendar = .current) -> [CalendarDay] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        var days: [CalendarDay] = []
        var cursor = firstWeek.start
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(cursor, equalTo: month, toGranularity: .month)
            days.append(CalendarDay(date: cursor, isWithinDisplayedMonth: isCurrentMonth))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }

        var weeks = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0 + 7]) }
        while let lastWeek = weeks.last, lastWeek.allSatisfy({ !$0.isWithinDisplayedMonth }) {
            weeks.removeLast()
        }
        return weeks.flatMap { $0 }
    }
}
