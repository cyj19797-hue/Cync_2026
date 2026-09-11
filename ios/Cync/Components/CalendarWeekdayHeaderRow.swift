
//
//  CalendarWeekdayHeaderRow.swift
//  test
//
//  Figma node `I240:1678;44:3687;44:3491` ("week") — the 일/월/화/수/목/금/토
//  header row above the day grid. Symbols come from `DateFormatter` rotated
//  to `Calendar.current.firstWeekday`, with the locale forced to `ko_KR` (not
//  `Locale.current`) so it always reads "일 월 화 수 목 금 토" regardless of the
//  device's language/region setting — the app is Korean-first (see
//  `Typography.swift`'s header comment), so date/weekday text shouldn't
//  silently flip to English on an English-locale device.
//

import SwiftUI

struct CalendarWeekdayHeaderRow: View {
    private var symbols: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ko_KR")
        let all = formatter.shortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let firstIndex = calendar.firstWeekday - 1
        return Array(all[firstIndex...] + all[..<firstIndex])
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.calendarWeekdayLabel).tracking(Tracking.calendarWeekdayLabel)
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
