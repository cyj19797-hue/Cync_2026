//
//  LoginView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `219:2565` ("1-5 로그인").
//
//  No nav bar / back chevron in the design — this is an onboarding screen
//  (after language selection). `CyncApp` shows this whenever
//  `SessionStore.isLoggedIn` is false (skipped on launch when "자동 로그인"
//  restored a saved session); a
//  successful `viewModel.submit()` calls `sessionStore.logIn()` to switch
//  to `RootTabView`.
//
//  No UIKit anywhere on this screen — a plain `VStack` plus the app's
//  existing `TextField`/`SecureField`-based components covers the whole
//  layout, so nothing here needed it.
//
//  A failed `submit()` shows `ErrorDialog` ("로그인 실패") as a dimmed-backdrop
//  overlay — same non-`.alert()` pattern the locker application dialogs use
//  — instead of the system `.alert(...)` this screen used to show.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        VStack(spacing: 0) {
            logo
            loginCard
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .overlay {
            if let errorMessage = viewModel.errorMessage {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    ErrorDialog(
                        titleKey: .loginFailedTitle,
                        message: errorMessage,
                        onConfirm: { viewModel.errorMessage = nil }
                    )
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
    }

    private var logo: some View {
        Image("CyncWordmark")
            .resizable()
            .scaledToFit()
            .frame(width: 144, height: 144)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loginCard: some View {
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(.loginTitle)
                .font(.loginTitle).tracking(Tracking.loginTitle)
                .foregroundStyle(Color.eventAccent)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                studentIdField
                passwordField
            }
            .padding(.vertical, Spacing.md)

            HStack(spacing: Spacing.sm) {
                CheckboxToggle(
                    isChecked: $viewModel.rememberStudentId,
                    titleKey: .loginRememberId,
                    style: .accent,
                    spacing: Spacing.xs
                )

                CheckboxToggle(
                    isChecked: $viewModel.autoLogin,
                    titleKey: .loginAutoLogin,
                    style: .accent,
                    spacing: Spacing.xs
                )
            }
            .padding(.vertical, Spacing.xxs)

            PrimaryActionButton(
                titleKey: .loginSubmit,
                isEnabled: viewModel.canSubmit && !viewModel.isSubmitting,
                tint: .eventAccent
            ) {
                Task {
                    if await viewModel.submit() {
                        sessionStore.logIn()
                    }
                }
            }
            .padding(.vertical, Spacing.xxs)
        }
        .padding(Spacing.cardInset)
        .background(Color.gray50)
        .overlay {
            UnevenRoundedRectangle(topLeadingRadius: Radius.card, topTrailingRadius: Radius.card)
                .strokeBorder(Color.gray200)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: Radius.card, topTrailingRadius: Radius.card))
    }

    private var studentIdField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.loginStudentId)
                .font(.loginFieldLabel).tracking(Tracking.loginFieldLabel)
                .foregroundStyle(Color.textPrimary)
            LabeledInputField(placeholder: .loginStudentIdPlaceholder, text: $viewModel.studentId, keyboardType: .numberPad)
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Text(.loginPassword)
                    .font(.loginFieldLabel).tracking(Tracking.loginFieldLabel)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                    Text(.loginPasswordNotStored)
                        .font(.loginCaption).tracking(Tracking.loginCaption)
                        .foregroundStyle(Color.textSecondary)
                }
                
            }
            LabeledInputField(placeholder: .loginPasswordPlaceholder, text: $viewModel.password, isSecure: true)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}
