//
//  LoginResponse.swift
//  Cync
//
//  Decodes `POST /api/auth/login`'s response — mirrors the backend's
//  `TokenResponse`/`SejongMemberInfo` DTOs (`backend/.../dto/TokenResponse.java`,
//  `.../dto/SejongMemberInfo.java`). Login authenticates against the actual
//  Sejong University portal (`SejongPortalLoginService`), not a local
//  password — `memberInfo` is scraped from the portal on success.
//
//  Every `memberInfo` field is optional: the admin login
//  (`AdminLoginService`) fills only major/studentId/name and sends the
//  rest as null, and a portal page missing a field would do the same.
//  Requiring them made a successful admin login fail to decode — and read
//  as "wrong id/password". Nothing in the app reads `memberInfo` (the
//  profile comes from `GET /api/me`); `accessToken` and `termsAgreed`
//  are what matter.
//

import Foundation

struct SejongMemberInfo: Decodable {
    let major: String?
    let studentId: String?
    let name: String?
    let grade: String?
    let status: String?
    let completedSemester: String?
}

struct LoginResponse: Decodable {
    let accessToken: String
    let tokenType: String?
    let memberInfo: SejongMemberInfo?
    /// Already agreed to the required terms — false sends the student to
    /// `TermsAgreementView` before the main tabs. Missing → false.
    let termsAgreed: Bool

    init(accessToken: String, tokenType: String?, memberInfo: SejongMemberInfo?, termsAgreed: Bool) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.memberInfo = memberInfo
        self.termsAgreed = termsAgreed
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken, tokenType, memberInfo, termsAgreed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try c.decode(String.self, forKey: .accessToken)
        tokenType = try c.decodeIfPresent(String.self, forKey: .tokenType)
        memberInfo = try c.decodeIfPresent(SejongMemberInfo.self, forKey: .memberInfo)
        termsAgreed = try c.decodeIfPresent(Bool.self, forKey: .termsAgreed) ?? false
    }
}
