//
//  AdminLockerConfirmDialog.swift
//  Cync
//
//  Confirm before a locker action that the student will feel — 거부
//  ("012번 사물함 신청을 거부할까요?") and 반납 ("045번 사물함을 반납
//  처리할까요?"). Custom `DialogCard`, not `.alert`. The report screen
//  reuses it for 삭제 ("이 게시글을 삭제할까요?") with a red `confirmTint`.
//

import SwiftUI

struct AdminLockerConfirmDialog: View {
    let titleKey: LocalizedStringResource
    let messageKey: LocalizedStringResource
    let confirmKey: LocalizedStringResource
    let onCancel: () -> Void
    let onConfirm: () -> Void
    /// The main button's fill — red for a delete.
    var confirmTint: Color = .buttonAccent

    var body: some View {
        DialogCard {
            Text(titleKey)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .dialogTitleGap()

            Text(messageKey)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .dialogBodyGap()

            DialogActionRow {
                DialogActionButton(titleKey: .commonCancel, action: onCancel)
                DialogActionButton(titleKey: confirmKey, style: .primary, tint: confirmTint, action: onConfirm)
            }
        }
    }
}

extension AdminLockerConfirmDialog {
    static func reject(paddedNumber: String, onCancel: @escaping () -> Void, onConfirm: @escaping () -> Void) -> Self {
        Self(
            titleKey: .adminLockerRejectConfirmTitle(paddedNumber),
            messageKey: .adminLockerRejectConfirmMessage,
            confirmKey: .adminLockerReject,
            onCancel: onCancel,
            onConfirm: onConfirm
        )
    }

    static func `return`(paddedNumber: String, onCancel: @escaping () -> Void, onConfirm: @escaping () -> Void) -> Self {
        Self(
            titleKey: .adminLockerReturnConfirmTitle(paddedNumber),
            messageKey: .adminLockerReturnConfirmMessage,
            confirmKey: .adminLockerReturn,
            onCancel: onCancel,
            onConfirm: onConfirm
        )
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AdminLockerConfirmDialog.reject(paddedNumber: "012", onCancel: {}, onConfirm: {})
        AdminLockerConfirmDialog.return(paddedNumber: "045", onCancel: {}, onConfirm: {})
    }
    .padding()
}
