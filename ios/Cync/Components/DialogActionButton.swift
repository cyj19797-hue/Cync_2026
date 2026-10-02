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
    /// `tint` fill (default `accentStrong`), white label, 10pt radius — the
    /// dialog's main action (신청, 신고, 삭제, 저장 …).
    case primary
}

/// A dialog's action button: sized to its label with 10pt of padding all
/// around (and never under 44×44pt, so it stays easy to hit). Rows put a
/// `Spacer` first, so the buttons sit together at the dialog's trailing
/// edge — 취소 then the main action — `Spacing.xs` apart.
struct DialogActionButton: View {
    let titleKey: LocalizedStringResource
    var style: DialogActionStyle = .secondary
    /// `.primary`'s fill. Defaults to `accentStrong`: white on it is ~5.2:1,
    /// where the old pink `brandPrimary` (~3:1) and sky `eventAccent`
    /// (~2.4:1) both fell short of the 4.5:1 text minimum.
    var tint: Color = .accentStrong
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(.categoryChip).tracking(Tracking.categoryChip)
                .foregroundStyle(style == .primary ? Color.white : Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(10)
                .frame(minWidth: 44, minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(style == .primary ? tint : Color.surface)
                }
                .contentShape(RoundedRectangle(cornerRadius: Radius.chipSelected))
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

#Preview {
    HStack(spacing: Spacing.xs) {
        Spacer(minLength: 0)
        DialogActionButton(titleKey: "취소") {}
        DialogActionButton(titleKey: "삭제", style: .primary) {}
    }
    .padding()
}
