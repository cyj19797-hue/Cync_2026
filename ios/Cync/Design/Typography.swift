//
//  Typography.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//

//  Figma's frames were authored against "Pretendard" (Regular/Medium/
//  SemiBold/Bold), a custom Korean typeface, not SF Pro. The app now
//  intentionally uses Apple's system font everywhere instead — every token
//  below still keeps Figma's specified point size/weight/text-style pairing,
//  only the family changed. Unlike `.custom(_:size:relativeTo:)`,
//  `Font.system(size:weight:design:)` does NOT scale with Dynamic Type on
//  its own, so `appDefault` scales each Figma size through `UIFontMetrics`
//  for the token's `relativeTo` text style (body grows like body, captions
//  like captions). The tokens are computed (`static var`), not `static let`,
//  so they pick up the current 글자 크기 setting each time a view renders;
//  `RootTabView` also rebuilds its content when `dynamicTypeSize` changes
//  so a change made while the app is open shows up right away.
//
//  Figma's 18pt tokens are intentionally rendered at 17pt (the iOS
//  body/headline size) — their comments below still quote Figma's 18.
//

import SwiftUI
import UIKit

private enum AppFontWeight {
    case regular
    case medium
    case semibold
    case bold

    var systemWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

private extension Font {
    static func appDefault(_ weight: AppFontWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        let scaledSize = UIFontMetrics(forTextStyle: textStyle.uiTextStyle).scaledValue(for: size)
        return .system(size: scaledSize, weight: weight.systemWeight, design: .default)
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}

extension Font {
    /// "공지사항" nav title, e.g. `I41:816;41:779` — Pretendard Bold 16.
    static var noticeNavTitle: Font { .appDefault(.bold, size: 20, relativeTo: .headline) }

    /// Shared button/field label size — Pretendard Medium 16. Also the base
    /// this file used for the "전체"/"학사"/… filter chip label until it was
    /// split out below (`.categoryFilterChipLabel`) at a smaller size.
    static var categoryChip: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    /// `PrimaryActionButton` label — iOS 기본 주요 버튼 크기(17pt SemiBold)를
    /// 따른다. 앱의 모든 주요 버튼이 이 토큰을 공유한다.
    static var primaryButtonLabel: Font { .appDefault(.semibold, size: 17, relativeTo: .body) }

    /// Category filter chip label ("전체", "학사", …) on "2 공지사항" /
    /// "3 캘린더" — Pretendard Regular 14. Deliberately smaller/lighter than
    /// `.noticeTitle` so the filter row doesn't visually compete with notice
    /// titles below it.
    static var categoryFilterChipLabel: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }

    /// Small pink category badge inside a notice row — Pretendard Medium 14.
    static var categoryBadge: Font { .appDefault(.medium, size: 14, relativeTo: .body) }

    /// Notice row title — Pretendard Bold 16.
    static var noticeTitle: Font { .appDefault(.bold, size: 16, relativeTo: .body) }

    /// "알림 설정" section titles and "전체 알림" — Pretendard Bold 18, a
    /// step above the 17pt rows under them.
    static var settingSectionTitle: Font { .appDefault(.bold, size: 18, relativeTo: .title3) }

    /// "알림 설정" row title (마감 임박 알림 …) — Pretendard Medium 17.
    static var settingRowTitle: Font { .appDefault(.medium, size: 17, relativeTo: .body) }

    /// "알림 설정" row description and value — Pretendard Regular 14.
    static var settingRowSubtitle: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }

