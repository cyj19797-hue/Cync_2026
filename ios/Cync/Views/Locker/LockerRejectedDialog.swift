//
//  LockerRejectedDialog.swift
//  Cync
//
//  "사물함 신청이 승인되지 않았어요" — shown once on the 사물함 tab when a
//  request the student was waiting on is gone (`LockerViewModel
//  .rejectedLocker`, from `LockerApplicationTracker`). It doesn't say
//  "rejected" outright: the admin's 학기 말 전체 반납 can also cancel
//  pending requests, and the app can't tell the two apart.
//
//  [확인] closes; [다시 신청하기] closes and opens the apply screen.
//

import SwiftUI

struct LockerRejectedDialog: View {
    /// "B203(1)"; nil if the number isn't in the layout.
    let zoneId: String?
    let lockerNumber: Int
    let onClose: () -> Void
    let onReapply: () -> Void

    var body: some View {
        DialogCard {
            Text(.lockerRejectedTitle)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .dialogTitleGap()

            Text(.lockerRejectedMessage(zoneId ?? "", lockerNumber))
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .dialogBodyGap()

            DialogActionRow {
                DialogActionButton(titleKey: .commonOk, action: onClose)
                DialogActionButton(titleKey: .lockerRejectedReapply, style: .primary, action: onReapply)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.dimOverlayStrong.ignoresSafeArea()
        LockerRejectedDialog(zoneId: "B203(1)", lockerNumber: 112, onClose: {}, onReapply: {})
            .padding(.horizontal, Spacing.md)
    }
}
