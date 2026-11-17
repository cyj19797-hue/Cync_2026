//
//  Colors.swift
//  test
//
//  Design tokens extracted from Figma (26-2-창학 file, "2 공지사항" frame).
//

import SwiftUI

extension Color {
    /// Figma style: `category` (#3982FF) — the accent bar on each
    /// "등록된 일정" row and (reused) the per-day event dot in the grid.
    /// Also doubles as the Figma style `primary` (#36AFFF) used on "1-2 언어
    /// 선택"'s "계속하기" button and "1-5 로그인"'s title/button — same hex,
    /// different style name depending on which frame defined it.
    static let eventAccent = Color(hex: 0x36AFFF)

    /// Figma style: `primary_dark` (#174B6D) — border of the checked
    /// "학번 기억하기" checkbox on "1-5 로그인".
    static let eventAccentDark = Color(hex: 0x174B6D)

    /// Asset catalog color `AccentColorLight` — light tint of `eventAccent`
    /// behind the "today" number in the calendar grid. Kept as an asset
    /// catalog reference (not a `Color(hex:)` literal like the rest of this
    /// file) so it stays in sync with the display-P3 value set in Xcode.
    static let eventAccentLight = Color(hex: 0x8DD1FF)

    /// Figma #E8F6FF — palest `eventAccent` tint: the icon circle on the
    /// app-launch popup notice card.
    static let eventAccentTint = Color(hex: 0xE8F6FF)

    /// Figma #F7F8FA — a hair off white: the "1 / 2" order pill on the
    /// app-launch popup notice card.
    static let surfaceSubtle = Color(hex: 0xF7F8FA)

    /// Figma style: `white` (#FFFFFF) — screen background.
    static let appBackground = Color.white

    /// Figma style: `Text Primary` (#172033) — primary label color used across
    /// titles, chip labels and body copy in the design.
    static let textPrimary = Color(hex: 0x172033)

    /// Figma style: `Text Secondary` (#667085) — added for the "2-1 공지글"
    /// detail frame (the "< 목록으로" back link).
    static let textSecondary = Color(hex: 0x667085)
    
    /// Figma style: `Surface` (#F0F2F5) — fill for the selected category chip.
    static let surface = Color(hex: 0xF0F2F5)

    /// Figma style: `border` (#DDE1E7) — hairline border for unselected chips.
    static let borderLight = Color(hex: 0xDDE1E7)

    /// Figma style: `gray400` (#98A2B3) — secondary/disabled content.
    static let gray400 = Color(hex: 0x98A2B3)

    /// Figma style: `gray50` (#FAFBFC) — tab bar background.
    static let gray50 = Color(hex: 0xFAFBFC)

    /// Figma variable: `accents/red` (#FF383C) — used only for the "마감 D-n"
    /// deadline label. Scoped to this element, not the app-wide tint, so it is
    /// NOT written into `AccentColor`.
    static let accentRed = Color(hex: 0xFF383C)

    /// Background of the filled category badge (`FilterChip.Style.badge`) on
    /// the notice detail card — the app accent (`eventAccent`) instead of
    /// Figma's light pink `rgba(255,181,181,0.5)`.
    static let categoryBadgeBackground = eventAccent

    /// Raw one-off fill (#EAEAEA, not a named Figma style) — background of
    /// the pill-shaped 이전 글/목록으로/다음 글 control on the detail screen.
    static let controlPillBackground = Color(hex: 0xEAEAEA)

    // MARK: - Shared hues
    //
    // One definition per value that several tokens below share, so changing
    // the hue changes every use at once.

    /// #34C759 — 사용중 badge, 학생회 일정 dot, profile 초록.
    static let statusGreen = Color(hex: 0x34C759)

    /// #FFEFE0 — light orange tint: admin map 승인 대기 tile, "팝업" tag.
    static let orangeTint = Color(hex: 0xFFEFE0)

    // MARK: - Dims (behind popups)

    /// Black 30% — behind dialogs, bottom action cards and the ban card.
    static let dimOverlay = Color.black.opacity(0.3)

    /// Black 40% — behind the profile editor.
    static let dimOverlayMedium = Color.black.opacity(0.4)

    /// Black 60% — behind the notice detail card (Figma `rgba(53,53,53,0.6)`)
    /// and the locker application dialogs.
    static let dimOverlayStrong = Color.black.opacity(0.6)

