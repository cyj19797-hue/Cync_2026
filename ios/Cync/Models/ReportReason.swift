//
//  ReportReason.swift
//  test
//
//  Data model backing "커뮤니티 - 신고사유입력" — the 5 selectable reasons a
//  report can cite. Selecting `.other` reveals a free-text field (see
//  "커뮤니티 - 신고사유입력(기타선택)"), handled in ReportReasonSheet.
//

import SwiftUI

enum ReportReason: String, CaseIterable, Identifiable, Codable {
    case spam = "스팸 또는 광고성 게시글"
    case hateSpeech = "욕설 또는 혐오 표현"
    case privacyExposure = "개인정보 노출"
    case misinformation = "허위 정보"
    case other = "기타"

    var id: String { rawValue }

    var localizedKey: LocalizedStringKey { LocalizedStringKey(rawValue) }
}
