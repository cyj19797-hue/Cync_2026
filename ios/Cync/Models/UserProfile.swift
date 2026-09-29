//
//  UserProfile.swift
//  Cync
//
//  Data model backing the "6 - 설정" (Settings / MyPage) screen's profile
//  summary card — now the real `GET /api/me` / `PUT /api/me/profile` shape
//  from `docs/API.md`, not just a local nickname.
//

import SwiftUI

struct UserProfile: Codable {
    var studentId: String
    var name: String
    var role: String
    var nickname: String
    var profileColor: ProfileColor
    var banned: Bool
    var banExpiresAt: String?
    var banReason: String?
    var currentlyBanned: Bool
}

/// The 9-color palette `PUT /api/me/profile` accepts.
enum ProfileColor: String, CaseIterable, Codable {
    case red = "RED", orange = "ORANGE", yellow = "YELLOW", green = "GREEN"
    case mint = "MINT", blue = "BLUE", purple = "PURPLE", pink = "PINK", gray = "GRAY"

    var swatch: Color {
        switch self {
        case .red: return .profileRed
        case .orange: return .profileOrange
        case .yellow: return .profileYellow
        case .green: return .profileGreen
        case .mint: return .profileMint
        case .blue: return .profileBlue
        case .purple: return .profilePurple
        case .pink: return .profilePink
        case .gray: return .profileGray
        }
    }
}

extension UserProfile {
    /// Preview/placeholder data — the real app always loads this from
    /// `GET /api/me` (see `SettingsViewModel.loadProfile()`).
    static let mock = UserProfile(
        studentId: "20231234",
        name: "홍길동",
        role: "STUDENT",
        nickname: "코딩하는펭귄",
        profileColor: .blue,
        banned: false,
        banExpiresAt: nil,
        banReason: nil,
        currentlyBanned: false
    )
}