    // MARK: - "1-5 로그인" (login)

    /// Figma style: `gray200` (#EAECF0) — border of the login card. Distinct
    /// from `borderLight` (#DDE1E7), which is a different gray used on
    /// category chips and dialog borders.
    static let gray200 = Color(hex: 0xEAECF0)

    /// Not in Figma — a deeper `eventAccent` for blue *text* on white
    /// (댓글 "등록", the "글쓴이" badge) and focused-field borders.
    /// `eventAccent` text on white is only ~2.4:1; this is the lightest blue
    /// of the same hue that reaches the 4.5:1 text minimum (~4.52:1).
    /// Filled buttons don't use it: they're `buttonAccent` with white labels.
    static let accentStrong = Color(hex: 0x007ACB)

    /// Fill of every filled blue button, with a white label — the app
    /// accent itself (#36AFFF). White on it is ~2.4:1, below the WCAG text
    /// minimum; chosen by the team for the brand look.
    static let buttonAccent = eventAccent

    /// Not in Figma — "on" track of `AppSwitchToggleStyle`. The lightest
    /// blue of `eventAccent`'s hue that's 3:1 against white (~3.01:1).
    static let switchOnTrack = Color(hex: 0x0099FE)

    /// Not in Figma — "off" track of `AppSwitchToggleStyle`. `gray400`'s
    /// hue darkened to 3:1 against white (~3.02:1); iOS's own off track
    /// is ~1.2:1 and barely shows.
    static let switchOffTrack = Color(hex: 0x8A95A9)

    /// Figma style: `secondaryColor` (#FF4194) — the reply icon of the
    /// comment you're currently replying to on "5-1 게시글" (~3.1:1 on the
    /// comments' gray, above the 3:1 minimum for icons).
    static let secondaryAccent = Color(hex: 0xFF4194)

    /// Not in Figma — border of an unchecked checkbox. `borderLight` was
    /// ~1.3:1 against the card behind it (nearly invisible); this clears
    /// the 3:1 minimum for control outlines on white/`gray50`.
    static let controlBorder = Color(hex: 0x858FA1)

    // MARK: - "3 캘린더" (calendar)

    /// Figma style: `gray300` (#D0D5DD) — neutral gray for disabled/broken
    /// states (locker cells, comment dividers).
    static let gray300 = Color(hex: 0xD0D5DD)

    /// Figma style: `white_sub` (#F7F8FA) — the month-grid card background.
    static let calendarSurface = Color(hex: 0xF7F8FA)

    /// Sunday / public-holiday day numbers and weekday label — the red most
    /// Korean calendars use. Same hue as `accentRed`.
    static let calendarSunday = accentRed

    /// Saturday day numbers and weekday label. A deeper blue than
    /// `eventAccent` so it doesn't read as the "today"/selected accent.
    static let calendarSaturday = Color(hex: 0x3478F6)

    // MARK: - Category colors (calendar event dots / row accent bars)

    /// Figma style: `category` (#3982FF, "어떠한 카테고리") — the schedule
    /// color bar ("일정색") on "3 캘린더" / "3-1 일정 전체보기".
    static let category = Color(hex: 0x3982FF)

    /// 학사 (and 전체) — Figma's `category` style.
    static let categoryAcademic = category
    /// 학생회 = the brand's secondary color (pink).
    static let categoryStudentCouncil = secondaryAccent

    // MARK: - "4 사물함" (locker)

    /// Figma style: `primary` (#FF4F6D) — highlights the current user's own
    /// locker in the grid. Named `brandPrimary` (not `AccentColor`) because
    /// only this one element uses it in the file so far; promote it to
    /// `AccentColor` later if it turns out to be the app-wide tint too.
    static let brandPrimary = Color(hex: 0xFF4F6D)

    /// Figma fill `rgba(255,141,40,0.3)` (#FF8D28) — "내 사물함" component's
    /// `속성 1=승인대기` variant status dot/pill (신청 후 관리자 승인 대기 중).
    /// Not an exact match for any `UIColor` system color, unlike the
    /// `systemGreen`/`systemOrange` used elsewhere on this card.
    static let lockerPendingBadge = Color(hex: 0xFF8D28)

