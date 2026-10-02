//
//  LegalDocumentContent.swift
//  Cync
//
//  Localized plain-text bodies (ko/en, `legal.*` keys in
//  `Localizable.xcstrings`) for the three "1-4 이용약관 동의" detail screens
//  (이용약관 세부사항 `253:5227`, 개인정보 처리방침세부사항 `254:5312`, 알림
//  설정 세부사항 `282:2104`) — pulled out of the view file since they're this
//  long. Figma's rich text (numbered/bulleted lists) is flattened to plain
//  `•`/`N.`-prefixed lines rather than built as `AttributedString`, since
//  `AgreementDetailView` just needs to show placeholder legal copy, not
//  reproduce Figma's exact list-rendering markup.
//

import Foundation

enum LegalDocumentContent {
    static var termsOfService: String { String(localized: .legalTermsOfService) }
    static var privacyPolicy: String { String(localized: .legalPrivacyPolicy) }
    static var notificationInfo: String { String(localized: .legalNotificationInfo) }
}
