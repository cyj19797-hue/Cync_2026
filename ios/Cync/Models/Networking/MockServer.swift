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
//  - `-mockLockers`: the 사물함 endpoints (`/api/lockers`, `/pending`,
//    `/in-use`, `/return-all`) answer from an in-memory list built from
//    `lockers.json` instead of the server, and every call is printed
//    (`[MockServer] POST /api/lockers/return-all confirm=false …`).
//    The student's own locker (`mine`) is the first one in B203(1):
//    `-mockMyLocker pending|inUse|none` (default pending).
//  - `-mockLockerRejected` (with `-mockLockers`): that locker is back to
//    AVAILABLE and not mine — as if the request had been turned down.
//  - `-mockLockerRole student|admin`: overrides `isAdmin` on the 사물함 tab
//    (the student card and the rejection popup only show for students).
//  - `-debugAdminLocker`: opens 관리자 사물함 관리 on the 사용 중 tab once
//    the 사물함 tab loads; `-debugReturnAll` then taps 학기 말 전체 반납,
//    `-debugReturnAllIncludePending` ticks "승인 대기 신청도 함께 취소",
//    and `-debugReturnAllExecute` presses the red button 3s later.
//  - `-debugLockerExpand`: pushes the 전체 사물함 크게 보기 screen.
//  - `-mockAuth`: 로그인, `GET /api/me` and `POST /api/me/terms-agreement`
//    don't call the server. Any 학번/password logs in with a fake token
//    (`sub` = that 학번); `termsAgreed` is remembered per 학번 on the device
//    (so agreeing once sticks), and `99999999` (admin) is always agreed.
//    Calls are printed (`[MockServer] POST /api/auth/login …`).
//  - `-mockAuthReset` (with `-mockAuth`): forgets every agreement first.
//  - `-mockMeFails network|unauthorized` (with `-mockAuth`): `/api/me`
//    fails offline, or with 401.
//  - `-mockAgreeFails` (with `-mockAuth`): the agreement request fails (500).
//  - `-debugLogin <학번>`: fills the login form (자동 로그인 on) and presses
//    로그인 once the login screen shows — once per launch.
//  - `-debugLoggedOut`: starts logged out (drops any saved token) — to
//    log in again without tapping 로그아웃.
//  - `-debugAgree` / `-debugDecline`: on the terms screen, presses 모두
//    동의하고 시작하기 / 동의하지 않고 로그아웃 after a second.
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

    // MARK: - 로그인·약관 (`-mockAuth`)

    static var mocksAuth: Bool { arguments.contains("-mockAuth") }
    static var autoAgreesToTerms: Bool { arguments.contains("-debugAgree") }
    static var startsLoggedOut: Bool { arguments.contains("-debugLoggedOut") }
    /// `-debugLogin` goes straight to the login screen (no 앱 소개 tap).
    static var skipsIntro: Bool { arguments.contains("-debugLogin") }
    static var autoDeclinesTerms: Bool { arguments.contains("-debugDecline") }

    @MainActor private static var didTakeDebugLogin = false
    @MainActor static func takeDebugLoginStudentId() -> String? {
        guard !didTakeDebugLogin else { return nil }
        didTakeDebugLogin = true
        return value(after: "-debugLogin")
    }

    private static func agreedKey(_ studentId: String) -> String { "mockTermsAgreed.\(studentId)" }

    /// `-mockAuthReset` — called once at launch (SessionStore.init).
    static func resetAuthIfNeeded() {
        guard mocksAuth, arguments.contains("-mockAuthReset") else { return }
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("mockTermsAgreed.") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        print("[MockServer] agreements reset")
    }

    private static func isAgreed(_ studentId: String) -> Bool {
        studentId == "99999999" || UserDefaults.standard.bool(forKey: agreedKey(studentId))
    }

    /// An unsigned JWT-shaped token: `sub` = 학번, expiring in a year.
    private static func token(for studentId: String) -> String {
        func encode(_ json: String) -> String {
            Data(json.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        let exp = Int(Date().addingTimeInterval(365 * 24 * 3600).timeIntervalSince1970)
        return encode(#"{"alg":"none"}"#) + "." + encode(#"{"sub":"\#(studentId)","exp":\#(exp)}"#) + ".mock"
    }

    private static func profile(for studentId: String) -> UserProfile {
        var profile = studentId == "99999999" ? UserProfile.adminMock : UserProfile.mock
        profile.studentId = studentId
        profile.termsAgreed = isAgreed(studentId)
        return profile
    }

    /// `nil` unless `-mockAuth`.
    static func loginResponse(studentId: String) -> LoginResponse? {
        guard mocksAuth else { return nil }
        let agreed = isAgreed(studentId)
        print("[MockServer] POST /api/auth/login id=\(studentId) → termsAgreed=\(agreed)")
        return LoginResponse(accessToken: token(for: studentId), tokenType: "Bearer", memberInfo: nil, termsAgreed: agreed)
    }

    /// `nil` unless `-mockAuth`; throws for `-mockMeFails`.
    static func myProfileResponse() throws -> UserProfile? {
        guard mocksAuth else { return nil }
        let studentId = CyncAPI.accessToken.flatMap(JWT.subject) ?? "unknown"
        switch value(after: "-mockMeFails") {
        case "network":
            print("[MockServer] GET /api/me → offline")
            throw URLError(.notConnectedToInternet)
        case "unauthorized":
            print("[MockServer] GET /api/me → 401")
            throw CyncAPIError.unauthorized
        default:
            let profile = profile(for: studentId)
            print("[MockServer] GET /api/me id=\(studentId) → termsAgreed=\(profile.termsAgreed)")
            return profile
        }
    }

    /// `nil` unless `-mockAuth`; throws (500) for `-mockAgreeFails`.
    /// Takes a second, so the button's spinner shows.
    static func termsAgreementResponse() async throws -> UserProfile? {
        guard mocksAuth else { return nil }
        try? await Task.sleep(for: .seconds(1))
        let studentId = CyncAPI.accessToken.flatMap(JWT.subject) ?? "unknown"
        if arguments.contains("-mockAgreeFails") {
            print("[MockServer] POST /api/me/terms-agreement id=\(studentId) → 500")
            throw CyncAPIError.badStatus(500)
        }
        UserDefaults.standard.set(true, forKey: agreedKey(studentId))
        print("[MockServer] POST /api/me/terms-agreement id=\(studentId) → termsAgreed=true")
        return profile(for: studentId)
    }

    // MARK: - 사물함 (`-mockLockers`)

    static var mocksLockers: Bool { arguments.contains("-mockLockers") }
    static var lockerRole: String? { value(after: "-mockLockerRole") }
    static var opensAdminLocker: Bool { arguments.contains("-debugAdminLocker") }
    static var tapsReturnAll: Bool { arguments.contains("-debugReturnAll") }
    static var returnAllIncludesPending: Bool { arguments.contains("-debugReturnAllIncludePending") }
    static var executesReturnAll: Bool { arguments.contains("-debugReturnAllExecute") }
    static var opensLockerExpand: Bool { arguments.contains("-debugLockerExpand") }

    /// The mock's current lockers — changed by return-all.
    private static var mockLockers: [Locker] = makeMockLockers()

    private static func makeMockLockers() -> [Locker] {
        let zoneByNumber = LockerDataLoader.zoneIdByLockerNumber()
        let numbers = zoneByNumber.keys.sorted()
        let myNumber = numbers.first { zoneByNumber[$0] == "B203(1)" }
        let myState = value(after: "-mockMyLocker") ?? "pending"
        let rejected = arguments.contains("-mockLockerRejected")
        return numbers.map { number in
            if number == myNumber, myState != "none", !rejected {
                let inUse = myState == "inUse"
                return Locker(
                    id: number, lockerNumber: number, location: nil,
                    status: inUse ? .inUse : .pending, currentUserId: "20231234",
                    assignedAt: inUse ? "2026-09-08T10:00:00" : nil, dueDate: nil,
                    password: inUse ? "3847" : nil, mine: true
                )
            }
            let status: LockerStatus
            switch number % 10 {
            case 0: status = .broken
            case 3: status = .pending
            case 1, 4, 6, 8: status = .inUse
            default: status = .available
            }
            return Locker(
                id: number, lockerNumber: number, location: nil, status: status,
                currentUserId: status == .inUse || status == .pending ? String(format: "2201%04d", number) : nil,
                assignedAt: status == .inUse ? "2026-09-10T09:30:00" : nil, dueDate: nil,
                password: status == .inUse ? String(format: "%04d", number * 37 % 10000) : nil
            )
        }
    }

    /// `nil` unless `-mockLockers`.
    static func lockerResponse(path: String) -> [Locker]? {
        guard mocksLockers else { return nil }
        print("[MockServer] GET \(path)")
        switch path {
        case "/api/lockers/pending": return mockLockers.filter { $0.status == .pending }
        case "/api/lockers/in-use": return mockLockers.filter { $0.status == .inUse }
        default: return mockLockers
        }
    }

    /// `nil` unless `-mockLockers`. `confirm=false` only counts.
    static func returnAllResponse(confirm: Bool, includePending: Bool) -> ReturnAllResult? {
        guard mocksLockers else { return nil }
        print("[MockServer] POST /api/lockers/return-all confirm=\(confirm) includePending=\(includePending)")
        let targets = mockLockers.filter { $0.status == .inUse || (includePending && $0.status == .pending) }
        let numbers = targets.map(\.lockerNumber).sorted()
        if confirm {
            let ids = Set(targets.map(\.id))
            mockLockers = mockLockers.map { locker in
                guard ids.contains(locker.id) else { return locker }
                var returned = locker
                returned.status = .available
                returned.currentUserId = nil
                returned.password = nil
                returned.assignedAt = nil
                returned.mine = false
                return returned
            }
        }
        print("[MockServer] → executed=\(confirm) count=\(numbers.count)")
        return ReturnAllResult(executed: confirm, count: numbers.count, lockerNumbers: numbers)
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
