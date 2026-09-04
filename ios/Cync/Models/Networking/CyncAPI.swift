//
//  CyncAPI.swift
//  Cync
//
//  Networking layer for the endpoints documented in `docs/API.md`
//  ("Cync API 명세 업데이트 (2026-08-22)") — the Spring Boot backend deployed
//  on Azure. That doc, not the `backend/` folder in this repo, is the real
//  server: `backend/` is an unrelated NestJS scaffold (`/health` + an AI
//  proxy) that these endpoints aren't part of.
//
//  Every endpoint here needs `Authorization: Bearer <accessToken>`, but
//  this app has no login screen yet, so `accessToken` starts `nil` and
//  every call below will fail (401/403) until a future login flow calls
//  `KeychainTokenStore.save`. See the iOS/API gap table for what's missing
//  before that's possible.
//

import Foundation

enum CyncAPIError: LocalizedError {
    case unauthorized
    case badStatus(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "로그인이 필요합니다."
        case .badStatus(let code):
            return "서버 오류가 발생했습니다. (HTTP \(code))"
        case .decoding:
            return "서버 응답을 처리하지 못했습니다."
        }
    }
}

/// Minimal Keychain-backed store for the login access token — matches the
/// `KeychainHelper.load("accessToken")` assumption `docs/API.md` makes.
/// Nothing calls `save` yet since there's no login flow; it exists so that
/// flow has somewhere to put the token that every `CyncAPI` request below
/// already reads from.
enum KeychainTokenStore {
    private static let account = "accessToken"
    private static let service = "com.cync.app"

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = Data(token.utf8)
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum CyncAPI {
    static let baseURL = URL(string: "https://cync-backend-evena5hbhjevdsc8.koreacentral-01.azurewebsites.net")!

    static var accessToken: String? = KeychainTokenStore.load()

    private static func authorizedRequest(path: String, method: String, query: [String: String] = [:]) -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private static func formBody(_ params: [String: String]) -> Data {
        params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)!
    }

    private static func checkStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw CyncAPIError.unauthorized
            }
            throw CyncAPIError.badStatus(http.statusCode)
        }
    }

    private static func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkStatus(response)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CyncAPIError.decoding
        }
    }

    private static func send(_ request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)
        try checkStatus(response)
    }

    // MARK: - 1. 닉네임 / 프로필 색상

    static func fetchMyProfile() async throws -> UserProfile {
        try await send(authorizedRequest(path: "/api/me", method: "GET"))
    }

    static func updateMyProfile(nickname: String, color: ProfileColor) async throws -> UserProfile {
        try await send(authorizedRequest(
            path: "/api/me/profile",
            method: "PUT",
            query: ["nickname": nickname, "profileColor": color.rawValue]
        ))
    }

    // MARK: - 2. 게시글 / 댓글

    static func fetchPosts() async throws -> [CommunityPost] {
        try await send(authorizedRequest(path: "/api/posts", method: "GET"))
    }

    static func createPost(title: String, content: String, isAnonymous: Bool) async throws -> CommunityPost {
        var request = authorizedRequest(path: "/api/posts", method: "POST")
        request.httpBody = formBody(["title": title, "content": content, "isAnonymous": String(isAnonymous)])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return try await send(request)
    }

    static func fetchComments(postId: Int) async throws -> [Comment] {
        try await send(authorizedRequest(path: "/api/posts/\(postId)/comments", method: "GET"))
    }

    static func createComment(
        postId: Int,
        content: String,
        parentCommentId: Int? = nil,
        isAnonymous: Bool
    ) async throws -> Comment {
        var params = ["content": content, "isAnonymous": String(isAnonymous)]
        if let parentCommentId { params["parentCommentId"] = String(parentCommentId) }

        var request = authorizedRequest(path: "/api/posts/\(postId)/comments", method: "POST")
        request.httpBody = formBody(params)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return try await send(request)
    }

    // MARK: - 3. 학생회공지

    static func fetchCouncilNotices() async throws -> [CouncilNotice] {
        try await send(authorizedRequest(path: "/api/notices/council", method: "GET"))
    }

    // MARK: - 4. 사물함

    static func fetchAllLockers() async throws -> [Locker] {
        try await send(authorizedRequest(path: "/api/lockers", method: "GET"))
    }

    static func fetchAvailableLockers() async throws -> [Locker] {
        try await send(authorizedRequest(path: "/api/lockers/available", method: "GET"))
    }

    static func applyLocker(id: Int) async throws -> Locker {
        try await send(authorizedRequest(path: "/api/lockers/\(id)/apply", method: "POST"))
    }

    // MARK: - 6. 학사일정

    static func fetchAcademicSchedules() async throws -> [AcademicSchedule] {
        try await send(authorizedRequest(path: "/api/academic-schedule", method: "GET"))
    }
}
