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

import Foundation

struct SejongMemberInfo: Decodable {
    let major: String
    let studentId: String
    let name: String
    let grade: String
    let status: String
    let completedSemester: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let memberInfo: SejongMemberInfo
}
