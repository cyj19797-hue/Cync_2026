//
//  Tracking.swift
//  Cync
//
//  Letter-spacing (자간) companion to `Typography.swift`. Every token now
//  shares one app-wide value, `Tracking.standard` (-0.4pt), regardless of
//  the token's point size — a deliberate choice to keep Korean text spacing
//  uniform across all screens (it used to be `size * -0.025` per token).
//  The per-token names are kept so call sites stay unchanged and a single
//  token can still diverge later if needed.
//
//  SwiftUI's `Font` type can't carry a tracking value itself — `.tracking(_:)`
//  is a separate `Text` modifier — so every `Text(...).font(.someToken)`
//  call site also chains `.tracking(Tracking.someToken)` right after it.
//  Shared components that take a configurable `font: Font` parameter
//  (`PrimaryActionButton`, `CheckboxToggle`) take a matching `tracking:`
//  parameter too.
//

import CoreGraphics

enum Tracking {
    /// App-wide letter spacing for all text.
    static let standard: CGFloat = -0.4

    static let noticeNavTitle: CGFloat = standard
    static let categoryChip: CGFloat = standard
    static let primaryButtonLabel: CGFloat = standard
    static let categoryFilterChipLabel: CGFloat = standard
    static let categoryBadge: CGFloat = standard
    static let noticeTitle: CGFloat = standard
    static let noticeDate: CGFloat = standard
    static let noticeDeadline: CGFloat = standard
    static let tabItemLabel: CGFloat = standard

    // MARK: - Shared navigation bar
    static let screenNavTitle: CGFloat = standard
    static let screenNavTitleCentered: CGFloat = standard

    // MARK: - "2-1 공지글" (notice detail)
    static let noticeDetailBackLabel: CGFloat = standard
    static let noticeDetailTitle: CGFloat = standard
    static let noticeDetailDate: CGFloat = standard
    static let noticeDetailBody: CGFloat = standard
    static let toggleTabLabel: CGFloat = standard
    static let remoteNavLabel: CGFloat = standard

    // MARK: - "3 캘린더" (calendar)
    static let calendarMonthLabel: CGFloat = standard
    static let calendarWeekdayLabel: CGFloat = standard
    static let calendarDayNumber: CGFloat = standard
    static let calendarCaption: CGFloat = standard
    static let calendarSectionTitle: CGFloat = standard
    static let calendarSectionSubtitle: CGFloat = standard
    static let emptyStateMessage: CGFloat = standard

    // MARK: - "4 사물함" (locker)
    static let myLockerTitle: CGFloat = standard
    static let lockerNumberLarge: CGFloat = standard
    static let lockerStatusBadge: CGFloat = standard
    static let lockerPeriodText: CGFloat = standard
    static let lockerLocationText: CGFloat = standard
    static let lockerCellNumber: CGFloat = standard
    static let lockerRoomLabel: CGFloat = standard
    static let lockerZoneButton: CGFloat = standard
    static let lockerCellStatus: CGFloat = standard

    // MARK: - Popup dialogs ("4-1-1 사물함 신청 팝업", "4-1-2 사물함 신청 팝업2")
    static let dialogTitle: CGFloat = standard
    static let dialogBody: CGFloat = standard

    // MARK: - "5 커뮤니티" (community)
    static let communityPostTitle: CGFloat = standard
    static let communityPostBody: CGFloat = standard
    static let communityReactionCount: CGFloat = standard
    static let communityRowTitle: CGFloat = standard
    static let communityRowPreview: CGFloat = standard
    static let communityRowMeta: CGFloat = standard

    // MARK: - "5-1 게시글" (post detail)
    static let postDetailTitle: CGFloat = standard
    static let communityPostDetailTitle: CGFloat = standard
    static let commentAuthor: CGFloat = standard
    static let commentsSectionTitle: CGFloat = standard
    static let commentReplyButton: CGFloat = standard

    // MARK: - "start" (launch screen)
    static let launchTagline: CGFloat = standard

    // MARK: - "1-3 앱 소개" (app intro)
    static let appIntroTitle: CGFloat = standard
    static let appIntroBody: CGFloat = standard

    // MARK: - "1-4 이용약관 동의" (terms agreement)
    static let termsAgreementTitle: CGFloat = standard
    static let termsAgreementSubtitle: CGFloat = standard
    static let termsItemLabel: CGFloat = standard
    static let termsAgreeAllLabel: CGFloat = standard
    static let termsButtonLabel: CGFloat = standard

    // MARK: - "1-5 로그인" (login)
    static let loginTitle: CGFloat = standard
    static let loginFieldLabel: CGFloat = standard
    static let loginFieldValue: CGFloat = standard
    static let loginCaption: CGFloat = standard
    static let loginButtonLabel: CGFloat = standard

    // MARK: - "6-2 Cync 공지" / "6-2-1 공지사항 내용"
    static let cyncNoticeRowTitle: CGFloat = standard
    static let cyncNoticeRowTitleRead: CGFloat = standard
    static let cyncNoticeDetailDate: CGFloat = standard
}
