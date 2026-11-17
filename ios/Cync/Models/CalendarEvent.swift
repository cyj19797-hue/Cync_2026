//
//  CalendarEvent.swift
//  Cync
//
//  Data model backing the "3 캘린더" (Calendar) screen's "등록된 일정"
//  (registered schedule) list — mapped from the real `AcademicSchedule`
//  shape returned by `GET /api/academic-schedule` (`docs/API.md` §6).
//
//  The server distinguishes two sources (`SCHOOL`/`STUDENT_COUNCIL`), which
//  map onto `NoticeCategory`'s 학사 / 학생회 filters.
//

import Foundation

/// Raw shape of one row from `GET /api/academic-schedule`.
struct AcademicSchedule: Decodable {
    let id: Int
    let title: String
    let startDate: String
    let endDate: String
    let source: String
    let authorId: String?
}

private enum ScheduleSource: String {
    case school = "SCHOOL"
    case studentCouncil = "STUDENT_COUNCIL"
}

/// One entry in "등록된 일정" — a schedule item spanning `startDate...endDate`
/// (inclusive; single-day schedules have `startDate == endDate`'s day).
struct CalendarEvent: Identifiable, Hashable {
    /// What the user has to do on this date. `nil` for plain schedules
    /// (multi-day periods, or dates with no recognizable keyword).
    enum Kind: Hashable {
        case deadline
        case event
    }

    let id: Int
    var category: NoticeCategory
    var title: String
    /// Carries the time of day when `hasTime` is true.
    var startDate: Date
    /// Start of the last day (inclusive).
    var endDate: Date
    var hasTime: Bool = false
    var kind: Kind?
    /// Local-only — the API has no per-user bookmark endpoint (see the gap
    /// table), so this never persists and resets on every reload.
    var isBookmarked: Bool = false
    /// Set only on events synthesized from `BookmarkStore` (see
    /// `events(fromBookmarkedNotice:)`) — the source notice's own id, so
    /// `CalendarViewModel.toggleBookmark` can un-bookmark it there instead
    /// of just flipping a flag that resets on reload. `nil` for events that
    /// came straight from `GET /api/academic-schedule`.
    var sourceNoticeId: Int?

    var isMultiDay: Bool {
        !Calendar.current.isDate(startDate, inSameDayAs: endDate)
    }

    /// Days left until a deadline ("마감 D-n"), `nil` for non-deadlines and
    /// deadlines already past.
    func deadlineDays(from today: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard kind == .deadline else { return nil }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: today),
            to: calendar.startOfDay(for: endDate)
        ).day ?? -1
        return days >= 0 ? days : nil
    }

    /// Whether this schedule covers `date` — multi-day entries (school
    /// breaks, exam periods) span more than just `startDate`.
    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: startDate) && day <= calendar.startOfDay(for: endDate)
    }
}

extension CalendarEvent {
    init?(schedule: AcademicSchedule) {
        guard
            let start = SpringDate.parseDay(schedule.startDate),
            let end = SpringDate.parseDay(schedule.endDate),
            let source = ScheduleSource(rawValue: schedule.source)
        else { return nil }

        self.init(
            id: schedule.id,
            category: source == .school ? .academic : .studentCouncil,
            title: schedule.title,
            startDate: start,
            endDate: end,
            // Only single-day entries get a kind — a multi-day one is a
            // period, and its title ("수강신청 기간") would misfire as a deadline.
            kind: Calendar.current.isDate(start, inSameDayAs: end)
                ? NoticeScheduleExtractor.kind(forLine: schedule.title)
                : nil
        )
    }
}

extension CalendarEvent {
    /// Keeps bookmarked-notice ids clear of `AcademicSchedule`'s id space
    /// (unrelated tables that both number rows from 1). Each notice gets a
    /// block of `idsPerNotice` ids, one per extracted date.
    private static let bookmarkedNoticeIDOffset = 1_000_000_000
    private static let idsPerNotice = 10

    /// Maps a bookmarked notice (from `BookmarkStore`) onto the dates the
    /// user has to act on — "9/2(수) 오전 10:00 증설", "6월 5일 신청 마감" —
    /// extracted from its body and title by `NoticeScheduleExtractor`. A
    /// notice with no recognizable date yields no events: it stays on
    /// "공지사항" only, rather than being pinned to its posting day (which
    /// would just repeat the notice list sorted by date).
    static func events(fromBookmarkedNotice notice: Notice) -> [CalendarEvent] {
        let text = notice.title + "\n" + notice.originalText
        return NoticeScheduleExtractor.extract(from: text, postedDate: notice.date)
            .prefix(idsPerNotice)
            .enumerated()
            .map { index, schedule in
                CalendarEvent(
                    id: bookmarkedNoticeIDOffset + notice.id * idsPerNotice + index,
                    category: notice.category,
                    title: notice.title,
                    startDate: schedule.startDate,
                    endDate: schedule.endDate,
                    hasTime: schedule.hasTime,
                    kind: schedule.kind,
                    isBookmarked: true,
                    sourceNoticeId: notice.id
                )
            }
    }
}

extension CalendarEvent {
    /// Mock data for previews only — the real list always comes from
    /// `GET /api/academic-schedule` (see `CalendarViewModel.load()`).
    static let mockList: [CalendarEvent] = {
        let calendar = Calendar.current
        func day(_ day: Int, hour: Int? = nil) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 8, day: day, hour: hour))!
        }

        return [
            CalendarEvent(id: 1, category: .academic, title: "2026학년도 2학기 수강정정 안내", startDate: day(10), endDate: day(10), kind: .deadline),
            CalendarEvent(id: 2, category: .studentCouncil, title: "학생회 정기 모임", startDate: day(10, hour: 18), endDate: day(10), hasTime: true, kind: .event),
            CalendarEvent(id: 3, category: .academic, title: "중간고사 기간", startDate: day(20), endDate: day(24)),
            CalendarEvent(id: 4, category: .academic, title: "교내 장학금 신청", startDate: day(20), endDate: day(20), kind: .deadline)
        ]
    }()

    /// The month the mock events live in — the calendar screen opens on
    /// this month so the mock data is visible without navigating.
    static let mockReferenceDate: Date = {
        Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10))!
    }()
}
