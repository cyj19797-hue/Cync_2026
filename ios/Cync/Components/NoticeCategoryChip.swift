//
//  NoticeCategoryChip.swift
//  test
//
//  Figma node `42:108` ("category") — a row of filter chips. The selected
//  chip (`I42:108;42:84`, "전체") is a filled `Surface`-colored pill; the rest
//  (`I42:108;42:87` etc.) are white with a hairline `border`. Visually these
//  are individual capsule buttons rather than one segmented-control
//  container, so a custom chip is used instead of `Picker(.segmented)`.
//

import SwiftUI

struct NoticeCategoryChip: View {
    let category: NoticeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.localizedKey)
                .font(.categoryFilterChipLabel)
                .foregroundStyle(Color.textPrimary)
                .padding(Spacing.xs)
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
        NoticeCategoryChip(category: .all, isSelected: true) {}
        NoticeCategoryChip(category: .academic, isSelected: false) {}
        NoticeCategoryChip(category: .scholarship, isSelected: false) {}
    }
    .padding()
    .background(Color.appBackground)
}
