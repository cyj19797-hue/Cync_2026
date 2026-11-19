//
//  MockServer.swift
//  Cync
//
//  DEBUG-only canned server responses, switched on per launch with a
//  launch argument (Xcode: Edit Scheme > Run > Arguments, or
//  `xcrun simctl launch … -mockPopupNotices`). Release builds don't
//  contain this file's code paths at all.
//
//  - `-mockPopupNotices`: `CyncAPI.fetchPopupNotices()` returns the two
//    popup fixtures below (a short one and a long one, created at
//    different times) instead of calling the server.
//  - `-mockPopupNoticesEdited` (with the above): the long notice comes back
//    with a newer `updatedAt`, as if an admin had edited it — to check that
//    a notice dismissed with "다시 보지 않기" pops up again after an edit.
//  - `-debugTab community`: starts on that main tab (notices / calendar /
//    lockers / community / settings) instead of 공지사항.
//  - `-debugOpenFirstPost` (with `-debugTab community`): opens the
//    most-commented post's detail screen once the list loads.
//  - `-debugComposer expanded|reply` (with the above): the comment input
//    starts expanded, or replying to the first comment with a sample draft.
//  - `-debugCategory academic|studentCouncil`: 공지사항 and 캘린더 start
//    with that category chip selected.
//  - `-debugCalendarEvent notice|schedule` (with `-debugTab calendar`):
//    opens the first bookmarked-notice event, or server schedule, of the
//    month in the detail card.
//  - `-debugOpenNotice`: opens the first notice (under `-debugCategory`, if
//    given) in the 공지사항 detail card.
//  - `-debugCompose councilCreate|councilEdit`: pushes the 학생회 공지
//    작성 screen, or 수정 pre-filled with a sample period notice, once
//    공지사항 loads (no admin login needed to look at it).
//  - `-debugEventDate start|end|clear` (with `-debugCompose`): the 행사 날짜
//    section starts with today's 시작일 calendar open (start), a 4-day
//    period with the 마감일 calendar open (end), or the existing date
//    removed (clear, edit only).
//  - `-debugComposeAutoSubmit` (with `-debugCompose`): fills any empty
//    title/content with a sample and presses 등록/저장 after a second — with
//    `-mockCouncilCompose`, to read the sent fields without tapping.
//  - `-mockCouncilCompose`: 학생회 공지 작성/수정 don't call the server —
//    the multipart fields that would be sent are printed to the console
//    (`[MockServer] POST /api/notices/council …`) and a fake notice comes
//    back. Applies the server's date rules (end without start, or end
//    before start → 400) so the "날짜를 다시 확인해 주세요" popup can be checked.
//  - `-mockPopupOpenDetail`: opens the first card's 자세히 보기 detail screen
//    right after loading — to check that screen without tapping.
//
//  Fixture text is mock data, not UI copy (CLAUDE.md exception).
//

#if DEBUG
import Foundation

enum MockServer {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var opensPopupDetail: Bool { arguments.contains("-mockPopupOpenDetail") }

