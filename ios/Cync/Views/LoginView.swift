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
//  Changes from Figma (accessibility/UX review): the card heading is a
//  plain-color "세종대학교 계정으로 로그인" instead of a large accent "로그인"
//  that repeated the button; the button uses `accentStrong` so its white
//  label passes 4.5:1; the "not stored" hint moved under the password
//  field; the password field has a show/hide toggle and the focused field
//  gets an accent border; the card reaches the bottom of the screen.
//
//  A failed `submit()` shows `ErrorDialog` ("로그인 실패") as a dimmed-backdrop
//  overlay — same non-`.alert()` pattern the locker application dialogs use
//  — instead of the system `.alert(...)` this screen used to show.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var keyboard = KeyboardObserver()
    /// Natural height of the card's content, so the card's `ScrollView`
    /// is only as tall as what's in it (and scrolls only when squeezed).
    @State private var cardContentHeight: CGFloat = 0

    private var isKeyboardVisible: Bool { keyboard.height > 0 }

    private static let submitButtonID = "loginSubmit"

    var body: some View {
        VStack(spacing: 0) {
            // While typing, the logo steps aside so the whole card (button
            // included) fits above the keyboard; the spacer keeps the card
            // pinned to the bottom.
            if isKeyboardVisible {
                Spacer(minLength: Spacing.md)
            } else {
                logo
            }
            loginCard
                // The card claims its height first; the logo gets the rest.
                .layoutPriority(1)
        }
        .animation(.easeOut(duration: 0.25), value: isKeyboardVisible)
        .padding([.top, .horizontal], Spacing.md)
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
            // Up to 144pt, but free to shrink (e.g. with a large text size,
            // where the card is taller) instead of pushing the card down.
            .frame(maxWidth: 144, maxHeight: 144)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Scrolls only when it can't fit (large text sizes with the keyboard
    /// up); when the keyboard comes up it scrolls to the 로그인 button so
    /// it's never left hidden underneath.
    private var loginCard: some View {
        ScrollViewReader { proxy in
            ScrollView {
                cardContent
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardContentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .frame(maxHeight: cardContentHeight > 0 ? cardContentHeight : nil)
            .onChange(of: isKeyboardVisible) { _, isVisible in
                guard isVisible else { return }
                withAnimation { proxy.scrollTo(Self.submitButtonID, anchor: .bottom) }
            }
        }
        // The card runs down under the home indicator to the screen's
        // bottom edge (the fill and border both ignore the bottom safe
        // area), so there's no stray border line or white strip under it.
        // Content keeps to the safe area, so the button never sits under
        // the home indicator.
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Radius.card, topTrailingRadius: Radius.card)
                .fill(Color.gray50)
                .overlay {
                    UnevenRoundedRectangle(topLeadingRadius: Radius.card, topTrailingRadius: Radius.card)
                        .strokeBorder(Color.gray200)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(.loginTitle)
                .font(.loginTitle).tracking(Tracking.loginTitle)
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.md) {
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
            .padding(.bottom, Spacing.md)

            // Disabled (gray) while either field is empty; while the
            // request runs, the label reads "로그인 중…" so the tap visibly
            // registered.
            PrimaryActionButton(
                titleKey: viewModel.isSubmitting ? .loginSubmitting : .loginSubmit,
                isEnabled: viewModel.canSubmit && !viewModel.isSubmitting,
                tint: .accentStrong,
                action: submit
            )
            .id(Self.submitButtonID)
        }
        .padding(Spacing.md)
    }

    private var studentIdField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.loginStudentId)
                .font(.loginFieldLabel).tracking(Tracking.loginFieldLabel)
                .foregroundStyle(Color.textPrimary)
            // Number pad has no return key, so there's no "다음" here —
            // tapping the password field moves on.
            LabeledInputField(
                placeholder: .loginStudentIdPlaceholder,
                text: $viewModel.studentId,
                keyboardType: .numberPad,
                textContentType: .username
            )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.loginPassword)
                .font(.loginFieldLabel).tracking(Tracking.loginFieldLabel)
                .foregroundStyle(Color.textPrimary)

            LabeledInputField(
                placeholder: .loginPasswordPlaceholder,
                text: $viewModel.password,
                isSecure: true,
                textContentType: .password,
                submitLabel: .go,
                onSubmit: submit
            )

            // Helper text under the field rather than beside the label, so
            // a longer translation wraps on its own line.
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Image(systemName: "lock")
                    .accessibilityHidden(true)
                Text(.loginPasswordNotStored)
                    .tracking(Tracking.loginCaption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.loginCaption)
            .foregroundStyle(Color.textSecondary)
        }
    }

    private func submit() {
        guard viewModel.canSubmit, !viewModel.isSubmitting else { return }
        Task {
            if await viewModel.submit() {
                sessionStore.logIn()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}
