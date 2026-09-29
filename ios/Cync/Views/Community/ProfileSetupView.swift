//
//  ProfileSetupView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `257:6758` ("프로필 설정").
//
//  One-time, per-account gate shown by `CommunityView` the first time the
//  user opens "5 커뮤니티" without ever having saved a nickname
//  (`NicknameSetupStore`, since the backend always returns a non-empty
//  `nickname` — see that type's header comment for why this can't be
//  derived from `GET /api/me` alone). Reuses the exact same "1-5 로그인"
//  layout building blocks — no logo, just a leading title, a bordered
//  `LabeledInputField`, and an `eventAccent` `PrimaryActionButton` pinned to
//  the bottom — plus `LoginView`'s `ErrorDialog` overlay pattern instead of
//  a system `.alert(...)` for a failed save (e.g. duplicate nickname).
//
//  NOTE (design deviation): Figma's input box for this screen (node
//  `257:6771`, literally still named "학번입력" — "student id input") carries
//  the placeholder text "ex) 25123456, E123456, S1234566", i.e. the *login
//  screen's* student-id example — copy-pasted from that component without
//  being updated for a nickname field. That placeholder would be actively
//  confusing here, so this screen uses a real nickname placeholder instead.
//

import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var viewModel: ProfileSetupViewModel
    let onComplete: () -> Void

    init(profile: UserProfile, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ProfileSetupViewModel(
            currentNickname: profile.nickname,
            currentColor: profile.profileColor
        ))
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(.profileSetupTitle)
                .font(.appIntroTitle).tracking(Tracking.appIntroTitle)
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.cardInset) {
                avatar
                nicknameField
            }

            Spacer(minLength: Spacing.sm)

            PrimaryActionButton(
                titleKey: .commonContinue,
                isEnabled: viewModel.canSubmit && !viewModel.isSubmitting,
                tint: .eventAccent
            ) {
                Task {
                    if await viewModel.submit() {
                        onComplete()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
        .overlay {
            if let errorMessage = viewModel.errorMessage {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    ErrorDialog(
                        titleKey: .profileSetupSaveFailedTitle,
                        message: errorMessage,
                        onConfirm: { viewModel.errorMessage = nil }
                    )
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
    }

    private var avatar: some View {
        Circle()
            .fill(Color.surface)
            .frame(width: 105, height: 105)
            .frame(maxWidth: .infinity)
    }

    private var nicknameField: some View {
        VStack(alignment: .leading, spacing: Spacing.cardInset) {
            Text(.commonNickname)
                .font(.loginFieldLabel).tracking(Tracking.loginFieldLabel)
                .foregroundStyle(Color.textPrimary)
            LabeledInputField(placeholder: .profileSetupNicknamePlaceholder, text: $viewModel.nickname)
        }
    }
}

#Preview {
    ProfileSetupView(profile: .mock) {}
}
