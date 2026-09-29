//
//  CalendarEvent.swift
//  Cync
//
//  Data model backing the "3 캘린더" (Calendar) screen's "등록된 일정"
//  (registered schedule) list — mapped from the real `AcademicSchedule`
//  shape returned by `GET /api/academic-schedule` (`docs/API.md` §6).
//
//  The server only distinguishes two sources (`SCHOOL`/`STUDENT_COUNCIL`),
//  not the app's 5-way `NoticeCategory` filter (전체/학사/장학/학생회/국제교류)
//  — see the gap table: 장학/국제교류 have no server category yet, so those
//  two filter chips will always be empty against real data.
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
/// (inclusive; single-day schedules have `startDate == endDate`).
struct CalendarEvent: Identifiable, Hashable {
    let id: Int
    var category: NoticeCategory
    var title: String
    var startDate: Date
    var endDate: Date
    /// Not provided by `AcademicSchedule` (no deadline concept there) —
    /// always `nil` for real data; kept only so `CalendarEventRow`'s
    /// existing "마감 D-n" badge still compiles and previews unchanged.
    var deadlineDays: Int?
    /// Local-only — the API has no per-user bookmark endpoint (see the gap
    /// table), so this never persists and resets on every reload.
    var isBookmarked: Bool = false
    /// Set only on events synthesized from `BookmarkStore` (see
    /// `init(bookmarkedNotice:)`) — the source notice's own id, so
    /// `CalendarViewModel.toggleBookmark` can un-bookmark it there instead
    /// of just flipping a flag that resets on reload. `nil` for events that
    /// came straight from `GET /api/academic-schedule`.
    var sourceNoticeId: Int?

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
            endDate: end
        )
    }
}

extension CalendarEvent {
    /// Offsets a bookmarked notice's id clear of `AcademicSchedule`'s id
    /// space — the two are unrelated servers/tables and could otherwise
    /// collide (both number their rows from 1).
    private static let bookmarkedNoticeIDOffset = 100_000_000

    /// Maps a bookmarked notice (from `BookmarkStore`) onto a same-day
    /// calendar event, so bookmarking a notice on "공지사항" also surfaces
    /// it on "캘린더" — see `BookmarkStore`'s header comment.
    init(bookmarkedNotice notice: Notice) {
        self.init(
            id: notice.id + Self.bookmarkedNoticeIDOffset,
            category: notice.category,
            title: notice.title,
            startDate: notice.date,
            endDate: notice.date,
            deadlineDays: notice.deadlineDays,
            isBookmarked: true,
            sourceNoticeId: notice.id
        )
    }
}

extension CalendarEvent {
    /// Mock data for previews only — the real list always comes from
    /// `GET /api/academic-schedule` (see `CalendarViewModel.load()`).
    static let mockList: [CalendarEvent] = {
        let calendar = Calendar.current
        func day(_ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 8, day: day))!
        }

        return [
            CalendarEvent(id: 1, category: .academic, title: "2026학년도 2학기 수강정정 안내", startDate: day(10), endDate: day(10), deadlineDays: 6),
            CalendarEvent(id: 2, category: .studentCouncil, title: "학생회 정기 모임", startDate: day(19), endDate: day(19)),
            CalendarEvent(id: 3, category: .academic, title: "중간고사 기간", startDate: day(20), endDate: day(24))
        ]
    }()

    /// The month the mock events live in — the calendar screen opens on
    /// this month so the mock data is visible without navigating.
    static let mockReferenceDate: Date = {
        Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10))!
    }()
}
