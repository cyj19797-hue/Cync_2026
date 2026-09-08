//
//  Typography.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//

//  Figma uses the "Pretendard" family (Regular/Medium/SemiBold/Bold) across
//  the app's frames — a custom Korean typeface, not SF Pro.
//
//  NOTE (design deviation): SF Pro would give Dynamic Type / optical sizing
//  "for free", but Pretendard is the studio's chosen brand font for a
//  Korean-first app, so it is kept here. `.custom(_:size:relativeTo:)` is
//  used (not the plain `.custom(_:size:)` overload) so text still scales
//  with the user's Dynamic Type setting even though the family is custom.
//
//  TODO: Add the Pretendard .otf/.ttf files to the target and register them
//  under `Fonts provided by application` in Info.plist. Until the font files
//  are bundled, SwiftUI silently falls back to the system font, so the UI
//  keeps working (just without the intended typeface).
//

import SwiftUI

private enum PretendardWeight {
    case regular
    case medium
    case semibold
    case bold

    var fontName: String {
        switch self {
        case .regular: return "Pretendard-Regular"
        case .medium: return "Pretendard-Medium"
        case .semibold: return "Pretendard-SemiBold"
        case .bold: return "Pretendard-Bold"
        }
    }
}

private extension Font {
    static func pretendard(_ weight: PretendardWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom(weight.fontName, size: size, relativeTo: textStyle)
    }
}

extension Font {
    /// "공지사항" nav title, e.g. `I41:816;41:779` — Pretendard Bold 16.
    static let noticeNavTitle = Font.pretendard(.bold, size: 20, relativeTo: .headline)

    /// Shared button/field label size — Pretendard Medium 16. Also the base
    /// this file used for the "전체"/"학사"/… filter chip label until it was
    /// split out below (`.categoryFilterChipLabel`) at a smaller size.
    static let categoryChip = Font.pretendard(.medium, size: 16, relativeTo: .body)

    /// Category filter chip label ("전체", "학사", …) on "2 공지사항" /
    /// "3 캘린더" — Pretendard Regular 14. Deliberately smaller/lighter than
    /// `.noticeTitle` so the filter row doesn't visually compete with notice
    /// titles below it.
    static let categoryFilterChipLabel = Font.pretendard(.regular, size: 14, relativeTo: .subheadline)

    /// Small pink category badge inside a notice row — Pretendard Medium 14.
    static let categoryBadge = Font.pretendard(.medium, size: 14, relativeTo: .subheadline)

    /// Notice row title — Pretendard Bold 16.
    static let noticeTitle = Font.pretendard(.bold, size: 16, relativeTo: .body)

    /// Notice row date ("2026.08.18") — Pretendard Regular 14.
    static let noticeDate = Font.pretendard(.regular, size: 14, relativeTo: .subheadline)

    /// Notice row deadline ("마감 D-6") — Pretendard Bold 14.
    static let noticeDeadline = Font.pretendard(.bold, size: 14, relativeTo: .subheadline)

    /// Bottom tab bar item label — Pretendard Regular 14.
    static let tabItemLabel = Font.pretendard(.regular, size: 14, relativeTo: .caption)

    // MARK: - Shared navigation bar

    /// Custom back-button nav bar title (e.g. "6-1 알림 설정") — Pretendard
    /// Medium 15.
    ///
    /// NOTE (design deviation): Figma specifies `Inter Medium 15` for this
    /// label, same authoring slip as `.commentReplyButton` below — Pretendard
    /// is used here too for consistency with the rest of the app.
    static let screenNavTitle = Font.pretendard(.medium, size: 15, relativeTo: .subheadline)

    // MARK: - "2-1 공지글" (notice detail)

    /// "< 목록으로" back link — Pretendard Medium 14.
    static let noticeDetailBackLabel = Font.pretendard(.medium, size: 14, relativeTo: .subheadline)

    /// Detail screen notice title — Pretendard Bold 24.
    static let noticeDetailTitle = Font.pretendard(.bold, size: 24, relativeTo: .title)

    /// Detail screen date ("2026.08.07") — Pretendard Medium 14 (bolder
    /// weight than the list row's `.noticeDate`, matching the Figma spec).
    static let noticeDetailDate = Font.pretendard(.medium, size: 14, relativeTo: .subheadline)

    /// Notice body paragraphs — Pretendard Medium 16.
    static let noticeDetailBody = Font.pretendard(.medium, size: 16, relativeTo: .body)

    /// "원문" / "AI 번역" toggle label — Pretendard Medium 14.
    static let toggleTabLabel = Font.pretendard(.medium, size: 14, relativeTo: .subheadline)

    /// 이전 글 / 목록으로 / 다음 글 pill labels — Pretendard Medium 12.
    static let remoteNavLabel = Font.pretendard(.medium, size: 12, relativeTo: .caption2)

    // MARK: - "3 캘린더" (calendar)

    /// Month header ("2026년 8월") — Pretendard Regular 16.
    static let calendarMonthLabel = Font.pretendard(.regular, size: 16, relativeTo: .body)

    /// Weekday header row (일/월/화/…) — Pretendard Regular 12.
    static let calendarWeekdayLabel = Font.pretendard(.regular, size: 12, relativeTo: .caption2)

    /// Day-grid cell number — Pretendard Regular 14. Same visual spec as
    /// `.noticeDate`, kept as its own token since it labels an unrelated
    /// component (a calendar grid cell, not a notice row).
    static let calendarDayNumber = Font.pretendard(.regular, size: 14, relativeTo: .subheadline)

