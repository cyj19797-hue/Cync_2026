
//
//  CalendarWeekdayHeaderRow.swift
//  test
//
//  Figma node `I240:1678;44:3687;44:3491` ("week") — the 일/월/화/수/목/금/토
//  header row above the day grid. Symbols come from `DateFormatter` rotated
//  to `Calendar.current.firstWeekday` instead of a hardcoded Korean array,
//  so it reads "S M T W T F S" for an English-locale user automatically.
//

import SwiftUI

struct CalendarWeekdayHeaderRow: View {
    private var symbols: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        let all = formatter.shortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let firstIndex = calendar.firstWeekday - 1
        return Array(all[firstIndex...] + all[..<firstIndex])
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.calendarWeekdayLabel)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    CalendarWeekdayHeaderRow()
        .padding()
}
