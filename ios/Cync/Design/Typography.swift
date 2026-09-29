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
//  only the family changed. `Font.system(size:weight:design:)` scales with
//  the user's Dynamic Type setting the same way `.custom(_:size:relativeTo:)`
//  did, so no call site (any `Font.appDefault(...)` below) needed to change
//  its arguments — only this helper's implementation did. `relativeTo` is
//  kept as a parameter purely for documentation (it records which Figma
//  text-style role each token plays) even though the system font doesn't
//  need it to scale.
//

import SwiftUI

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
    static func appDefault(_ weight: AppFontWeight, size: CGFloat, relativeTo _: Font.TextStyle) -> Font {
        .system(size: size, weight: weight.systemWeight, design: .default)
    }
}

extension Font {
    /// "공지사항" nav title, e.g. `I41:816;41:779` — Pretendard Bold 16.
    static let noticeNavTitle = Font.appDefault(.bold, size: 20, relativeTo: .headline)

    /// Shared button/field label size — Pretendard Medium 16. Also the base
    /// this file used for the "전체"/"학사"/… filter chip label until it was
    /// split out below (`.categoryFilterChipLabel`) at a smaller size.
    static let categoryChip = Font.appDefault(.medium, size: 16, relativeTo: .body)

    /// Category filter chip label ("전체", "학사", …) on "2 공지사항" /
    /// "3 캘린더" — Pretendard Regular 14. Deliberately smaller/lighter than
    /// `.noticeTitle` so the filter row doesn't visually compete with notice
    /// titles below it.
    static let categoryFilterChipLabel = Font.appDefault(.regular, size: 14, relativeTo: .subheadline)

    /// Small pink category badge inside a notice row — Pretendard Medium 14.
    static let categoryBadge = Font.appDefault(.medium, size: 14, relativeTo: .body)

    /// Notice row title — Pretendard Bold 16.
    static let noticeTitle = Font.appDefault(.bold, size: 16, relativeTo: .body)

    /// Notice row date ("2026.08.18") — Pretendard Regular 14.
    static let noticeDate = Font.appDefault(.regular, size: 14, relativeTo: .subheadline)

    /// Notice row deadline ("마감 D-6") — Pretendard Bold 14.
    static let noticeDeadline = Font.appDefault(.bold, size: 14, relativeTo: .subheadline)

    /// Bottom tab bar item label — Pretendard Regular 14.
    static let tabItemLabel = Font.appDefault(.regular, size: 14, relativeTo: .caption)

    // MARK: - Shared navigation bar

    /// Custom back-button nav bar title (e.g. "6-1 알림 설정") — Pretendard
    /// Medium 15.
    ///
    /// NOTE (design deviation): Figma specifies `Inter Medium 15` for this
    /// label, same authoring slip as `.commentReplyButton` below — Pretendard
    /// is used here too for consistency with the rest of the app.
    static let screenNavTitle = Font.appDefault(.medium, size: 15, relativeTo: .subheadline)

    // MARK: - "2-1 공지글" (notice detail)

    /// "< 목록으로" back link — Pretendard Medium 14.
    static let noticeDetailBackLabel = Font.appDefault(.medium, size: 14, relativeTo: .subheadline)

    /// Detail screen notice title — Pretendard Bold 24.
    static let noticeDetailTitle = Font.appDefault(.bold, size: 24, relativeTo: .title)

    /// Detail screen date ("2026.08.07") — Pretendard Medium 14 (bolder
    /// weight than the list row's `.noticeDate`, matching the Figma spec).
    static let noticeDetailDate = Font.appDefault(.medium, size: 14, relativeTo: .subheadline)

    /// Notice body paragraphs — Pretendard Medium 16.
    static let noticeDetailBody = Font.appDefault(.medium, size: 16, relativeTo: .body)

    /// "원문" / "AI 번역" toggle label — Pretendard Medium 14.
    static let toggleTabLabel = Font.appDefault(.medium, size: 14, relativeTo: .subheadline)

    /// 이전 글 / 목록으로 / 다음 글 pill labels — Pretendard Medium 12.
    static let remoteNavLabel = Font.appDefault(.medium, size: 12, relativeTo: .caption2)

    // MARK: - "3 캘린더" (calendar)

