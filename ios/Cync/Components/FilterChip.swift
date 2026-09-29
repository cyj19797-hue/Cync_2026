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
//  Also covers the small category tag in front of each notice title (Figma
//  node `I44:269;184:1577`, formerly its own `NoticeCategoryBadge`
//  component) via `Style.badge` — same capsule shape and category label as
//  the filter chip, just a white fill with a pink hairline border (no fill
//  color, matching `.unselected`'s outlined look) and no tap action, so it
//  was folded into this component instead of duplicating the capsule layout
//  in a second file.
//
//  `Style.selected`/`.unselected` only ever switch the fill/border/corner-radius
//  below — Figma specs the same `p-[8px]` on every chip regardless of
//  selection, so the padding here is pinned to
//  `chipHorizontalPadding`/`chipVerticalPadding` independently of `style`,
//  guaranteeing every variant renders at the same height.
//

import SwiftUI

struct FilterChip: View {
    enum Style: Equatable {
        case selected
        case unselected
        /// The non-interactive notice-category tag (white fill, pink border).
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
        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    private var label: some View {
        Text(category.label)
            .font(font).tracking(tracking)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Self.chipHorizontalPadding)
            .padding(.vertical, Self.chipVerticalPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .overlay {
                        if let borderColor {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(borderColor, lineWidth: 0.5)
                        }
                    }
            }
    }

    private var font: Font {
        style == .badge ? .categoryBadge : .categoryFilterChipLabel
    }

    private var tracking: CGFloat {
        style == .badge ? Tracking.categoryBadge : Tracking.categoryFilterChipLabel
    }

    private var cornerRadius: CGFloat {
        style == .selected ? Radius.chipSelected : Radius.chipDefault
    }

    private var fillColor: Color {
        switch style {
        case .selected: return .surface
        case .unselected, .badge: return .white
        }
    }

    private var borderColor: Color? {
        switch style {
        case .selected: return nil
        case .unselected: return .borderLight
        case .badge: return .categoryBadgeBorder
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        HStack(spacing: Spacing.xs) {
            FilterChip(category: .all, style: .selected) {}
            FilterChip(category: .academic, style: .unselected) {}
            FilterChip(category: .scholarship, style: .unselected) {}
        }
        HStack(spacing: Spacing.xs) {
            FilterChip(category: .academic, style: .badge)
            FilterChip(category: .exchange, style: .badge)
        }
    }
    .padding()
    .background(Color.appBackground)
}
