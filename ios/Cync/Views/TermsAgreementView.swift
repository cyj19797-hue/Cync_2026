//
//  TermsAgreementView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `240:1463` ("1-4 이용약관 동의"), reworked
//  for the server-recorded agreement: shown right after login, once per
//  account, only while `SessionStore.entryState == .needsTermsAgreement`
//  (the server's `termsAgreed` is false). It's a root screen in
//  `CyncApp`'s `RootView`, so there's no back button and no swipe out —
//  the only ways on are agreeing or logging out.
//
//  Both items are required, so there are no checkboxes: one button agrees
//  to both (`POST /api/me/terms-agreement`).
//  - Title + subtitle (same styles as before).
//  - "[필수] 이용약관 ›" / "[필수] 개인정보 처리방침 ›" in the same card
//    (`AgreementItemRow` without a checkbox); a row opens the full text in
//    `AgreementDetailView`, as before.
//  - A small gray line saying the button means agreeing to both.
//  - "모두 동의하고 시작하기" (`PrimaryActionButton`, always enabled):
//    spins and ignores taps while the request runs; on success the main
//    tabs show (`SessionStore` moves to `.ready`); on failure an
//    `ErrorDialog`, and the student can try again.
//  - "동의하지 않고 로그아웃" → `SessionStore.logOut()` → login screen.
//
//  The old optional "알림 수신 동의" row is gone — it wasn't stored
//  anywhere; alerts are set in 설정 > 알림 설정.
//

import SwiftUI

struct TermsAgreementView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var isAgreeing: Bool
    @State private var errorMessage: String?
    @State private var presentedDetail: AgreementDetail?

    private enum AgreementDetail {
        case terms, privacyPolicy
    }

    /// The parameters are for previews (loading / failed states).
    init(isAgreeing: Bool = false, errorMessage: String? = nil) {
        _isAgreeing = State(initialValue: isAgreeing)
        _errorMessage = State(initialValue: errorMessage)
    }

    var body: some View {
        ZStack {
            mainContent

            if let presentedDetail {
                detailView(for: presentedDetail)
                    .transition(.opacity)
                    .zIndex(1)
            }

            if let errorMessage {
                ZStack {
                    Color.dimOverlayStrong
                        .ignoresSafeArea()
                    ErrorDialog(titleKey: .commonError, message: errorMessage) {
                        self.errorMessage = nil
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .animation(.default, value: presentedDetail == nil)
        .animation(.easeOut(duration: 0.2), value: errorMessage)
        #if DEBUG
        .task {
            // `-debugAgree` / `-debugDecline` (MockServer.swift).
            try? await Task.sleep(for: .seconds(1))
            if MockServer.autoAgreesToTerms { agree() }
            if MockServer.autoDeclinesTerms { sessionStore.logOut() }
        }
        #endif
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            subtitle
            agreementCard
            notice

            Spacer(minLength: 0)

            agreeButton
                .padding(.top, Spacing.xs)
            declineButton
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appBackground)
    }

    private var title: some View {
        Text(.termsTitle)
            .font(.termsAgreementTitle).tracking(Tracking.termsAgreementTitle)
            .foregroundStyle(Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.cardInset)
    }

    private var subtitle: some View {
        Text(.termsSubtitle)
            .font(.termsAgreementSubtitle).tracking(Tracking.termsAgreementSubtitle)
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.cardInset)
    }

    private var agreementCard: some View {
        VStack(spacing: 0) {
            AgreementItemRow(titleKey: .termsRequiredTerms) {
                presentedDetail = .terms
            }

            Divider().overlay(Color.borderLight)

            AgreementItemRow(titleKey: .termsRequiredPrivacy) {
                presentedDetail = .privacyPolicy
            }
        }
        .padding(.horizontal, Spacing.cardInset)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.agreementCard)
                .strokeBorder(Color.borderLight)
        }
        .padding(.vertical, Spacing.cardInset)
    }

    private var notice: some View {
        Text(.termsAgreeAllNotice)
            .font(.loginCaption).tracking(Tracking.loginCaption)
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.cardInset)
    }

    private var agreeButton: some View {
        PrimaryActionButton(
            titleKey: .termsAgreeAndStart,
            tint: .buttonAccent,
            // Hidden (not removed) while the spinner shows, so the button
            // keeps its size.
            labelColor: isAgreeing ? .clear : .white,
            borderColor: .eventAccentLight,
            enabledCornerRadius: Radius.agreementCard,
            action: agree
        )
        .overlay {
            if isAgreeing {
                ProgressView()
                    .tint(Color.white)
                    .accessibilityLabel(Text(.termsAgreeAndStart))
            }
        }
        .disabled(isAgreeing)
    }

    private var declineButton: some View {
        Button {
            sessionStore.logOut()
        } label: {
            Text(.termsDeclineAndLogout)
                .font(.loginCaption).tracking(Tracking.loginCaption)
                .foregroundStyle(Color.textSecondary)
                .underline()
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAgreeing)
    }

    private func agree() {
        guard !isAgreeing else { return }
        isAgreeing = true
        Task {
            defer { isAgreeing = false }
            do {
                try await sessionStore.agreeToTerms()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func detailView(for detail: AgreementDetail) -> some View {
        switch detail {
        case .terms:
            AgreementDetailView(
                titleKey: .termsTermsOfService,
                bodyText: LegalDocumentContent.termsOfService
            ) {
                presentedDetail = nil
            }
        case .privacyPolicy:
            AgreementDetailView(
                titleKey: .termsPrivacyPolicy,
                bodyText: LegalDocumentContent.privacyPolicy
            ) {
                presentedDetail = nil
            }
        }
    }
}

#Preview("약관 화면") {
    TermsAgreementView()
        .environmentObject(SessionStore(previewState: .needsTermsAgreement))
}

#Preview("동의 중") {
    TermsAgreementView(isAgreeing: true)
        .environmentObject(SessionStore(previewState: .needsTermsAgreement))
}

#Preview("동의 실패") {
    TermsAgreementView(errorMessage: "서버 오류가 발생했어요. (500)")
        .environmentObject(SessionStore(previewState: .needsTermsAgreement))
}
