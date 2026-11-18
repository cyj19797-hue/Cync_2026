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
//  Also covers the category tag on the notice detail card (Figma node
//  `I44:269;184:1577`, formerly its own `NoticeCategoryBadge` component)
//  via `Style.badge` — drawn exactly like the selected filter chip (학사
//  blue + white, 학생회 light pink + dark text), just without a tap action.
//
//  `.selected` is filled with the category's chip color
//  (`chipSelectedColor`: 학사·전체 blue, 학생회 light pink) with a white
//  label (dark on the light pink — `chipSelectedLabelColor`), instead of Figma's light-gray
//  `surface` fill — the gray was too close to the unselected chips to tell
//  which filter is active.
//
//  `Style.selected`/`.unselected` only ever switch the fill/border/corner-radius
//  below — Figma specs the same `p-[8px]` on every chip regardless of
//  selection, so the padding here is pinned to
//  `chipHorizontalPadding`/`chipVerticalPadding` independently of `style`,
//  guaranteeing every variant renders at the same height.
//
//  The tappable `.selected`/`.unselected` chips render through the shared
//  `SelectableChip` (`.filter` look); `label` below now only draws the
//  static `.badge`.
//

import SwiftUI

struct FilterChip: View {
    enum Style: Equatable {
        case selected
        case unselected
        /// The non-interactive notice-category tag — looks like `.selected`.
        case badge
    }

    /// Sourced from `Spacing.xs` (not a raw literal) so this stays in sync
    /// with the rest of the design system if that token ever changes.
    private static let chipHorizontalPadding: CGFloat = Spacing.xs
    private static let chipVerticalPadding: CGFloat = Spacing.xs

    let category: NoticeCategory
    let style: Style
    /// `nil` renders as a plain (non-`Button`) label — used by `.badge`,
    /// which is a static tag rather than a tappable filter.
    var action: (() -> Void)?

    var body: some View {
        if style != .badge, let action {
            // The tappable filter chip is the shared `SelectableChip`.
            SelectableChip(
                titleKey: category.label,
                isSelected: style == .selected,
                selectedTint: category.chipSelectedColor,
                selectedLabelColor: category.chipSelectedLabelColor,
                action: action
            )
        } else if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    /// Draws `.badge` (and a non-tappable `.selected`) exactly like the
    /// selected filter chip — same font, padding, corners, and the
    /// category's chip fill and label color — so the tag inside a notice
    /// matches the chip row above the list.
    private var label: some View {
        Text(category.label)
            .font(.categoryFilterChipLabel).tracking(Tracking.categoryFilterChipLabel)
            .foregroundStyle(isFilled ? category.chipSelectedLabelColor : Color.textPrimary)
            .padding(.horizontal, Self.chipHorizontalPadding)
            .padding(.vertical, Self.chipVerticalPadding)
            .background {
                RoundedRectangle(cornerRadius: isFilled ? Radius.chipSelected : Radius.chipDefault)
                    .fill(isFilled ? category.chipSelectedColor : Color.white)
                    .overlay {
                        if !isFilled {
                            RoundedRectangle(cornerRadius: Radius.chipDefault)
                                .strokeBorder(Color.borderLight, lineWidth: 0.5)
                        }
                    }
            }
    }

    private var isFilled: Bool { style != .unselected }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        HStack(spacing: Spacing.xs) {
            FilterChip(category: .all, style: .selected) {}
            FilterChip(category: .academic, style: .unselected) {}
            FilterChip(category: .studentCouncil, style: .unselected) {}
        }
        HStack(spacing: Spacing.xs) {
            FilterChip(category: .academic, style: .badge)
            FilterChip(category: .academic, style: .badge)
        }
    }
    .padding()
    .background(Color.appBackground)
}