    /// Notice row date ("2026.08.18") — Pretendard Regular 14.
    static var noticeDate: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }

    /// Notice row deadline ("마감 D-6") — Pretendard Bold 14.
    static var noticeDeadline: Font { .appDefault(.bold, size: 14, relativeTo: .subheadline) }

    /// Bottom tab bar item label — Pretendard Regular 14.
    static var tabItemLabel: Font { .appDefault(.regular, size: 14, relativeTo: .caption) }

    // MARK: - Shared navigation bar

    /// Custom back-button nav bar title (e.g. "6-1 알림 설정") — Pretendard
    /// Medium 15.
    ///
    /// NOTE (design deviation): Figma specifies `Inter Medium 15` for this
    /// label, same authoring slip as `.commentReplyButton` below — Pretendard
    /// is used here too for consistency with the rest of the app.
    static var screenNavTitle: Font { .appDefault(.medium, size: 15, relativeTo: .subheadline) }

    // MARK: - "2-1 공지글" (notice detail)

    /// "< 목록으로" back link — Pretendard Medium 14.
    static var noticeDetailBackLabel: Font { .appDefault(.medium, size: 14, relativeTo: .subheadline) }

    /// Detail screen notice title — Pretendard Bold 24.
    static var noticeDetailTitle: Font { .appDefault(.bold, size: 24, relativeTo: .title) }

    /// Detail screen date ("2026.08.07") — Pretendard Medium 14 (bolder
    /// weight than the list row's `.noticeDate`, matching the Figma spec).
    static var noticeDetailDate: Font { .appDefault(.medium, size: 14, relativeTo: .subheadline) }

    /// Notice body paragraphs — Pretendard Medium 16.
    static var noticeDetailBody: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    /// "원문" / "AI 번역" toggle label — Pretendard Medium 14.
    static var toggleTabLabel: Font { .appDefault(.medium, size: 14, relativeTo: .subheadline) }

    /// 이전 글 / 목록으로 / 다음 글 pill labels — Pretendard Medium 12.
    static var remoteNavLabel: Font { .appDefault(.medium, size: 12, relativeTo: .caption2) }

    // MARK: - "3 캘린더" (calendar)

    /// Month header ("2026년 8월") — Pretendard Regular 16.
    static var calendarMonthLabel: Font { .appDefault(.regular, size: 16, relativeTo: .body) }

    /// Weekday header row (일/월/화/…) — Pretendard Regular 12.
    static var calendarWeekdayLabel: Font { .appDefault(.regular, size: 12, relativeTo: .caption2) }

    /// Day-grid cell number — Pretendard Regular 14. Same visual spec as
    /// `.noticeDate`, kept as its own token since it labels an unrelated
    /// component (a calendar grid cell, not a notice row).
    static var calendarDayNumber: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }

    /// Small 12px captions — the "오늘" pill, the "9월 전체 일정" link and the
    /// month list's holiday names — Pretendard Regular 12.
    static var calendarCaption: Font { .appDefault(.regular, size: 12, relativeTo: .caption2) }

    /// "등록된 일정" card title and the month list's per-day headers — Bold 17, one step above the 16 Bold event
    /// titles (`.noticeTitle`) listed under it so the header reads as a
    /// section title rather than another row.
    static var calendarSectionTitle: Font { .appDefault(.bold, size: 17, relativeTo: .headline) }

    /// Selected date ("9월 25일 (금)") and holiday name next to
    /// `calendarSectionTitle` — Regular 14.
    static var calendarSectionSubtitle: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }

    /// "이 날은 일정이 없어요." empty-state message — Regular 14 (Figma
    /// `361:2591` had Medium 16; reduced so it reads as a secondary note
    /// under the 17 Bold section header rather than competing with it).
    static var emptyStateMessage: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }

    // MARK: - Shared components

    /// Centered title of `ScreenNavigationBar`'s `.centered` style (e.g.
    /// "월별 일정") — Semibold 17, matching the iOS navigation bar title.
    static var screenNavTitleCentered: Font { .appDefault(.semibold, size: 17, relativeTo: .headline) }

    /// Filled text button in a screen header (글쓰기 "등록") — Pretendard
    /// SemiBold 15.
    static var headerActionButton: Font { .appDefault(.semibold, size: 15, relativeTo: .subheadline) }

    /// `NavigationChevron` SF Symbol ("<" / ">") — Semibold 14.
    static var navigationChevron: Font { .appDefault(.semibold, size: 14, relativeTo: .subheadline) }

    // MARK: - "4 사물함" (locker)

    /// "나의 사물함" card title — Pretendard Bold 18.
    static var myLockerTitle: Font { .appDefault(.bold, size: 17, relativeTo: .title3) }

    /// The large "XXX번" locker number on the summary card — Pretendard Bold 32.
    static var lockerNumberLarge: Font { .appDefault(.bold, size: 28, relativeTo: .largeTitle) }

    /// "사용중" status pill on the summary card — Pretendard Bold 16.
    static var lockerStatusBadge: Font { .appDefault(.bold, size: 16, relativeTo: .headline) }

    /// "기간 : …" usage period line — Pretendard Regular 16.
    static var lockerPeriodText: Font { .appDefault(.regular, size: 16, relativeTo: .body) }

    /// "센B202 앞" location picker label — Pretendard Medium 12.
    static var lockerLocationText: Font { .appDefault(.medium, size: 12, relativeTo: .caption2) }

    /// Room ("B201") after MyLockerCard's big locker number — Medium 14 in
    /// a light gray, so the number itself stays the focus.
    static var lockerRoomLabel: Font { .appDefault(.medium, size: 14, relativeTo: .subheadline) }

    /// Room button inside the map card ("B201 ⌄") — Medium 13.
    static var lockerZoneButton: Font { .appDefault(.medium, size: 13, relativeTo: .footnote) }

    /// Grid cell locker number ("7번") — Pretendard Bold 16.
    static var lockerCellNumber: Font { .appDefault(.bold, size: 16, relativeTo: .subheadline) }

    /// Grid cell status label ("사용 가능" / "사용 불가" / …) — Pretendard Regular 12.
    static var lockerCellStatus: Font { .appDefault(.regular, size: 12, relativeTo: .caption2) }

    // MARK: - Popup dialogs ("4-1-1 사물함 신청 팝업", "4-1-2 사물함 신청 팝업2")

    /// Dialog title ("계좌 안내") — Pretendard Bold 20.
    static var dialogTitle: Font { .appDefault(.bold, size: 17, relativeTo: .title3) }

    /// Dialog body copy — Pretendard Medium 16.
    static var dialogBody: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    // MARK: - "5 커뮤니티" (community)

    /// Post title ("제목입니다") — Pretendard SemiBold 20.
    static var communityPostTitle: Font { .appDefault(.bold, size: 17, relativeTo: .title3) }

    /// Post body preview (1-line clamp) — Pretendard Medium 16.
    static var communityPostBody: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    /// Like/comment count next to their icon — Pretendard SemiBold 16.
    static var communityReactionCount: Font { .appDefault(.semibold, size: 16, relativeTo: .body) }

    /// Feed-row title (`CommunityPostRow`) — Pretendard Bold 16, same as the
    /// notice list's `.noticeTitle` so both feeds share one title size.
    /// Separate from `.communityPostTitle`, which other screens still use.
    static var communityRowTitle: Font { .appDefault(.bold, size: 16, relativeTo: .body) }

    /// Feed-row body preview (2-line clamp) — Pretendard Regular 14, a step
    /// below the title so the preview reads as secondary.
    static var communityRowPreview: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }

    /// Feed-row meta line ("3분 전 • 💬 2 ♡ 5") — Pretendard Regular 13.
    static var communityRowMeta: Font { .appDefault(.regular, size: 13, relativeTo: .footnote) }

    // MARK: - "5-1 게시글" (post detail)

    /// Post detail title ("뿌릿 이햣 듀듀") — Pretendard Bold 20.
    /// "5-1 게시글" post title — Bold 18, a step under `.postDetailTitle`
    /// (20) so the title doesn't overpower the body right below it.
    static var communityPostDetailTitle: Font { .appDefault(.bold, size: 18, relativeTo: .headline) }

    static var postDetailTitle: Font { .appDefault(.bold, size: 20, relativeTo: .title3) }

    /// "익명" author name (post header + every comment) — Pretendard SemiBold 16.
    static var commentAuthor: Font { .appDefault(.semibold, size: 16, relativeTo: .body) }

    /// "댓글" section title — Pretendard SemiBold 18.
    static var commentsSectionTitle: Font { .appDefault(.semibold, size: 17, relativeTo: .title3) }

    /// "답글 달기" reply button — Pretendard Medium 14.
    ///
    /// NOTE (design deviation): Figma's comment body/reply-button text uses
    /// `font-['Inter:Medium']`, not Pretendard, unlike every other text
    /// style in this file. That reads as an authoring slip (one stray text
    /// style in an otherwise all-Pretendard file) rather than an
    /// intentional font choice, so Pretendard is used here too for
    /// consistency with the rest of the app.
    static var commentReplyButton: Font { .appDefault(.medium, size: 14, relativeTo: .subheadline) }

    // MARK: - "start" (launch screen)

    /// "Campus, in Cync" tagline under the logo — Pretendard Medium 16.
    ///
    /// NOTE (design deviation): Figma specifies `Inter Medium 16` here, same
    /// authoring slip as `.commentReplyButton`/`.screenNavTitle` above —
    /// Pretendard is used instead for consistency with the rest of the app.
    static var launchTagline: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    // MARK: - "1-3 앱 소개" (app intro)

    /// "학과 생활을 하나로 연결하다," headline — Pretendard Bold 24.
    static var appIntroTitle: Font { .appDefault(.bold, size: 24, relativeTo: .title2) }

    /// Two-line body copy under the headline — Pretendard Medium 16.
    static var appIntroBody: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    // MARK: - "1-4 이용약관 동의" (terms agreement)

    /// "Cync를 시작하기 전에, ..." headline — Pretendard Bold 28.
    static var termsAgreementTitle: Font { .appDefault(.bold, size: 28, relativeTo: .largeTitle) }

    /// Sub-headline under the title — Pretendard Medium 16.
    static var termsAgreementSubtitle: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    /// "[필수] 이용약관" / "[선택] 중요한 학과 소식 알림" item row label —
    /// Pretendard Medium 18.
    static var termsItemLabel: Font { .appDefault(.medium, size: 17, relativeTo: .title3) }

    /// "전체 동의" label — Pretendard Medium 16.
    static var termsAgreeAllLabel: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    /// "👉 세종대학교 계정으로 시작하기" button label — Pretendard Bold 18.
    static var termsButtonLabel: Font { .appDefault(.bold, size: 17, relativeTo: .title3) }

    // MARK: - "1-5 로그인" (login)

    /// "세종대학교 계정으로 로그인" card heading — Bold 20 (Figma had a Bold 32
    /// "로그인" in the accent color, which outweighed the logo and repeated
    /// the button's label).
    static var loginTitle: Font { .appDefault(.bold, size: 20, relativeTo: .title3) }

    /// "학번" / "비밀번호" field label — Pretendard Bold 18.
    static var loginFieldLabel: Font { .appDefault(.bold, size: 17, relativeTo: .title3) }

    /// Typed value inside the 학번/비밀번호 input boxes — Pretendard Medium 16.
    /// Not specified in Figma (the mock shows both fields empty), chosen to
    /// match other text-field values in the app (e.g. `ProfileEditSheet`'s
    /// nickname field).
    static var loginFieldValue: Font { .appDefault(.medium, size: 16, relativeTo: .body) }

    /// "비밀번호는 서버에 저장되지 않아요!" helper text under the password
    /// field — Regular 13 (Figma: Medium 12 beside the label, which crowded
    /// the label's line and was hard to read).
    static var loginCaption: Font { .appDefault(.regular, size: 13, relativeTo: .footnote) }

    /// "로그인" button label — Pretendard Bold 16. Kept separate from
    /// `.categoryChip` (Pretendard Medium 16, used by `PrimaryActionButton`'s
    /// default) since this button is specifically Bold in Figma.
    static var loginButtonLabel: Font { .appDefault(.bold, size: 16, relativeTo: .headline) }

    // MARK: - "6-2 Cync 공지" / "6-2-1 공지사항 내용"

    /// "Cync 공지" list row title, unread — Bold 16, the same as the 공지사항
    /// tab's row title (`.noticeTitle`) so the two boards' lists read at the
    /// same size (Figma's SemiBold 20 looked oversized next to it). Read rows
    /// drop to `.cyncNoticeRowTitleRead`.
    static var cyncNoticeRowTitle: Font { .appDefault(.bold, size: 16, relativeTo: .body) }

    /// "Cync 공지" row title once the notice has been opened — same size as
    /// `.cyncNoticeRowTitle`, Regular instead of Bold, so read/unread
    /// differ by weight (plus the unread dot) without the row jumping.
    static var cyncNoticeRowTitleRead: Font { .appDefault(.regular, size: 16, relativeTo: .body) }

    /// "Cync 공지" detail date ("2026.03.05") — Regular 14 (Figma had
    /// SemiBold) so it reads as meta info under the title, not as a heading.
    /// The detail title itself reuses `.postDetailTitle` (Pretendard Bold
    /// 20), which happens to match this frame's title spec exactly.
    static var cyncNoticeDetailDate: Font { .appDefault(.regular, size: 14, relativeTo: .subheadline) }
}