    /// Figma fill `rgba(0,192,232,0.3)` (#00C0E8) — "내 사물함" component's
    /// `속성 1=베리언트4` variant status dot/pill (승인 완료, 비밀번호 등록 필요).
    static let lockerApprovedBadge = Color(hex: 0x00C0E8)

    /// Figma fill `rgba(52,199,89,0.3)` (#34C759) — "사용중" status dot/pill
    /// (내 사물함 카드, 관리자 사물함 행). Same as the light-mode system green
    /// it replaces.
    static let lockerInUseBadge = statusGreen

    /// Figma `#FFEFE0` — 승인 대기 tile on the admin locker map (light orange,
    /// a tint of `lockerPendingBadge`).
    static let lockerAdminPending = orangeTint

    // MARK: - Locker cell states (main-screen grid, apply-screen map, legend)

    /// "신청 가능" — the only state that invites a tap, so the only one with
    /// an accent fill (`eventAccentLight`, AccentLight).
    static let lockerAvailable = eventAccentLight
    /// "승인 대기중" — the original yellow, unchanged.
    static let lockerPending = Color(hex: 0xFFC542)
    /// 사용중 · 고장 · 사용 제한 · 정보 없음 — one quiet light-gray tile with
    /// faded text, so the grid doesn't read as a wall of buttons.
    static let lockerUnavailable = surface
    static let lockerUnavailableText = gray400
    /// Numberless "-" slots (B206's 학생회 사물함 columns) — a dark gray
    /// block so they don't read as rentable lockers with a missing number.
    static let lockerRestricted = gray400
    /// "내 사물함" — AccentDark fill with white text so it stands out.
    static let lockerMine = eventAccentDark

    // MARK: - "5 커뮤니티" (community)

    /// Figma style: `gray700` (#344054) — like/comment count labels.
    static let gray700 = Color(hex: 0x344054)

    // MARK: - 관리자 신고 관리 (Figma `729:3939`, `731:4120`)

    /// Destructive red — 신고 사유 태그 / "신고 n건" / "삭제" text, the
    /// pending-count number on the 미처리 tab, and the "n일 정지하기" fill.
    /// Figma has #F04438, which is only ~3.6:1 against white (and lower on
    /// its pink tag); this is the same hue deepened to clear 4.5:1 for
    /// small text — the same reason `accentStrong` replaces #36AFFF.
    static let adminDanger = Color(hex: 0xD92D20)

    /// Figma `#FFECEA` — background of the red 신고 사유 tag.
    static let adminDangerTint = Color(hex: 0xFFECEA)

    /// "처리 완료 · …" text on a resolved report card. Figma's #12965A is
    /// ~3.4:1 on its green tint; deepened to clear 4.5:1.
    static let adminSuccess = Color(hex: 0x067647)

    /// Figma `#E0F6EA` — background of the "처리 완료" line.
    static let adminSuccessTint = Color(hex: 0xE0F6EA)

    // MARK: - Cync 공지 "팝업" 태그 (Figma `734:4276`)

    /// "팝업" tag text. Figma's #FF8D28 is only ~2.2:1 on its tint; this
    /// is the same orange deepened past 4.5:1.
    static let popupTagText = Color(hex: 0xB54708)

    /// Figma `#FFEFE0` — "팝업" tag background (same tint as the admin
    /// map's 승인 대기 tile).
    static let popupTagBackground = orangeTint

    // MARK: - Profile colors (`ProfileColor` from `PUT /api/me/profile`)

    /// The 9-color profile palette isn't in the Figma file (no picker UI was
    /// designed for it yet) — these are standard iOS system-color hues
    /// approximating each server enum case, not extracted design tokens.
    static let profileRed = Color(hex: 0xFF3B30)
    static let profileOrange = Color(hex: 0xFF9500)
    static let profileYellow = Color(hex: 0xFFCC00)
    static let profileGreen = statusGreen
    static let profileMint = Color(hex: 0x00C7BE)
    static let profileBlue = Color(hex: 0x007AFF)
    static let profilePurple = Color(hex: 0xAF52DE)
    /// Lighter, bluer pink than the system's #FF2D55, which read almost the
    /// same as `profileRed` (#FF3B30) in the picker. Still saved as PINK.
    static let profilePink = Color(hex: 0xFF5FB4)
    static let profileGray = Color(hex: 0x8E8E93)
}

private extension Color {
    /// Convenience initializer for the raw hex values captured from Figma.
    init(hex: UInt32) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
