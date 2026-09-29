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
//  Neither board has a concept of "장학"/"국제교류" notices yet — same gap
//  as `CalendarEvent`'s matching categories — so those filter chips will
//  stay empty against real data until those boards exist server-side.
//

import Foundation
import SwiftUI

/// The category filters shown as chips at the top of the notice list
/// (Figma node `42:108`, "전체" / "학사" / "장학" / "학생회" / "국제교류").
///
/// NOTE: Figma also included a 6th chip literally labeled "버튼" ("Button").
/// It reads as a leftover demo/placeholder component rather than a real
/// category, so it was not carried over — see the summary for details.
enum NoticeCategory: String, CaseIterable, Identifiable, Codable {
    case all = "전체"
    case academic = "학사"
    case scholarship = "장학"
    case studentCouncil = "학생회"
    case exchange = "국제교류"

    var id: String { rawValue }

    /// Wraps `rawValue` as a `LocalizedStringKey` so the Korean label can be
    /// looked up in a String Catalog (`Localizable.xcstrings`) for English.
    var localizedKey: LocalizedStringKey { LocalizedStringKey(rawValue) }
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

    var dateText: String {
        date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).locale(Locale(identifier: "ko_KR")))
            .replacingOccurrences(of: " ", with: "")
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
    /// picked up a body (`content` nil/empty), `sourceUrl` is shown instead,
    /// per `docs/API.md` §7's recommendation.
    init(schoolNotice: SchoolNotice) {
        self.init(
            id: schoolNotice.id + Self.schoolNoticeIDOffset,
            category: NoticeCategory(rawValue: schoolNotice.category) ?? .academic,
            title: schoolNotice.title,
            date: SpringDate.parseDottedDay(schoolNotice.postedDate) ?? Date(),
            deadlineDays: nil,
            isBookmarked: false,
            originalText: (schoolNotice.content?.isEmpty == false ? schoolNotice.content : nil) ?? schoolNotice.sourceUrl,
            translatedText: nil
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
                category: .scholarship,
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
                """
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
