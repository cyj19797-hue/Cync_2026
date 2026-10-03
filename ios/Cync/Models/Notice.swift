//
//  Notice.swift
//  test
//
//  Data model backing the "공지사항" (Notices) screen — merges two boards:
//  the real `StudentCouncilNotice` shape from `GET /api/notices/council`
//  (`docs/API.md` §3, usually empty — no one's posted yet) and the crawled
//  `SchoolNotice` shape from `GET /api/notices/school` (`docs/API.md` §7,
//  the one that's actually populated).
//
//  The filter categories follow those two boards: 학사 (department) and
//  학생회 (student council).
//

import Foundation
import SwiftUI

/// The category filters shown as chips at the top of the notice list
/// ("전체" / "학사" / "학생회" — one per notice board in the API spec).
///
/// NOTE: Figma also included a 6th chip literally labeled "버튼" ("Button").
/// It reads as a leftover demo/placeholder component rather than a real
/// category, so it was not carried over — see the summary for details.
enum NoticeCategory: String, CaseIterable, Identifiable, Codable {
    case all = "전체"
    case academic = "학사"
    case studentCouncil = "학생회"

    var id: String { rawValue }

    /// Display label. `rawValue` stays the Korean category string the
    /// server sends (see `NoticeCategory(rawValue:)` below), so the UI label
    /// is looked up separately in `Localizable.xcstrings`.
    var label: LocalizedStringResource {
        switch self {
        case .all: return .noticeCategoryAll
        case .academic: return .noticeCategoryAcademic
        case .studentCouncil: return .noticeCategoryStudentCouncil
        }
    }

    /// Calendar event dot / row accent bar color for this category.
    var accentColor: Color {
        switch self {
        case .all, .academic: return .categoryAcademic
        case .studentCouncil: return .categoryStudentCouncil
        }
    }
}

/// A single 공지사항 (notice/announcement) list entry.
///
/// `originalText` / `translatedText` mirror the backend's AI-translation
/// feature (Spring Boot API) — this screen doesn't render them yet, but the
/// detail screen that will read this model needs them from day one.
struct Notice: Identifiable, Codable {
    let id: Int
    var category: NoticeCategory
    var title: String
    var date: Date
    /// Days remaining until the notice's deadline, e.g. `6` → "마감 D-6".
    /// `nil` when the notice has no deadline (most notices).
    var deadlineDays: Int?
    var isBookmarked: Bool
    var originalText: String
    var translatedText: String?
    /// Department-website page for this notice (`SchoolNotice.sourceUrl`).
    /// `nil` for boards written in-app (student council), which have no
    /// external original.
    var sourceURL: URL? = nil

    /// Absolute date in the current locale: "2026.09.01." in Korean,
    /// "Sep 1, 2026" in English.
    var dateText: String {
        RelativeTime.absoluteDateText(for: date)
    }

    /// List-row date: "오늘" / "어제" / "3일 전" ("Today" / "Yesterday" /
    /// "3 days ago") within the last week, `dateText` beyond that. Counted
    /// in calendar days since the school board only gives a posting day,
    /// not a time.
    var listDateText: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: Date())
        ).day ?? .max

        guard (0..<7).contains(days) else { return dateText }

        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.formattingContext = .beginningOfSentence
        formatter.locale = AppLanguage.currentLocale
        return formatter.localizedString(from: DateComponents(day: -days))
    }
}

/// Raw shape of one row from `GET /api/notices/council` (`docs/API.md` §3's
/// `StudentCouncilNotice`).
struct CouncilNotice: Decodable {
    let id: Int
    let title: String
    let content: String
    let imageUrl: String?
    let authorId: String
    let authorName: String
    let createdAt: String
    let updatedAt: String
}

extension Notice {
    /// Maps a server-side student council notice onto the app's `Notice`
    /// model. Fields the council board doesn't have — `deadlineDays`
    /// (no deadline concept), `isBookmarked` (no per-user bookmark API yet),
    /// `translatedText` (no AI-translation for this board yet) — are left
    /// at their empty defaults, same reasoning as `CalendarEvent`'s gaps.
    init(councilNotice: CouncilNotice) {
        self.init(
            id: councilNotice.id,
            category: .studentCouncil,
            title: councilNotice.title,
            date: SpringDate.parse(councilNotice.createdAt),
            deadlineDays: nil,
            isBookmarked: false,
            originalText: councilNotice.content,
            translatedText: nil
        )
    }
}

