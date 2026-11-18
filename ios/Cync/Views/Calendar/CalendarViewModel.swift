//
//  CalendarViewModel.swift
//  Cync
//
//  Backs CalendarView. Students see only the notices they bookmarked in
//  `BookmarkStore` (see `CalendarEvent.events(fromBookmarkedNotice:)`);
//  admins also see every `GET /api/academic-schedule` row (`docs/API.md` §6).
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

    /// What's on the calendar depends on who's signed in:
    ///   - students: only the notices they bookmarked on "공지사항"
    ///     (`BookmarkStore`), on the dates extracted from each notice.
    ///   - admins: additionally every row of `GET /api/academic-schedule`.
    /// `scheduleEvents` is fetched only for admins.
    private var scheduleEvents: [CalendarEvent] = []
    private var bookmarkEvents: [CalendarEvent] = []
    private var isAdmin = CurrentUserSession.shared.profile?.isAdmin ?? false
    private let isPreview: Bool
    private var bookmarkSubscription: AnyCancellable?

    init(referenceDate: Date = Date()) {
        events = []
        displayedMonth = referenceDate
        selectedDate = referenceDate
        isPreview = false

        // Follows bookmark changes live — the calendar tab stays alive
        // while the user bookmarks on "공지사항", so a one-time read in
        // `load()` would miss them. `$bookmarkedNotices` emits on the main
        // actor (BookmarkStore is @MainActor) and once right away.
        bookmarkSubscription = BookmarkStore.shared.$bookmarkedNotices
            .sink { [weak self] notices in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.bookmarkEvents = notices.flatMap(CalendarEvent.events(fromBookmarkedNotice:))
                    self.rebuildEvents()
                }
            }
    }

    /// Preview data — shown as-is, never calls the server.
    init(events: [CalendarEvent], referenceDate: Date) {
        self.events = events
        displayedMonth = referenceDate
        selectedDate = referenceDate
        isPreview = true
    }

    func load() async {
        guard !isPreview else { return }
        // Bookmarks are saved snapshots — prune ones whose notice is no
        // longer on the server before they land on the calendar.
        await BookmarkStore.shared.refreshFromServer()
        if let profile = try? await CurrentUserSession.shared.refresh() {
            isAdmin = profile.isAdmin
        }
        guard isAdmin else {
            scheduleEvents = []
            rebuildEvents()
            return
        }
        do {
            let schedules = try await CyncAPI.fetchAcademicSchedules()
            scheduleEvents = schedules.compactMap(CalendarEvent.init(schedule:))
            rebuildEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rebuildEvents() {
        events = (isAdmin ? scheduleEvents : []) + bookmarkEvents
    }

    /// Full weeks covering `displayedMonth` (see `CalendarMonthGrid`).
    var visibleDays: [CalendarDay] {
        CalendarMonthGrid.days(for: displayedMonth, calendar: calendar)
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
        Self.oncePerNotice(
            filteredEvents
                .filter { $0.contains(selectedDate, calendar: calendar) }
                .sorted(by: Self.displayOrder)
        )
    }

    /// One bookmarked notice can yield several dates — a 신청 기간 plus the
    /// 마감/행사 days inside it, or overlapping periods — and they're kept as
    /// separate entries. A day still lists each notice once: a specific
    /// day (마감 / 행사 / timed) beats a period covering it, so 11/29 shows
    /// "마감 23:59", not "11/22~11/29". Keeps `events`' order otherwise.
    private static func oncePerNotice(_ events: [CalendarEvent]) -> [CalendarEvent] {
        func rank(_ event: CalendarEvent) -> Int {
            if event.isMultiDay { return event.kind == nil ? 3 : 2 }
            return event.kind == nil && !event.hasTime ? 1 : 0
        }
        var best: [Int: CalendarEvent] = [:]
        for event in events {
            guard let noticeId = event.sourceNoticeId else { continue }
            if let current = best[noticeId], rank(current) <= rank(event) { continue }
            best[noticeId] = event
        }
        return events.filter { event in
            guard let noticeId = event.sourceNoticeId else { return true }
            return best[noticeId]?.id == event.id
        }
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
            .map { CalendarDaySection(date: $0.key, events: Self.oncePerNotice($0.value.sorted(by: Self.displayOrder))) }
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
        Self.oncePerNotice(filteredEvents.filter { $0.contains(date, calendar: calendar) }).count
    }

    /// Empty-state copy for the selected day — names the category when a
    /// specific chip is on ("이 날은 학생회 일정이 없어요.").
    var emptyDayMessage: LocalizedStringResource {
        guard selectedCategory != .all else { return .calendarEmpty }
        return .calendarEmptyDayCategory(String(appLocalized: selectedCategory.label))
    }

    /// Empty-state copy for the monthly list ("9월 학생회 일정이 없어요.").
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
    /// What the detail card shows for `event`: the bookmarked notice itself
    /// when the event came from one, otherwise the schedule's own fields.
    /// `nil` once the event is gone (its bookmark was just removed).
    func detailContent(for event: CalendarEvent) -> NoticeDetailContent? {
        if let noticeId = event.sourceNoticeId {
            guard var notice = BookmarkStore.shared.bookmarkedNotices.first(where: { $0.id == noticeId }) else { return nil }
            notice.isBookmarked = true
            return NoticeDetailContent(notice: notice)
        }
        return events.first { $0.id == event.id }.map(NoticeDetailContent.init(schedule:))
    }

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