    /// Month header ("2026년 8월") — Pretendard Regular 16.
    static let calendarMonthLabel = Font.appDefault(.regular, size: 16, relativeTo: .body)

    /// Weekday header row (일/월/화/…) — Pretendard Regular 12.
    static let calendarWeekdayLabel = Font.appDefault(.regular, size: 12, relativeTo: .caption2)

    /// Day-grid cell number — Pretendard Regular 14. Same visual spec as
    /// `.noticeDate`, kept as its own token since it labels an unrelated
    /// component (a calendar grid cell, not a notice row).
    static let calendarDayNumber = Font.appDefault(.regular, size: 14, relativeTo: .subheadline)

    /// Small 12px captions on the schedule card ("8월 10일 화요일", "전체 보기")
    /// — Pretendard Regular 12.
    static let calendarCaption = Font.appDefault(.regular, size: 12, relativeTo: .caption2)

    /// "등록된 일정이 없습니다." empty-state message — Pretendard Medium 16.
    /// (Figma: `361:2591` in "3-2 일정 전체보기(일정 없음)".)
    static let emptyStateMessage = Font.appDefault(.medium, size: 16, relativeTo: .body)

    // MARK: - "4 사물함" (locker)

    /// "나의 사물함" card title — Pretendard Bold 18.
    static let myLockerTitle = Font.appDefault(.bold, size: 18, relativeTo: .title3)

    /// The large "XXX번" locker number on the summary card — Pretendard Bold 32.
    static let lockerNumberLarge = Font.appDefault(.bold, size: 28, relativeTo: .largeTitle)

    /// "사용중" status pill on the summary card — Pretendard Bold 16.
    static let lockerStatusBadge = Font.appDefault(.bold, size: 16, relativeTo: .headline)

    /// "기간 : …" usage period line — Pretendard Regular 16.
    static let lockerPeriodText = Font.appDefault(.regular, size: 16, relativeTo: .body)

    /// "센B202 앞" location picker label — Pretendard Medium 12.
    static let lockerLocationText = Font.appDefault(.medium, size: 12, relativeTo: .caption2)

    /// Grid cell locker number ("7번") — Pretendard Bold 16.
    static let lockerCellNumber = Font.appDefault(.bold, size: 16, relativeTo: .subheadline)

    /// Grid cell status label ("사용 가능" / "사용 불가" / …) — Pretendard Regular 12.
    static let lockerCellStatus = Font.appDefault(.regular, size: 12, relativeTo: .caption2)

    // MARK: - Popup dialogs ("4-1-1 사물함 신청 팝업", "4-1-2 사물함 신청 팝업2")

    /// Dialog title ("계좌 안내") — Pretendard Bold 20.
    static let dialogTitle = Font.appDefault(.bold, size: 18, relativeTo: .title3)

    /// Dialog body copy — Pretendard Medium 16.
    static let dialogBody = Font.appDefault(.medium, size: 16, relativeTo: .body)

    // MARK: - "5 커뮤니티" (community)

    /// Post title ("제목입니다") — Pretendard SemiBold 20.
    static let communityPostTitle = Font.appDefault(.bold, size: 18, relativeTo: .title3)

    /// Post body preview (1-line clamp) — Pretendard Medium 16.
    static let communityPostBody = Font.appDefault(.medium, size: 16, relativeTo: .body)

    /// Like/comment count next to their icon — Pretendard SemiBold 14.
    static let communityReactionCount = Font.appDefault(.semibold, size: 14, relativeTo: .subheadline)

    // MARK: - "5-1 게시글" (post detail)

    /// Post detail title ("뿌릿 이햣 듀듀") — Pretendard Bold 20.
    static let postDetailTitle = Font.appDefault(.bold, size: 20, relativeTo: .title3)

    /// "익명" author name (post header + every comment) — Pretendard SemiBold 14.
    static let commentAuthor = Font.appDefault(.semibold, size: 14, relativeTo: .subheadline)

    /// "댓글" section title — Pretendard SemiBold 18.
    static let commentsSectionTitle = Font.appDefault(.semibold, size: 18, relativeTo: .title3)

