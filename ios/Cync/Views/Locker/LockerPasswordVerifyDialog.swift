//
//  LockerPasswordVerifyDialog.swift
//  Cync
//
//  "사물함 비밀번호 찾기" gate: asks for the account password (a
//  `SecureField` via `LabeledInputField(isSecure:)`) before revealing the
//  locker password. A wrong password shows "비밀번호가 일치하지 않아요" under
//  the field, clears it and lets the student try again; a network failure
//  shows a separate retry message. On success the same card switches to
//  showing the locker password. Dimmed-overlay `DialogCard`, not a system
//  alert (CLAUDE.md).
//

import SwiftUI

struct LockerPasswordVerifyDialog: View {
    let lockerPassword: String?
    let verify: (String) async throws -> Bool
    let onClose: () -> Void

    private enum Phase {
        case input
        case verifying
        case revealed
    }

    @State private var phase: Phase = .input
    @State private var accountPassword = ""
    @State private var errorMessage: LocalizedStringResource?
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        DialogCard {
            switch phase {
            case .input, .verifying:
                inputContent
            case .revealed:
                revealedContent
            }
        }
    }

    private var inputContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.lockerVerifyTitle)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)

            Text(.lockerVerifyMessage)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textSecondary)

            LabeledInputField(placeholder: .lockerVerifyPlaceholder, text: $accountPassword, isSecure: true)
                .focused($isFieldFocused)
                .submitLabel(.done)
                .onSubmit(submit)
                .disabled(phase == .verifying)
                .padding(.top, Spacing.xxs)

            if let errorMessage {
                Text(errorMessage)
                    .font(.calendarCaption).tracking(Tracking.calendarCaption)
                    .foregroundStyle(Color.accentRed)
            }

            HStack(spacing: Spacing.xs) {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: .commonCancel, action: onClose)
                DialogActionButton(
                    titleKey: phase == .verifying ? .lockerVerifying : .commonOk,
                    style: .primary,
                    action: submit
                )
                .disabled(accountPassword.isEmpty || phase == .verifying)
            }
            .padding(.top, Spacing.xxs)
        }
        .onAppear { isFieldFocused = true }
    }

    private var revealedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.lockerPasswordAlertTitle)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)

            Group {
                if let lockerPassword {
                    Text(verbatim: lockerPassword)
                        .font(.lockerNumberLarge).tracking(Tracking.lockerNumberLarge)
                } else {
                    Text(.lockerNoPassword)
                        .font(.dialogBody).tracking(Tracking.dialogBody)
                }
            }
            .foregroundStyle(Color.textPrimary)
            .padding(.vertical, Spacing.xxs)

            HStack {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: .commonOk, action: onClose)
            }
        }
    }

    private func submit() {
        guard !accountPassword.isEmpty, phase == .input else { return }
        phase = .verifying
        errorMessage = nil
        Task {
            do {
                if try await verify(accountPassword) {
                    phase = .revealed
                } else {
                    showRetry(.lockerVerifyMismatch)
                }
            } catch {
                showRetry(.lockerVerifyFailed)
            }
        }
    }

    private func showRetry(_ message: LocalizedStringResource) {
        errorMessage = message
        accountPassword = ""
        phase = .input
        isFieldFocused = true
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        LockerPasswordVerifyDialog(lockerPassword: "3847", verify: { $0 == "1234" }, onClose: {})
            .padding(.horizontal, Spacing.md)
    }
}
