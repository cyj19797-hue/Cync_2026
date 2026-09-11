//
//  FilterChip.swift
//  test
//
//  Figma node `42:108` ("category") — a row of filter chips. The selected
//  chip (`I42:108;42:84`, "전체") is a filled `Surface`-colored pill; the rest
//  (`I42:108;42:87` etc.) are white with a hairline `border`. Visually these
//  are individual capsule buttons rather than one segmented-control
//  container, so a custom chip is used instead of `Picker(.segmented)`.
//
//  `isSelected` only ever switches the fill/border/corner-radius below —
//  Figma specs the same `p-[8px]` on every chip regardless of selection, so
//  the padding here is pinned to `chipHorizontalPadding`/`chipVerticalPadding`
//  independently of `isSelected`, guaranteeing a selected and an unselected
//  chip always render at the same height. (Renamed from `NoticeCategoryChip`
//  — nothing about this chip is notice-specific, it's shared with
//  `CalendarView` too via `CategoryFilterRow`.)
//

import SwiftUI

struct FilterChip: View {
    /// Sourced from `Spacing.xs` (not a raw literal) so this stays in sync
    /// with the rest of the design system if that token ever changes.
    private static let chipHorizontalPadding: CGFloat = Spacing.xs
    private static let chipVerticalPadding: CGFloat = Spacing.xs

    let category: NoticeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.localizedKey)
                .font(.categoryFilterChipLabel).tracking(Tracking.categoryFilterChipLabel)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Self.chipHorizontalPadding)
                .padding(.vertical, Self.chipVerticalPadding)
                .background {
                    RoundedRectangle(cornerRadius: isSelected ? Radius.chipSelected : Radius.chipDefault)
                        .fill(isSelected ? Color.surface : Color.white)
                        .overlay {
                            if !isSelected {
                                RoundedRectangle(cornerRadius: Radius.chipDefault)
                                    .strokeBorder(Color.borderLight, lineWidth: 0.5)
                            }
                        }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: Spacing.xs) {
        FilterChip(category: .all, isSelected: true) {}
        FilterChip(category: .academic, isSelected: false) {}
        FilterChip(category: .scholarship, isSelected: false) {}
    }
    .padding()
    .background(Color.appBackground)
}