    /// "답글 달기" reply button — Pretendard Medium 14.
    ///
    /// NOTE (design deviation): Figma's comment body/reply-button text uses
    /// `font-['Inter:Medium']`, not Pretendard, unlike every other text
    /// style in this file. That reads as an authoring slip (one stray text
    /// style in an otherwise all-Pretendard file) rather than an
    /// intentional font choice, so Pretendard is used here too for
    /// consistency with the rest of the app.
    static let commentReplyButton = Font.appDefault(.medium, size: 14, relativeTo: .subheadline)

    // MARK: - "start" (launch screen)

    /// "Campus, in Cync" tagline under the logo — Pretendard Medium 16.
    ///
    /// NOTE (design deviation): Figma specifies `Inter Medium 16` here, same
    /// authoring slip as `.commentReplyButton`/`.screenNavTitle` above —
    /// Pretendard is used instead for consistency with the rest of the app.
    static let launchTagline = Font.appDefault(.medium, size: 16, relativeTo: .body)

    // MARK: - "1-3 앱 소개" (app intro)

    /// "학과 생활을 하나로 연결하다," headline — Pretendard Bold 24.
    static let appIntroTitle = Font.appDefault(.bold, size: 24, relativeTo: .title2)

    /// Two-line body copy under the headline — Pretendard Medium 16.
    static let appIntroBody = Font.appDefault(.medium, size: 16, relativeTo: .body)

    // MARK: - "1-4 이용약관 동의" (terms agreement)

    /// "Cync를 시작하기 전에, ..." headline — Pretendard Bold 28.
    static let termsAgreementTitle = Font.appDefault(.bold, size: 28, relativeTo: .largeTitle)

    /// Sub-headline under the title — Pretendard Medium 16.
    static let termsAgreementSubtitle = Font.appDefault(.medium, size: 16, relativeTo: .body)

    /// "[필수] 이용약관" / "[선택] 중요한 학과 소식 알림" item row label —
    /// Pretendard Medium 18.
    static let termsItemLabel = Font.appDefault(.medium, size: 18, relativeTo: .title3)

    /// "전체 동의" label — Pretendard Medium 16.
    static let termsAgreeAllLabel = Font.appDefault(.medium, size: 16, relativeTo: .body)

    /// "👉 세종대학교 계정으로 시작하기" button label — Pretendard Bold 18.
    static let termsButtonLabel = Font.appDefault(.bold, size: 18, relativeTo: .title3)

    // MARK: - "1-5 로그인" (login)

    /// "로그인" card title — Pretendard Bold 32.
    static let loginTitle = Font.appDefault(.bold, size: 32, relativeTo: .largeTitle)

    /// "학번" / "비밀번호" field label — Pretendard Bold 18.
    static let loginFieldLabel = Font.appDefault(.bold, size: 18, relativeTo: .title3)

    /// Typed value inside the 학번/비밀번호 input boxes — Pretendard Medium 16.
    /// Not specified in Figma (the mock shows both fields empty), chosen to
    /// match other text-field values in the app (e.g. `ProfileEditSheet`'s
    /// nickname field).
    static let loginFieldValue = Font.appDefault(.medium, size: 16, relativeTo: .body)

    /// "비밀번호는 서버에 저장되지 않아요!" hint and "학번 기억하기" checkbox
    /// label — Pretendard Medium 12.
    static let loginCaption = Font.appDefault(.medium, size: 12, relativeTo: .caption2)

    /// "로그인" button label — Pretendard Bold 16. Kept separate from
    /// `.categoryChip` (Pretendard Medium 16, used by `PrimaryActionButton`'s
    /// default) since this button is specifically Bold in Figma.
    static let loginButtonLabel = Font.appDefault(.bold, size: 16, relativeTo: .headline)

    // MARK: - "6-2 Cync 공지" / "6-2-1 공지사항 내용"

    /// "Cync 공지" list row title — Pretendard SemiBold 20. Note the school
    /// notice board's `.noticeTitle` (Bold 16) doesn't apply here — this
    /// board's Figma row uses a distinctly larger/lighter-weight style.
    static let cyncNoticeRowTitle = Font.appDefault(.semibold, size: 20, relativeTo: .title3)

    /// "Cync 공지" detail date ("2026.03.05") — Pretendard SemiBold 14.
    /// The detail title itself reuses `.postDetailTitle` (Pretendard Bold
    /// 20), which happens to match this frame's title spec exactly.
    static let cyncNoticeDetailDate = Font.appDefault(.semibold, size: 14, relativeTo: .subheadline)
}
