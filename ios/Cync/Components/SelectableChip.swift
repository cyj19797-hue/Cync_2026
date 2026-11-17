//
//  SelectableChip.swift
//  Cync
//
//  A tappable capsule chip for filter/tab rows, not tied to any data type
//  (`FilterChip` wraps it for `NoticeCategory`). Two looks:
//
//  - `.filter` — the 공지사항/캘린더 category chips (Figma `42:108`): 8pt
//    padding, selected = `eventAccent` fill + white label (Figma's gray was
//    too close to the unselected chips), unselected = white + hairline.
//  - `.tab` — "관리자 - 사물함 관리" tabs (Figma `690:3719`): 12×8pt padding,
//    7.5pt corners, selected = `surface` fill + Semibold label, unselected =
//    white + 1pt `borderLight` + Medium label. An optional count follows
//    the title in `lockerPendingBadge` orange ("승인 대기 3"); `countColor`
//    overrides it (the 신고 관리 "미처리 4" count is red, Figma `729:3880`).
//

import SwiftUI

struct SelectableChip: View {
    enum Appearance {
        case filter
        case tab
    }

    let titleKey: LocalizedStringResource
    let isSelected: Bool
    var appearance: Appearance = .filter
    /// Shown after the title (`.tab` only), e.g. the pending count.
    var count: Int? = nil
    /// The count's color — orange by default (사물함 "승인 대기").
    var countColor: Color = .lockerPendingBadge
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Text(titleKey)
                    .foregroundStyle(labelColor)
                if appearance == .tab, let count {
                    Text(count, format: .number.locale(AppLanguage.currentLocale))
                        .foregroundStyle(countColor)
                }
            }
            .font(font).tracking(tracking)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .overlay {
                        if !isSelected {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(Color.borderLight, lineWidth: borderWidth)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var font: Font {
        switch appearance {
        case .filter: return .categoryFilterChipLabel
        case .tab: return isSelected ? .adminTabChipSelected : .adminTabChip
        }
    }

    private var tracking: CGFloat {
        switch appearance {
        case .filter: return Tracking.categoryFilterChipLabel
        case .tab: return isSelected ? Tracking.adminTabChipSelected : Tracking.adminTabChip
        }
    }

    private var labelColor: Color {
        appearance == .filter && isSelected ? .white : .textPrimary
    }

    private var horizontalPadding: CGFloat {
        appearance == .filter ? Spacing.xs : Spacing.cardInset
    }

    private var cornerRadius: CGFloat {
        switch appearance {
        case .filter: return isSelected ? Radius.chipSelected : Radius.chipDefault
        case .tab: return Radius.chipDefault
        }
    }

    private var fillColor: Color {
        switch appearance {
        case .filter: return isSelected ? .eventAccent : .white
        case .tab: return isSelected ? .surface : .white
        }
    }

    private var borderWidth: CGFloat {
        appearance == .filter ? 0.5 : 1
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.md) {
        HStack(spacing: Spacing.xs) {
            SelectableChip(titleKey: .noticeCategoryAll, isSelected: true) {}
            SelectableChip(titleKey: .noticeCategoryAcademic, isSelected: false) {}
        }
        HStack(spacing: Spacing.xs) {
            SelectableChip(titleKey: .adminLockerStatusPending, isSelected: true, appearance: .tab, count: 3) {}
            SelectableChip(titleKey: .adminLockerStatusInUse, isSelected: false, appearance: .tab) {}
        }
    }
    .padding()
}
