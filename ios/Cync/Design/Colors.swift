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

    /// Figma fill: `rgba(255,181,181,0.5)` — background of the small category
    /// badge shown inside each notice row.
    static let categoryBadgeBackground = Color(hex: 0xFFB5B5).opacity(0.5)

    /// Raw one-off fill (#EAEAEA, not a named Figma style) — background of
    /// the pill-shaped 이전 글/목록으로/다음 글 control on the detail screen.
    static let controlPillBackground = Color(hex: 0xEAEAEA)

    // MARK: - "1-5 로그인" (login)

    /// Figma style: `gray200` (#EAECF0) — border of the login card. Distinct
    /// from `borderLight` (#DDE1E7), which is a different gray used on
    /// category chips and dialog borders.
    static let gray200 = Color(hex: 0xEAECF0)

    // MARK: - "3 캘린더" (calendar)

    /// Figma style: `gray300` (#D0D5DD) — the selected day's circle fill.
    static let gray300 = Color(hex: 0xD0D5DD)

    /// Figma style: `white_sub` (#F7F8FA) — the month-grid card background.
    static let calendarSurface = Color(hex: 0xF7F8FA)

    /// Raw one-off stroke (#DBDBDB, not a named Figma style) — border of the
    /// "등록된 일정" card, distinct from the lighter `borderLight` used on
    /// category chips.
    static let cardBorder = Color(hex: 0xDBDBDB)

    // MARK: - "4 사물함" (locker)

    /// Figma style: `primary` (#FF4F6D) — highlights the current user's own
    /// locker in the grid. Named `brandPrimary` (not `AccentColor`) because
    /// only this one element uses it in the file so far; promote it to
    /// `AccentColor` later if it turns out to be the app-wide tint too.
    static let brandPrimary = Color(hex: 0xFF4F6D)

    // MARK: - "5 커뮤니티" (community)

    /// Figma style: `gray700` (#344054) — like/comment count labels.
    static let gray700 = Color(hex: 0x344054)

    /// Figma style: `primary_dark` (#E63F5D) — border of the checked "기타"
    /// checkbox on the report-reason sheet.
    static let brandPrimaryDark = Color(hex: 0xE63F5D)

    // MARK: - Profile colors (`ProfileColor` from `PUT /api/me/profile`)

    /// The 9-color profile palette isn't in the Figma file (no picker UI was
    /// designed for it yet) — these are standard iOS system-color hues
    /// approximating each server enum case, not extracted design tokens.
    static let profileRed = Color(hex: 0xFF3B30)
    static let profileOrange = Color(hex: 0xFF9500)
    static let profileYellow = Color(hex: 0xFFCC00)
    static let profileGreen = Color(hex: 0x34C759)
    static let profileMint = Color(hex: 0x00C7BE)
    static let profileBlue = Color(hex: 0x007AFF)
    static let profilePurple = Color(hex: 0xAF52DE)
    static let profilePink = Color(hex: 0xFF2D55)
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
