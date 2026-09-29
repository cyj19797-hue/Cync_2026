//
//  AgreementDetailView.swift
//  Cync
//
//  Figma: "26 2 창학" file — one reusable layout backing all three "1-4
//  이용약관 동의" detail screens: "이용약관 세부사항" (`253:5227`), "개인정보
//  처리방침세부사항" (`254:5312`), and "알림 설정 세부사항" (`282:2104`). All
//  three share the same structure (centered title + a bordered, scrollable
//  text card + a "확인" button), differing only in title/title-weight/body
//  copy, so one parameterized view backs all three instead of three
//  near-duplicate files.
//
//  Figma has no back chevron here — "확인" is the only way back, so this is
//  presented as a plain full-screen overlay from `TermsAgreementView`
//  (`ZStack` + optional state), the same pattern `NoticeListView` already
//  uses for "2-1 공지글", rather than a `NavigationStack` push that would
//  need chrome this design doesn't have.
//
//  The content card is always given the remaining flexible height (`.frame
//  (maxHeight: .infinity)`), even though Figma's "알림 설정 세부사항" mock
//  only sizes its card to its short text. That's a deliberate deviation:
//  a fixed/shrink-to-fit card wouldn't adapt across device sizes the way
//  step 5 of this task asks for, and a flexible card still degrades
//  gracefully (short text just sits top-aligned in more breathing room).
//

import SwiftUI

struct AgreementDetailView: View {
    let titleKey: LocalizedStringKey
    var titleFont: Font = .dialogTitle
    let bodyText: String
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titleKey)
                .font(titleFont)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(Spacing.cardInset)

            ScrollView {
                Text(bodyText)
                    .font(.termsItemLabel).tracking(Tracking.termsItemLabel)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.calendarCard)
                    .strokeBorder(Color.borderLight)
            }

            PrimaryActionButton(
                titleKey: "확인",
                tint: .eventAccent,
                font: .loginButtonLabel,
                tracking: Tracking.loginButtonLabel,
                borderColor: .eventAccentLight,
                enabledCornerRadius: Radius.agreementCard,
                action: onConfirm
            )
            .padding(Spacing.xs)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appBackground)
    }
}

#Preview("이용약관") {
    AgreementDetailView(
        titleKey: "이용약관",
        bodyText: LegalDocumentContent.termsOfService,
        onConfirm: {}
    )
}

#Preview("알림 설정") {
    AgreementDetailView(
        titleKey: "[선택] 중요한 학과 소식 알림",
        titleFont: .termsItemLabel,
        bodyText: LegalDocumentContent.notificationInfo,
        onConfirm: {}
    )
}
