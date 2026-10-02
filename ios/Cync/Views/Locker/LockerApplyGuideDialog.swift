//
//  LockerApplyGuideDialog.swift
//  Cync
//
//  "사물함 신청 방법" popup behind the "!" icon in LockerView's header —
//  explains the apply flow step by step, since the header's "신청" button
//  only exists for students without a locker. When applying is possible
//  (`onApply` set), a "신청하러 가기" button opens the apply screen.
//  Dimmed-overlay `DialogCard`, not a system alert (CLAUDE.md).
//

import SwiftUI

struct LockerApplyGuideDialog: View {
    /// `nil` hides "신청하러 가기" (the student already has a locker).
    var onApply: (() -> Void)?
    let onClose: () -> Void

    private let steps: [LocalizedStringResource] = [
        .lockerGuideStep1, .lockerGuideStep2, .lockerGuideStep3, .lockerGuideStep4
    ]

    var body: some View {
        DialogCard {
            Text(.lockerGuideTitle)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(index + 1, format: .number)
                            .font(.dialogBody).tracking(Tracking.dialogBody)
                            .foregroundStyle(Color.eventAccent)
                        Text(step)
                            .font(.dialogBody).tracking(Tracking.dialogBody)
                            .foregroundStyle(Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, Spacing.xxs)

            HStack(spacing: Spacing.cardInset) {
                DialogActionButton(titleKey: .commonOk, action: onClose)
                if let onApply {
                    DialogActionButton(titleKey: .lockerGuideApply, style: .primary, action: onApply)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        LockerApplyGuideDialog(onApply: {}, onClose: {})
            .padding(.horizontal, Spacing.md)
    }
}
