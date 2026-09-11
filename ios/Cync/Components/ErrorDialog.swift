//
//  ErrorDialog.swift
//  Cync
//
//  Generic title + message + single bottom-right "확인" error popup — same
//  `DialogCard`/`DialogActionButton` chrome as the locker application
//  dialogs (`LockerApplicationAccountDialog`, `LockerApplicationConfirmDialog`).
//  This project's UI rule (CLAUDE.md) reserves the system `.alert(...)` for
//  destructive confirmations that truly need it; a plain error notice like
//  "로그인 실패" isn't one, so it gets this custom dialog instead, presented
//  as a dimmed-backdrop overlay the same way those locker dialogs are.
//

import SwiftUI

struct ErrorDialog: View {
    let titleKey: LocalizedStringKey
    let message: String
    let onConfirm: () -> Void

    var body: some View {
        DialogCard {
            Text(titleKey)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            Text(message)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            HStack {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: "확인", action: onConfirm)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        ErrorDialog(
            titleKey: "로그인 실패",
            message: "학번 또는 비밀번호를 제대로 입력해주세요.",
            onConfirm: {}
        )
        .padding(.horizontal, Spacing.md)
    }
}
