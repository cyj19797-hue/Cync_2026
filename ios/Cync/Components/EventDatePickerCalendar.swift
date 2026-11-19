//
//  EventDatePickerCalendar.swift
//  Cync
//
//  The fold-out month calendar under a 시작일/마감일 row on the 학생회 공지
//  compose screen (`ComposeEventDateSection`). Built from the 캘린더 tab's
//  own parts — `CalendarMonthHeader`, `CalendarWeekdayHeaderRow`,
//  `CalendarDayCell` and `CalendarMonthGrid` — instead of the system
//  `DatePicker`, so it looks like the rest of the app.
//
//  - No event or holiday dots.
//  - Selected days (start, and end for a period) are `CalendarDayCell`'s
//    blue circle; the days between sit on a light `eventAccentTint` band
//    that runs from the start's center to the end's center. The grid has
//    no column gap so the band is unbroken.
//  - In the 마감일 calendar, days before the start are dimmed and can't be
//    tapped.
//  - Opens on the month of the date being edited.
//

import SwiftUI

struct EventDatePickerCalendar: View {
    let selection: EventDateSelection
    /// Which row this calendar edits.
    let field: EventDateField
    let onSelect: (Date) -> Void

    @State private var displayedMonth: Date

    private let calendar = Calendar.current
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private static let numberSize: CGFloat = 28

    init(selection: EventDateSelection, field: EventDateField, onSelect: @escaping (Date) -> Void) {
        self.selection = selection
        self.field = field
        self.onSelect = onSelect
        let edited = field == .end ? (selection.end ?? selection.start) : selection.start
        _displayedMonth = State(initialValue: Calendar.current.dateInterval(of: .month, for: edited)?.start ?? edited)
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            CalendarMonthHeader(
                month: displayedMonth,
                style: .leading,
                onPrevious: { changeMonth(by: -1) },
                onNext: { changeMonth(by: 1) }
            )

            CalendarWeekdayHeaderRow()

            LazyVGrid(columns: Self.columns, spacing: Spacing.xs) {
                ForEach(CalendarMonthGrid.days(for: displayedMonth, calendar: calendar)) { day in
                    dayCell(day)
                }
            }
        }
        .padding(.horizontal, Spacing.cardInset)
        .padding(.bottom, Spacing.cardInset)
        .background {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .fill(Color.appBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.borderLight, lineWidth: 1)
        }
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        let isDisabled = field == .end && day.date < selection.start
        return CalendarDayCell(
            day: day,
            isSelected: isSelected(day.date),
            isToday: calendar.isDateInToday(day.date)
        ) {
            onSelect(day.date)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .top) { rangeBand(for: day.date) }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.35 : 1)
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selection.start)
            || selection.end.map { calendar.isDate(date, inSameDayAs: $0) } == true
    }

    /// The light band behind a period: half a column on the start and end
    /// days (toward the inside), the full column in between.
    @ViewBuilder
    private func rangeBand(for date: Date) -> some View {
        if let end = selection.end, end > selection.start, date >= selection.start, date <= end {
            let isStart = calendar.isDate(date, inSameDayAs: selection.start)
            let isEnd = calendar.isDate(date, inSameDayAs: end)
            GeometryReader { proxy in
                let half = proxy.size.width / 2
                Rectangle()
                    .fill(Color.eventAccentTint)
                    .frame(width: isStart || isEnd ? half : proxy.size.width)
                    .offset(x: isStart ? half : 0)
            }
            .frame(height: Self.numberSize)
        }
    }

    private func changeMonth(by value: Int) {
        if let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = month
        }
    }
}

#Preview {
    let today = Calendar.current.startOfDay(for: Date())
    let end = Calendar.current.date(byAdding: .day, value: 4, to: today)!
    return VStack(spacing: Spacing.md) {
        EventDatePickerCalendar(selection: EventDateSelection(start: today), field: .start) { _ in }
        EventDatePickerCalendar(selection: EventDateSelection(start: today, end: end), field: .end) { _ in }
    }
    .padding()
}
