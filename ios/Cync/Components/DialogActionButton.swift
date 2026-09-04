//
//  DialogActionButton.swift
//  test
//
//  Figma nodes `243:4720`/`243:4811` ("button", Surface-filled — 취소/확인)
//  and `243:4731` ("button", coral-filled — 신청) — the two pill-button
//  styles used across both popup dialogs.
//

import SwiftUI

enum DialogActionStyle {
    /// Surface (#F0F2F5) fill, `textPrimary` label, 10pt radius — 취소/확인.
    case secondary
    /// `brandPrimary` fill, white label, 7.5pt radius — 신청 (the
    /// affirmative/destructive-adjacent action).
    case primary
}

struct DialogActionButton: View {
    let titleKey: LocalizedStringKey
    var style: DialogActionStyle = .secondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(.categoryChip)
                .foregroundStyle(style == .primary ? Color.white : Color.textPrimary)
                .padding(Spacing.xs)
                .background {
                    RoundedRectangle(cornerRadius: style == .primary ? Radius.chipDefault : Radius.chipSelected)
                        .fill(style == .primary ? Color.brandPrimary : Color.surface)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        DialogActionButton(titleKey: "취소") {}
        DialogActionButton(titleKey: "신청", style: .primary) {}
    }
    .padding()
}
