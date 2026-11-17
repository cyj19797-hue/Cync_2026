
//
//  CalendarWeekdayHeaderRow.swift
//  test
//
//  Figma node `I240:1678;44:3687;44:3491` ("week") — the 일/월/화/수/목/금/토
//  header row above the day grid. Symbols come from `DateFormatter` in the
//  current locale (일/월/… in Korean, Sun/Mon/… in English), rotated to
//  `Calendar.current.firstWeekday`. Sunday is red and Saturday blue, the
//  same as their day numbers in `CalendarDayCell`.
//

import SwiftUI

struct CalendarWeekdayHeaderRow: View {
    /// (symbol, weekday number 1…7 where 1 = Sunday), in display order.
    private var weekdays: [(symbol: String, weekday: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = AppLanguage.currentLocale
        let all = formatter.shortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let firstIndex = calendar.firstWeekday - 1
        let order = Array(firstIndex..<7) + Array(0..<firstIndex)
        return order.map { (all[$0], $0 + 1) }
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(weekdays, id: \.weekday) { item in
                Text(item.symbol)
                    .font(.calendarWeekdayLabel).tracking(Tracking.calendarWeekdayLabel)
                    .foregroundStyle(color(for: item.weekday))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func color(for weekday: Int) -> Color {
        switch weekday {
        case 1: return .calendarSunday
        case 7: return .calendarSaturday
        default: return .textPrimary
        }
    }
}

#Preview {
    CalendarWeekdayHeaderRow()
        .padding()
}
