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
    /// `tint` fill (default `buttonAccent`) with a white label, 10pt
    /// radius — the
    /// dialog's main action (신청, 신고, 삭제, 저장 …).
    case primary
}

/// A dialog's action button: sized to its label with 10pt of padding all
/// around, 40pt tall on screen (`DialogMetrics.buttonHeight`) but 44pt
/// tall to tap. Put buttons in a `DialogActionRow`, which gathers them at
/// the dialog's trailing edge.
struct DialogActionButton: View {
    let titleKey: LocalizedStringResource
    var style: DialogActionStyle = .secondary
    /// `.primary`'s fill. Defaults to `buttonAccent` (the app accent), white label.
    var tint: Color = .buttonAccent
    /// `.primary`'s label color.
    var labelColor: Color = .white
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    private static let touchExtension = (44 - DialogMetrics.buttonHeight) / 2

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(.categoryChip).tracking(Tracking.categoryChip)
                .foregroundStyle(style == .primary ? labelColor : Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(10)
                .frame(minWidth: 44, minHeight: DialogMetrics.buttonHeight)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(style == .primary ? tint : Color.surface)
                }
                // 40pt to look at, 44pt to tap: the tappable shape reaches
                // 2pt past the top and bottom without changing the layout.
                .padding(.vertical, Self.touchExtension)
                .contentShape(Rectangle())
                .padding(.vertical, -Self.touchExtension)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

#Preview {
    DialogActionRow {
        DialogActionButton(titleKey: "취소") {}
        DialogActionButton(titleKey: "삭제", style: .primary) {}
    }
    .padding()
}
