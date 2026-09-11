//
//  LoginView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `219:2565` ("1-5 로그인").
//
//  No nav bar / back chevron in the design — this is an onboarding screen
//  (after language selection). `CyncApp` shows this whenever
//  `SessionStore.isLoggedIn` is false (always true on a fresh launch); a
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
                        titleKey: "로그인 실패",
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
            Text("로그인")
                .font(.loginTitle).tracking(Tracking.loginTitle)
                .foregroundStyle(Color.eventAccent)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                studentIdField
                passwordField
            }
            .padding(.vertical, Spacing.md)

            CheckboxToggle(
                isChecked: $viewModel.rememberStudentId,
                titleKey: "학번 기억하기",
                checkedFill: .eventAccent,
                checkedBorderColor: .eventAccentDark,
                checkmarkColor: .white
            )
            .padding(.vertical, Spacing.xxs)

            PrimaryActionButton(
                titleKey: "로그인",
                isEnabled: viewModel.canSubmit && !viewModel.isSubmitting,
                tint: .eventAccent,
                font: .loginButtonLabel,
                tracking: Tracking.loginButtonLabel
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
            Text("학번")
                .font(.loginFieldLabel).tracking(Tracking.loginFieldLabel)
                .foregroundStyle(Color.textPrimary)
            LabeledInputField(placeholder: "학번을 입력해주세요", text: $viewModel.studentId, keyboardType: .numberPad)
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Text("비밀번호")
                    .font(.loginFieldLabel).tracking(Tracking.loginFieldLabel)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                    Text("비밀번호는 서버에 저장되지 않아요!")
                        .font(.loginCaption).tracking(Tracking.loginCaption)
                        .foregroundStyle(Color.textSecondary)
                }
                
            }
            LabeledInputField(placeholder: "비밀번호를 입력해주세요", text: $viewModel.password, isSecure: true)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}