/// Raw shape of one row from `GET /api/notices/school` (`docs/API.md` §7's
/// `SchoolNotice`) — department notices crawled from the school site.
///
/// The server's actual JSON key for this field is `notice`, not `isNotice`
/// as `docs/API.md` has it — Jackson serializes a Java `isNotice()` getter
/// by dropping the `is` prefix. Verified directly against a live response
/// from `/api/notices/school`, whose keys are `id, articleNo, title,
/// content, category, postedDate, viewCount, sourceUrl, crawledAt, notice`.
struct SchoolNotice: Decodable {
    let id: Int
    let articleNo: Int
    let title: String
    let content: String?
    let category: String
    let isNotice: Bool
    let postedDate: String
    let viewCount: Int
    let sourceUrl: String
    let crawledAt: String

    enum CodingKeys: String, CodingKey {
        case id, articleNo, title, content, category, postedDate, viewCount, sourceUrl, crawledAt
        case isNotice = "notice"
    }
}

extension Notice {
    /// Offsets `SchoolNotice.id` clear of `CouncilNotice.id` — both boards
    /// number their rows from 1, and the merged list needs one `Identifiable`
    /// id space.
    private static let schoolNoticeIDOffset = 1_000_000

    /// Maps a crawled department notice onto the app's `Notice` model.
    /// `category` is free-text from the crawler (예: "학사", "행사", "기타",
    /// or blank) rather than one of `NoticeCategory`'s fixed cases, so
    /// anything that isn't an exact match falls back to `.academic` — these
    /// are all department-office notices at heart. When the crawler hasn't
    /// picked up a body (`content` nil/empty, e.g. image-only posts),
    /// `originalText` stays empty and `NoticeDetailView` shows a "check the
    /// original" message above its original-post link instead.
    init(schoolNotice: SchoolNotice) {
        self.init(
            id: schoolNotice.id + Self.schoolNoticeIDOffset,
            category: NoticeCategory(rawValue: schoolNotice.category) ?? .academic,
            title: schoolNotice.title,
            date: SpringDate.parseDottedDay(schoolNotice.postedDate) ?? Date(),
            deadlineDays: nil,
            isBookmarked: false,
            originalText: schoolNotice.content ?? "",
            translatedText: nil,
            sourceURL: URL(string: schoolNotice.sourceUrl)
        )
    }
}

extension Notice {
    /// Mock data for previews only — the real list always comes from
    /// `GET /api/notices/council` (see `NoticeListViewModel.load()`).
    static let mockList: [Notice] = {
        let calendar = Calendar.current
        let day = calendar.date(from: DateComponents(year: 2026, month: 8, day: 18))!

        return [
            Notice(
                id: 1,
                category: .academic,
                title: "2026학년도 2학기 수강정정 안내",
                date: day,
                deadlineDays: nil,
                isBookmarked: false,
                originalText: "2026학년도 2학기 수강정정 기간 및 절차를 안내드립니다.",
                translatedText: nil
            ),
            Notice(
                id: 2,
                category: .academic,
                title: "수강신청",
                date: day,
                deadlineDays: nil,
                isBookmarked: true,
                originalText: "2026학년도 2학기 수강신청 관련 공지입니다.",
                translatedText: nil
            ),
            Notice(
                id: 3,
                category: .studentCouncil,
                title: "파자마파티즈의 노래 자랑 대회 신청 안내",
                date: day,
                deadlineDays: 6,
                isBookmarked: false,
                // Longer body so the "2-1 공지글" detail screen's content
                // area actually needs to scroll in previews/mocks.
                originalText: """
                학과 행사 '파자마파티즈 노래 자랑 대회' 참가 신청을 받습니다.

                일시: 2026년 8월 24일(월) 18:00
                장소: 학생회관 대강당
                신청 대상: 컴퓨터공학과 재학생 누구나
                신청 방법: 학생회 인스타그램 DM 또는 학과 사무실 방문 접수

                참가자 전원에게 기념품이 제공되며, 우수상 수상자에게는 상금이 지급됩니다. \
                많은 관심과 참여 부탁드립니다.

                문의: 학생회 (02-000-0000)
                """,
                translatedText: """
                We are accepting applications for the department's "Pajama Parties" \
                singing contest.

                Date: Monday, August 24, 2026, 6:00 PM
                Venue: Student Union Auditorium
                Eligibility: Any enrolled Computer Engineering student
                How to apply: DM the student council's Instagram or visit the \
                department office

                All participants will receive a small gift, and cash prizes will be \
                awarded to the top performers. We look forward to your participation!

                Contact: Student Council (02-000-0000)
                """,
                sourceURL: URL(string: "https://ce.sejong.ac.kr")
            ),
            Notice(
                id: 4,
                category: .studentCouncil,
                title: "학생회 정기 모임 일정 변경 안내",
                date: day,
                deadlineDays: nil,
                isBookmarked: false,
                originalText: "이번 주 학생회 정기 모임 일정이 변경되었습니다.",
                translatedText: nil
            )
        ]
    }()
}