    /// Value after `name` in the launch arguments ("-debugTab community").
    private static func value(after name: String) -> String? {
        guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    static var initialTab: String? { value(after: "-debugTab") }
    static var opensFirstPost: Bool { arguments.contains("-debugOpenFirstPost") }
    static var composerState: String? { value(after: "-debugComposer") }
    static var calendarEvent: String? { value(after: "-debugCalendarEvent") }
    static var opensFirstNotice: Bool { arguments.contains("-debugOpenNotice") }
    static var initialCategory: NoticeCategory? {
        switch value(after: "-debugCategory") {
        case "academic": return .academic
        case "studentCouncil": return .studentCouncil
        default: return nil
        }
    }

    /// `-debugCompose` — handed out once, so coming back to 공지사항 after
    /// the screen closes doesn't push it again.
    @MainActor private static var didOpenComposeScreen = false
    @MainActor static func takeComposeScreen() -> String? {
        guard !didOpenComposeScreen else { return nil }
        didOpenComposeScreen = true
        return value(after: "-debugCompose")
    }
    static var mocksCouncilCompose: Bool { arguments.contains("-mockCouncilCompose") }
    static var eventDateState: String? { value(after: "-debugEventDate") }
    static var autoSubmitsCompose: Bool { arguments.contains("-debugComposeAutoSubmit") }

    /// Sample for `-debugCompose councilEdit`: a 3-day event starting the
    /// day after tomorrow.
    static var councilEditSample: NoticeComposeTarget {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return .edit(
            noticeId: 0,
            councilId: 1,
            title: "학생회 체육대회 참가 신청 안내",
            content: "학과 체육대회 참가 신청을 받습니다.",
            imageURL: nil,
            eventStart: calendar.date(byAdding: .day, value: 2, to: today),
            eventEnd: calendar.date(byAdding: .day, value: 4, to: today)
        )
    }

    /// `-mockCouncilCompose`: logs what would be sent and answers like the
    /// server would.
    static func councilNoticeResponse(
        method: String,
        path: String,
        fields: [String: String],
        hasImage: Bool
    ) throws -> CouncilNotice {
        let logged = fields
            .filter { $0.key != "content" }
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        print("[MockServer] \(method) \(path) \(logged) image=\(hasImage)")

        let start = fields["eventStartDate"]
        let end = fields["eventEndDate"]
        if end != nil && (start == nil || end! < start!) {
            print("[MockServer] → 400")
            throw CyncAPIError.badStatus(400)
        }
        let now = "2026-11-18T12:00:00"
        return CouncilNotice(
            id: 1,
            title: fields["title"] ?? "",
            content: fields["content"] ?? "",
            imageUrl: nil,
            authorId: "mock",
            authorName: "mock",
            createdAt: now,
            updatedAt: now,
            eventStartDate: start,
            eventEndDate: start == nil ? nil : (end ?? start)
        )
    }

    /// `nil` unless launched with `-mockPopupNotices`.
    static var popupNotices: [AppNotice]? {
        guard arguments.contains("-mockPopupNotices") else { return nil }
        let isEdited = arguments.contains("-mockPopupNoticesEdited")
        // Server order is not newest-first — the older one comes first on
        // purpose so the client-side sort is exercised.
        return [
            AppNotice.mockLongPopup(updatedAt: isEdited ? "2026-11-16T15:00:00" : "2026-11-15T10:00:00"),
            AppNotice.mockShortPopup
        ]
    }
}

extension AppNotice {
    static let mockShortPopup = AppNotice(
        id: 9001,
        title: "11/20(목) 서버 점검 안내",
        content: "더 안정적인 서비스를 위해 서버 점검을 진행해요. 점검 중에는 로그인과 사물함 신청이 잠시 멈춰요.",
        isPopup: true,
        createdAt: "2026-11-17T09:00:00"
    )

    static func mockLongPopup(updatedAt: String = "2026-11-15T10:00:00") -> AppNotice {
        AppNotice(
            id: 9002,
            title: "Cync 2.0 업데이트 안내 — 새로워진 캘린더와 사물함",
            content: """
            Cync가 2.0으로 업데이트되었어요. 이번 업데이트에서 달라진 점을 알려드려요.

            1. 캘린더: 공지사항에서 북마크한 글의 신청 기간·마감·행사 날짜가 캘린더에 자동으로 표시돼요. 같은 날 여러 일정이 있어도 한눈에 볼 수 있도록 정리했어요.

            2. 사물함: 신청부터 승인까지의 과정이 더 빨라졌어요. 승인이 완료되면 '나의 사물함' 카드에서 바로 비밀번호를 확인할 수 있어요.

            3. 커뮤니티: 신고 기능이 개선되어, 불편한 게시글과 댓글을 더 쉽게 알릴 수 있어요.

            4. 언어 설정: 설정 > 언어 설정에서 한국어와 English 중 원하는 언어를 고를 수 있어요. 바꾸면 앱을 다시 시작하지 않아도 바로 적용돼요.

            앞으로도 더 편리한 학교생활을 위해 노력할게요. 사용하면서 불편한 점이나 바라는 기능이 있다면 설정 > 문의하기로 알려 주세요. 감사합니다!
            """,
            isPopup: true,
            createdAt: "2026-11-15T10:00:00",
            updatedAt: updatedAt
        )
    }
}
#endif
