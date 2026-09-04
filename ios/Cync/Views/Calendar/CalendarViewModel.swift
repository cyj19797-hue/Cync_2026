//
//  CalendarViewModel.swift
//  Cync
//
//  Backs CalendarView with the real `GET /api/academic-schedule` call
//  (`docs/API.md` §6).
//

import Combine
import Foundation

/// One cell in the month grid — includes the leading/trailing days from the
/// adjacent months so the grid always renders full weeks.
struct CalendarDay: Identifiable, Hashable {
    let date: Date
    let isWithinDisplayedMonth: Bool
    var id: Date { date }
}

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent]
    @Published var selectedCategory: NoticeCategory = .all
    @Published var searchText: String = ""
    @Published var displayedMonth: Date
    @Published var selectedDate: Date
    @Published var errorMessage: String?

    private let calendar = Calendar.current

    init(
        events: [CalendarEvent] = [],
        referenceDate: Date = Date()
    ) {
        self.events = events
        self.displayedMonth = referenceDate
        self.selectedDate = referenceDate
    }

    func load() async {
        do {
            let schedules = try await CyncAPI.fetchAcademicSchedules()
            events = schedules.compactMap(CalendarEvent.init(schedule:))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Full weeks (7-day rows) covering `displayedMonth`, trimmed so a
    /// trailing week made up entirely of next-month days is dropped —
    /// matches how Apple's own Calendar app sizes the grid (5 or 6 rows
    /// depending on the month), rather than always rendering 6.
    var visibleDays: [CalendarDay] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        var days: [CalendarDay] = []
        var cursor = firstWeek.start
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(cursor, equalTo: displayedMonth, toGranularity: .month)
            days.append(CalendarDay(date: cursor, isWithinDisplayedMonth: isCurrentMonth))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }

        var weeks = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0 + 7]) }
        while let lastWeek = weeks.last, lastWeek.allSatisfy({ !$0.isWithinDisplayedMonth }) {
            weeks.removeLast()
        }
        return weeks.flatMap { $0 }
    }

    var eventsForSelectedDate: [CalendarEvent] {
        events.filter { event in
            let matchesCategory = selectedCategory == .all || event.category == selectedCategory
            let matchesDate = event.contains(selectedDate, calendar: calendar)
            let matchesSearch = searchText.isEmpty || event.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesDate && matchesSearch
        }
    }

    func hasEvent(on date: Date) -> Bool {
        events.contains { event in
            let matchesCategory = selectedCategory == .all || event.category == selectedCategory
            return matchesCategory && event.contains(date, calendar: calendar)
        }
    }

    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Selects a grid cell's date. If the cell belongs to the adjacent
    /// month (leading/trailing gray days), the displayed month also jumps
    /// there so the grid re-centers on it.
    func selectDay(_ day: CalendarDay) {
        if !day.isWithinDisplayedMonth {
            displayedMonth = day.date
        }
        selectedDate = day.date
    }

    func goToPreviousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    func goToNextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    func toggleBookmark(for event: CalendarEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index].isBookmarked.toggle()
    }
}