    /// Small 12px captions on the schedule card ("8월 10일 화요일", "전체 보기")
    /// — Pretendard Regular 12.
    static let calendarCaption = Font.pretendard(.regular, size: 12, relativeTo: .caption2)

    /// "등록된 일정이 없습니다." empty-state message — Pretendard Medium 16.
    /// (Figma: `361:2591` in "3-2 일정 전체보기(일정 없음)".)
    static let emptyStateMessage = Font.pretendard(.medium, size: 16, relativeTo: .body)

    // MARK: - "4 사물함" (locker)

    /// "나의 사물함" card title — Pretendard Bold 18.
    static let myLockerTitle = Font.pretendard(.bold, size: 18, relativeTo: .title3)

    /// The large "XXX번" locker number on the summary card — Pretendard Bold 32.
    static let lockerNumberLarge = Font.pretendard(.bold, size: 28, relativeTo: .largeTitle)

    /// "사용중" status pill on the summary card — Pretendard Bold 16.
    static let lockerStatusBadge = Font.pretendard(.bold, size: 16, relativeTo: .headline)

    /// "기간 : …" usage period line — Pretendard Regular 16.
    static let lockerPeriodText = Font.pretendard(.regular, size: 16, relativeTo: .body)

    /// "센B202 앞" location picker label — Pretendard Medium 12.
    static let lockerLocationText = Font.pretendard(.medium, size: 12, relativeTo: .caption2)

    /// Grid cell locker number ("7번") — Pretendard Bold 16.
    static let lockerCellNumber = Font.pretendard(.bold, size: 16, relativeTo: .subheadline)

    /// Grid cell status label ("사용 가능" / "사용 불가" / …) — Pretendard Regular 12.
    static let lockerCellStatus = Font.pretendard(.regular, size: 12, relativeTo: .caption2)

    // MARK: - Popup dialogs ("4-1-1 사물함 신청 팝업", "4-1-2 사물함 신청 팝업2")

    /// Dialog title ("계좌 안내") — Pretendard Bold 20.
    static let dialogTitle = Font.pretendard(.bold, size: 18, relativeTo: .title3)

    /// Dialog body copy — Pretendard Medium 16.
    static let dialogBody = Font.pretendard(.medium, size: 16, relativeTo: .body)

    // MARK: - "5 커뮤니티" (community)

    /// Post title ("제목입니다") — Pretendard SemiBold 20.
    static let communityPostTitle = Font.pretendard(.bold, size: 18, relativeTo: .title3)

    /// Post body preview (1-line clamp) — Pretendard Medium 16.
    static let communityPostBody = Font.pretendard(.medium, size: 16, relativeTo: .body)

    /// Like/comment count next to their icon — Pretendard SemiBold 14.
    static let communityReactionCount = Font.pretendard(.semibold, size: 14, relativeTo: .subheadline)

    // MARK: - "5-1 게시글" (post detail)

    /// Post detail title ("뿌릿 이햣 듀듀") — Pretendard Bold 20.
    static let postDetailTitle = Font.pretendard(.bold, size: 20, relativeTo: .title3)

    /// "익명" author name (post header + every comment) — Pretendard SemiBold 14.
    static let commentAuthor = Font.pretendard(.semibold, size: 14, relativeTo: .subheadline)

    /// "댓글" section title — Pretendard SemiBold 18.
    static let commentsSectionTitle = Font.pretendard(.semibold, size: 18, relativeTo: .title3)

    /// "답글 달기" reply button — Pretendard Medium 14.
    ///
    /// NOTE (design deviation): Figma's comment body/reply-button text uses
    /// `font-['Inter:Medium']`, not Pretendard, unlike every other text
    /// style in this file. That reads as an authoring slip (one stray text
    /// style in an otherwise all-Pretendard file) rather than an
    /// intentional font choice, so Pretendard is used here too for
    /// consistency with the rest of the app.
    static let commentReplyButton = Font.pretendard(.medium, size: 14, relativeTo: .subheadline)

    // MARK: - "1-5 로그인" (login)

    /// "로그인" card title — Pretendard Bold 32.
    static let loginTitle = Font.pretendard(.bold, size: 32, relativeTo: .largeTitle)

    /// "학번" / "비밀번호" field label — Pretendard Bold 18.
    static let loginFieldLabel = Font.pretendard(.bold, size: 18, relativeTo: .title3)

    /// Typed value inside the 학번/비밀번호 input boxes — Pretendard Medium 16.
    /// Not specified in Figma (the mock shows both fields empty), chosen to
    /// match other text-field values in the app (e.g. `ProfileEditSheet`'s
    /// nickname field).
    static let loginFieldValue = Font.pretendard(.medium, size: 16, relativeTo: .body)

    /// "비밀번호는 서버에 저장되지 않아요!" hint and "학번 기억하기" checkbox
    /// label — Pretendard Medium 12.
    static let loginCaption = Font.pretendard(.medium, size: 12, relativeTo: .caption2)

    /// "로그인" button label — Pretendard Bold 16. Kept separate from
    /// `.categoryChip` (Pretendard Medium 16, used by `PrimaryActionButton`'s
    /// default) since this button is specifically Bold in Figma.
    static let loginButtonLabel = Font.pretendard(.bold, size: 16, relativeTo: .headline)
}
