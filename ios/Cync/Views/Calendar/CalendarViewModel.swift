//
//  CalendarViewModel.swift
//  Cync
//
//  Backs CalendarView with the real `GET /api/academic-schedule` call
//  (`docs/API.md` §6), plus whatever notices are bookmarked in
//  `BookmarkStore` — see `CalendarEvent.init(bookmarkedNotice:)`.
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

extension FormatStyle where Self == Date.FormatStyle {
    /// Short day label shared by the calendar card header and the monthly
    /// list's day headers — "9월 2일 (수)" in Korean, "Wed, Sep 2" in English.
    static var calendarDay: Date.FormatStyle {
        .dateTime.month(.abbreviated).day().weekday(.abbreviated).locale(AppLanguage.currentLocale)
    }
}

/// One day's section in the month-wide event list ("9월 전체 일정").
struct CalendarDaySection: Identifiable {
    let date: Date
    let events: [CalendarEvent]
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
            let scheduleEvents = schedules.compactMap(CalendarEvent.init(schedule:))
            let bookmarkEvents = BookmarkStore.shared.bookmarkedNotices.flatMap(CalendarEvent.events(fromBookmarkedNotice:))
            events = scheduleEvents + bookmarkEvents
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

    /// Events passing the category chip + search text filters.
    private var filteredEvents: [CalendarEvent] {
        events.filter { event in
            let matchesCategory = selectedCategory == .all || event.category == selectedCategory
            let matchesSearch = searchText.isEmpty || event.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var eventsForSelectedDate: [CalendarEvent] {
        filteredEvents
            .filter { $0.contains(selectedDate, calendar: calendar) }
            .sorted(by: Self.displayOrder)
    }

    /// Every day in `displayedMonth` that has at least one event, for the
    /// "N월 전체 일정" screen. A multi-day event is listed once, on its first
    /// day within the month, instead of repeating on every day it spans.
    var sectionsForDisplayedMonth: [CalendarDaySection] {
        guard let month = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let lastDay = calendar.date(byAdding: .day, value: -1, to: month.end) ?? month.start

        let grouped = Dictionary(grouping: filteredEvents.filter { event in
            calendar.startOfDay(for: event.startDate) <= lastDay && event.endDate >= month.start
        }) { event in
            max(calendar.startOfDay(for: event.startDate), month.start)
        }

        return grouped
            .map { CalendarDaySection(date: $0.key, events: $0.value.sorted(by: Self.displayOrder)) }
            .sorted { $0.date < $1.date }
    }

    /// Timed entries first in time order, then all-day ones.
    private static func displayOrder(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        if lhs.hasTime != rhs.hasTime { return lhs.hasTime }
        return lhs.startDate < rhs.startDate
    }

    /// Distinct categories with a dot on `date`, in filter-chip order — one
    /// colored dot each under the day number (at most 3 fit). A multi-day
    /// period only gets dots on its first and last day, not the days between.
    func eventCategories(on date: Date) -> [NoticeCategory] {
        let categories = Set(events.filter { event in
            let matchesCategory = selectedCategory == .all || event.category == selectedCategory
            let marksDay = event.isMultiDay
                ? calendar.isDate(event.startDate, inSameDayAs: date) || calendar.isDate(event.endDate, inSameDayAs: date)
                : event.contains(date, calendar: calendar)
            return matchesCategory && marksDay
        }.map(\.category))
        return NoticeCategory.allCases.filter(categories.contains)
    }

    func eventCount(on date: Date) -> Int {
        filteredEvents.filter { $0.contains(date, calendar: calendar) }.count
    }

    /// Empty-state copy for the selected day — names the category when a
    /// specific chip is on ("이 날은 장학 일정이 없어요.").
    var emptyDayMessage: LocalizedStringResource {
        guard selectedCategory != .all else { return .calendarEmpty }
        return .calendarEmptyDayCategory(String(appLocalized: selectedCategory.label))
    }

    /// Empty-state copy for the monthly list ("9월 장학 일정이 없어요.").
    var emptyMonthMessage: LocalizedStringResource {
        guard selectedCategory != .all else { return .calendarEmptyMonth }
        return .calendarEmptyMonthCategory(
            displayedMonth.formatted(.dateTime.month(.wide).locale(AppLanguage.currentLocale)),
            String(appLocalized: selectedCategory.label)
        )
    }

    /// Whether every event in `section` has already ended — the monthly
    /// list dims those days so upcoming ones stand out.
    func isPast(_ section: CalendarDaySection) -> Bool {
        let today = calendar.startOfDay(for: Date())
        return section.events.allSatisfy { calendar.startOfDay(for: $0.endDate) < today }
    }

    /// Past-day dimming on the monthly list — applies in every month, so a
    /// fully past month renders dimmed throughout.
    func isDimmed(_ section: CalendarDaySection) -> Bool {
        isPast(section)
    }


    /// First section still relevant today (the monthly list scrolls here on
    /// entry). `nil` when the displayed month isn't the current one.
    var firstUpcomingSectionID: Date? {
        guard isShowingCurrentMonth else { return nil }
        return sectionsForDisplayedMonth.first { !isPast($0) }?.id
    }

    func holiday(on date: Date) -> KoreanHoliday? {
        KoreanHolidayCalendar.holiday(on: date, calendar: calendar)
    }

    /// Whether the grid is already on this month with today selected —
    /// the header's "오늘" button hides then.
    var isShowingToday: Bool {
        isShowingCurrentMonth && isToday(selectedDate)
    }

    /// The monthly list has no day selection, so its "오늘" button only
    /// cares about the month.
    var isShowingCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
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

    func goToToday() {
        let today = Date()
        displayedMonth = today
        selectedDate = today
    }

    func goToPreviousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    func goToNextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    /// Events synthesized from `BookmarkStore` (`sourceNoticeId != nil`)
    /// un-bookmark for real — removed from the store and the list. Events
    /// straight from the schedule API have no bookmark backing store, so
    /// their flag just flips locally (existing behavior, resets on reload).
    func toggleBookmark(for event: CalendarEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        if let sourceNoticeId = events[index].sourceNoticeId {
            // One notice can yield several dates — drop all of them.
            BookmarkStore.shared.remove(noticeId: sourceNoticeId)
            events.removeAll { $0.sourceNoticeId == sourceNoticeId }
        } else {
            events[index].isBookmarked.toggle()
        }
    }
}
