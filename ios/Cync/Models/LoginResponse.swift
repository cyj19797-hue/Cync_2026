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
//  profile comes from `GET /api/me`); only `accessToken` matters.
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
}
