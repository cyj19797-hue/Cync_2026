//
//  Tracking.swift
//  Cync
//
//  Letter-spacing (자간) companion to `Typography.swift` — every value here
//  is exactly `-2.5%` of that token's own point size (e.g. `noticeTitle` is
//  16pt, so `Tracking.noticeTitle` is `16 * -0.025 = -0.4`).
//
//  SwiftUI's `Font` type can't carry a tracking value itself — `.tracking(_:)`
//  is a separate `Text` modifier that takes an absolute point offset, not a
//  percentage — so this can't be folded into `Font.appDefault(...)`. Instead,
//  every `Text(...).font(.someToken)` call site in the app also chains
//  `.tracking(Tracking.someToken)` right after it. A handful of shared
//  components that take a configurable `font: Font` parameter instead
//  (`PrimaryActionButton`, `CheckboxToggle`) take a matching `tracking:
//  CGFloat` parameter too, defaulting to the tracking for that component's
//  own default font, so callers that don't override `font:` still get the
//  correct tracking automatically.
//
//  NOTE: these values are derived from `Typography.swift`'s `size:`
//  arguments and won't update automatically if a token's size ever changes
//  there — regenerate the matching entry here by hand (`size * -0.025`) if
//  you change a token's point size.
//

import CoreGraphics

enum Tracking {
    static let noticeNavTitle: CGFloat = -0.5
    static let categoryChip: CGFloat = -0.4
    static let categoryFilterChipLabel: CGFloat = -0.35
    static let categoryBadge: CGFloat = -0.35
    static let noticeTitle: CGFloat = -0.4
    static let noticeDate: CGFloat = -0.35
    static let noticeDeadline: CGFloat = -0.35
    static let tabItemLabel: CGFloat = -0.35

    // MARK: - Shared navigation bar
    static let screenNavTitle: CGFloat = -0.375

    // MARK: - "2-1 공지글" (notice detail)
    static let noticeDetailBackLabel: CGFloat = -0.35
    static let noticeDetailTitle: CGFloat = -0.6
    static let noticeDetailDate: CGFloat = -0.35
    static let noticeDetailBody: CGFloat = -0.4
    static let toggleTabLabel: CGFloat = -0.35
    static let remoteNavLabel: CGFloat = -0.3

    // MARK: - "3 캘린더" (calendar)
    static let calendarMonthLabel: CGFloat = -0.4
    static let calendarWeekdayLabel: CGFloat = -0.3
    static let calendarDayNumber: CGFloat = -0.35
    static let calendarCaption: CGFloat = -0.3
    static let emptyStateMessage: CGFloat = -0.4

    // MARK: - "4 사물함" (locker)
    static let myLockerTitle: CGFloat = -0.45
    static let lockerNumberLarge: CGFloat = -0.7
    static let lockerStatusBadge: CGFloat = -0.4
    static let lockerPeriodText: CGFloat = -0.4
    static let lockerLocationText: CGFloat = -0.3
    static let lockerCellNumber: CGFloat = -0.4
    static let lockerCellStatus: CGFloat = -0.3

    // MARK: - Popup dialogs ("4-1-1 사물함 신청 팝업", "4-1-2 사물함 신청 팝업2")
    static let dialogTitle: CGFloat = -0.45
    static let dialogBody: CGFloat = -0.4

    // MARK: - "5 커뮤니티" (community)
    static let communityPostTitle: CGFloat = -0.45
    static let communityPostBody: CGFloat = -0.4
    static let communityReactionCount: CGFloat = -0.35

    // MARK: - "5-1 게시글" (post detail)
    static let postDetailTitle: CGFloat = -0.5
    static let commentAuthor: CGFloat = -0.35
    static let commentsSectionTitle: CGFloat = -0.45
    static let commentReplyButton: CGFloat = -0.35

    // MARK: - "start" (launch screen)
    static let launchTagline: CGFloat = -0.4

    // MARK: - "1-3 앱 소개" (app intro)
    static let appIntroTitle: CGFloat = -0.6
    static let appIntroBody: CGFloat = -0.4

    // MARK: - "1-4 이용약관 동의" (terms agreement)
    static let termsAgreementTitle: CGFloat = -0.7
    static let termsAgreementSubtitle: CGFloat = -0.4
    static let termsItemLabel: CGFloat = -0.45
    static let termsAgreeAllLabel: CGFloat = -0.4
    static let termsButtonLabel: CGFloat = -0.45

    // MARK: - "1-5 로그인" (login)
    static let loginTitle: CGFloat = -0.8
    static let loginFieldLabel: CGFloat = -0.45
    static let loginFieldValue: CGFloat = -0.4
    static let loginCaption: CGFloat = -0.3
    static let loginButtonLabel: CGFloat = -0.4

    // MARK: - "6-2 Cync 공지" / "6-2-1 공지사항 내용"
    static let cyncNoticeRowTitle: CGFloat = -0.5
    static let cyncNoticeDetailDate: CGFloat = -0.35
}
