//
//  TermsAgreementView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `240:1463` ("1-4 이용약관 동의"). Shown after
//  `AppIntroView`'s "연결하기", before `LoginView` — `CyncApp`'s `RootView`
//  keeps this up until "세종대학교 계정으로 시작하기" is tapped, matching
//  Figma's own 1-3 → 1-4 → 1-5 screen numbering.
//
//  No pre-existing view/view model for this screen (checked: nothing in the
//  codebase referenced "이용약관"/"Terms" before this), so there was no prior
//  logic to preserve — this is a new screen built straight from Figma.
//
//  Reuses existing components/tokens throughout instead of one-offs:
//  `AgreementItemRow` (+ its shared `CheckboxSquare`) for each agreement
//  line, `CheckboxToggle` for the "전체 동의" master checkbox (its filled
//  `eventAccent`/`eventAccentLight`/white-check styling already matches
//  "1-5 로그인"'s "학번 기억하기" checkbox exactly), `NavigationChevron` for
//  the per-row disclosure hint, and `PrimaryActionButton` (with its
//  `enabledCornerRadius`/`isUnderlined` overrides — see that file) for the
//  bottom button instead of hand-rolling either.
//
//  "동의 항목" chevrons open `AgreementDetailView` (이용약관/개인정보
//  처리방침세부사항/알림 설정 세부사항) as a full-screen overlay — see that
//  file's header for why an overlay instead of a `NavigationStack` push.
//
//  No UIKit anywhere on this screen.
//

import SwiftUI

struct TermsAgreementView: View {
    let onContinue: () -> Void

    @State private var isTermsAgreed = false
    @State private var isPrivacyPolicyAgreed = false
    @State private var isMarketingAgreed = false
    @State private var presentedDetail: AgreementDetail?

    private enum AgreementDetail {
        case terms, privacyPolicy, notification
    }

    private var isAllAgreed: Bool {
        isTermsAgreed && isPrivacyPolicyAgreed && isMarketingAgreed
    }

    /// Only the two "필수" items gate continuing — "중요한 학과 소식 알림" is
    /// "선택" (optional), matching its Figma label.
    private var canContinue: Bool {
        isTermsAgreed && isPrivacyPolicyAgreed
    }

    var body: some View {
        ZStack {
            mainContent

            if let presentedDetail {
                detailView(for: presentedDetail)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.default, value: presentedDetail == nil)
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            subtitle
            essentialSection
            optionalSection
            agreeAllRow

            Spacer(minLength: 0)

            PrimaryActionButton(
                titleKey: .termsStart,
                isEnabled: canContinue,
                tint: .eventAccent,
                borderColor: .eventAccentLight,
                enabledCornerRadius: Radius.agreementCard,
                isUnderlined: true,
                action: onContinue
            )
            .padding(Spacing.xs)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appBackground)
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
        case .notification:
            AgreementDetailView(
                titleKey: .termsOptionalNotification,
                titleFont: .termsItemLabel,
                bodyText: LegalDocumentContent.notificationInfo
            ) {
                presentedDetail = nil
            }
        }
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

    private var essentialSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.termsRequiredSection)
                .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                AgreementItemRow(titleKey: .termsRequiredTerms, isAgreed: $isTermsAgreed) {
                    presentedDetail = .terms
                }

                Divider().overlay(Color.borderLight)

                AgreementItemRow(titleKey: .termsRequiredPrivacy, isAgreed: $isPrivacyPolicyAgreed) {
                    presentedDetail = .privacyPolicy
                }
            }
            .padding(.horizontal, Spacing.cardInset)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.agreementCard)
                    .strokeBorder(Color.borderLight)
            }
        }
        .padding(Spacing.cardInset)
    }

    private var optionalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.termsOptionalSection)
                .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
                .foregroundStyle(Color.textPrimary)

            AgreementItemRow(titleKey: .termsOptionalNotification, isAgreed: $isMarketingAgreed) {
                presentedDetail = .notification
            }
            .padding(.horizontal, Spacing.cardInset)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.agreementCard)
                    .strokeBorder(Color.borderLight)
            }
        }
        .padding(Spacing.cardInset)
    }

    private var agreeAllRow: some View {
        CheckboxToggle(
            isChecked: Binding(
                get: { isAllAgreed },
                set: { newValue in
                    isTermsAgreed = newValue
                    isPrivacyPolicyAgreed = newValue
                    isMarketingAgreed = newValue
                }
            ),
            titleKey: .termsAgreeAll,
            style: .accent,
            font: .termsAgreeAllLabel,
            tracking: Tracking.termsAgreeAllLabel
        )
        .padding(Spacing.button)
    }
}

#Preview {
    TermsAgreementView(onContinue: {})
}
