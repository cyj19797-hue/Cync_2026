//
//  NavigationChevron.swift
//  Cync
//
//  Shared chevron glyph for both trailing "disclosure" indicators
//  (SettingsRow, NotificationSettingRow, LockerView's locker-application
//  prompt, CalendarView's "전체 보기" link — all `.right`) and directional
//  back/prev/next buttons (NoticeDetailView's "목록으로" back arrow,
//  CalendarMonthHeader's prev/next month arrows — `.left`/`.right`).
//  `color` stays a parameter rather than hardcoded, since those two groups
//  legitimately use different colors (`gray400` for a row's disclosure
//  hint vs. each screen's own primary/secondary text color for an
//  in-context nav arrow) — only the glyph/size/weight is unified.
//

import SwiftUI

struct NavigationChevron: View {
    enum Direction {
        case left, right

        var systemImage: String {
            switch self {
            case .left: return "chevron.left"
            case .right: return "chevron.right"
            }
        }
    }

    var direction: Direction = .right
    var color: Color = .gray400

    var body: some View {
        Image(systemName: direction.systemImage)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        NavigationChevron(direction: .left)
        NavigationChevron(direction: .right)
        NavigationChevron(direction: .left, color: .textPrimary)
        NavigationChevron(direction: .right, color: .textSecondary)
    }
    .padding()
}
