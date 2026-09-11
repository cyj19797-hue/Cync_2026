//
//  Spacing.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//

import CoreGraphics

/// Auto-layout gap / padding tokens.
enum Spacing {
    /// Figma `--spacing-2xs` (4px).
    static let xxs: CGFloat = 4
    /// Figma `--spacing-xs` (8px).
    static let xs: CGFloat = 8
    /// Figma `--spacing-md` (16px).
    static let md: CGFloat = 16
    /// Figma `--spacing-sm` (12px) — used on the "2-1 공지글" detail card.
    static let sm: CGFloat = 24
    /// Figma `--spacing-xl` (32px) — reply indentation on "5-1 게시글".
    static let xl: CGFloat = 32
    /// Figma `--spacing-sm` (12px) — the "1-5 로그인" card's outer padding.
    /// NOTE: `sm` above already claims 12px in its own doc comment but is
    /// actually set to 24 — a pre-existing mismatch kept as-is so other
    /// screens that depend on its current 24pt value aren't affected; this
    /// token exists so the login screen isn't forced to inherit that bug.
    static let cardInset: CGFloat = 12
}

/// Corner radius tokens.
enum Radius {
    /// Selected category chip ("전체" pill), e.g. `I42:108;42:84` (10px).
    static let chipSelected: CGFloat = 10
    /// Unselected category chip / category badge (7.5px).
    static let chipDefault: CGFloat = 7.5
    /// "2-1 공지글" detail card outer corner radius (20px).
    static let card: CGFloat = 20
    /// "3 캘린더" month-grid card corner radius (10px).
    static let calendarCard: CGFloat = 10
    /// "3 캘린더" "등록된 일정" card's top corners (12px).
    static let scheduleCard: CGFloat = 12
    /// "4 사물함" grid cell corner radius (8px).
    static let lockerCell: CGFloat = 8
    /// "4 사물함" summary card's "사용중" status pill (15px).
    static let statusPill: CGFloat = 15
    /// "1-5 로그인" text field border radius (8px).
    static let inputField: CGFloat = 8
    /// "1-4 이용약관 동의" agreement item card corner radius (12px).
    static let agreementCard: CGFloat = 12
}
