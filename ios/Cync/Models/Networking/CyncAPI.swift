//
//  CyncAPI.swift
//  Cync
//
//  Networking layer for the endpoints documented in `docs/API.md`
//  ("Cync API 명세 업데이트 (2026-08-22)") — the Spring Boot backend deployed
//  on Azure, now the same one under `backend/` in this repo
//  (`com.sejong.sjc_app`, superseding the older NestJS scaffold that used
//  to live there).
//
//  Every endpoint here needs `Authorization: Bearer <accessToken>`.
//  `login(studentId:password:)` below calls `backend/.../AuthController`'s
//  `POST /api/auth/login` (not yet in `docs/API.md`) and saves the token
//  via `KeychainTokenStore.save`; every other call fails (401/403) until
//  that's happened.
//

import Foundation

enum CyncAPIError: LocalizedError {
    case unauthorized
    case badStatus(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return String(appLocalized: .apiUnauthorized)
        case .badStatus(let code):
            return String(appLocalized: .apiServerError(code))
        case .decoding:
            return String(appLocalized: .apiDecoding)
        }
    }
}

/// Minimal Keychain-backed store for the login access token — matches the
/// `KeychainHelper.load("accessToken")` assumption `docs/API.md` makes.
/// `login(studentId:password:persistToken:)` saves here only when
/// "자동 로그인" is checked.
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
    static let baseURL = URL(string: "https://cync-backend.azurewebsites.net")!

    static var accessToken: String? = KeychainTokenStore.load()

    static func logout() {
        KeychainTokenStore.clear()
        accessToken = nil
    }

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

    /// For endpoints that answer with plain text instead of JSON.
    private static func sendText(_ request: URLRequest) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkStatus(response)
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - 0. 로그인

    /// `persistToken` is `LoginView`'s "자동 로그인" checkbox: `true` keeps
    /// the JWT in the Keychain so `SessionStore` can restore the session on
    /// next launch; `false` keeps it in memory only for this run.
    static func login(studentId: String, password: String, persistToken: Bool) async throws -> LoginResponse {
        var request = authorizedRequest(path: "/api/auth/login", method: "POST")
        request.httpBody = formBody(["id": studentId, "password": password])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let response: LoginResponse = try await send(request)
        if persistToken {
            KeychainTokenStore.save(response.accessToken)
        } else {
            KeychainTokenStore.clear()
        }
        accessToken = response.accessToken
        return response
    }

    /// Checks the account password by attempting a login with it — there's
    /// no dedicated verify endpoint. Leaves the stored session token alone
    /// (the new token in the response is discarded). Returns `false` for any
    /// HTTP error: the server answers a wrong password with 500, not 401, so
    /// it can't be told apart from other server errors. Network failures
    /// (no connection, timeout) still throw.
    static func verifyPassword(studentId: String, password: String) async throws -> Bool {
        var request = authorizedRequest(path: "/api/auth/login", method: "POST")
        request.httpBody = formBody(["id": studentId, "password": password])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return false }
        return (200..<300).contains(http.statusCode)
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

    /// One post — and the only call that bumps its view count (by 1 per
    /// call; the list doesn't count). The response already carries the new
    /// `viewCount` and this user's `likedByMe` (the token is sent, so the
    /// server knows who's asking). Call once per opening of the detail.
    static func fetchPostDetail(id: Int) async throws -> CommunityPost {
        try await send(authorizedRequest(path: "/api/posts/\(id)", method: "GET"))
    }

    /// Toggles this user's like: likes it if they hadn't, unlikes it if
    /// they had. The server answers in plain text ("좋아요 완료" /
    /// "좋아요 취소") with no updated count — returns `true` when it's now
    /// liked. Fails for a banned user or a missing post.
    @discardableResult
    static func togglePostLike(id: Int) async throws -> Bool {
        let message = try await sendText(authorizedRequest(path: "/api/posts/\(id)/like", method: "POST"))
        return message.contains("완료")
    }

    static func createPost(title: String, content: String, isAnonymous: Bool) async throws -> CommunityPost {
        var request = authorizedRequest(path: "/api/posts", method: "POST")
        request.httpBody = formBody(["title": title, "content": content, "isAnonymous": String(isAnonymous)])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return try await send(request)
    }

    /// Hard delete — the server removes the post's comments and likes with
    /// it. Allowed for the post's author or an ADMIN.
    static func deletePost(id: Int) async throws {
        try await send(authorizedRequest(path: "/api/posts/\(id)", method: "DELETE"))
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

    /// Soft delete — the server keeps the row with `deleted = true` (so
    /// replies under it survive) and answers with a plain-text body.
    /// Allowed for the comment's author or an ADMIN.
    static func deleteComment(id: Int) async throws {
        try await send(authorizedRequest(path: "/api/comments/\(id)", method: "DELETE"))
    }

    /// Moderator edit. NOT on the server yet — `CommentController` has no
    /// update endpoint; this follows the same shape as `PUT /api/posts/{id}`
    /// and fails (404/405) until the backend adds it.
    static func updateComment(id: Int, content: String) async throws -> Comment {
        var request = authorizedRequest(path: "/api/comments/\(id)", method: "PUT")
        request.httpBody = formBody(["content": content])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return try await send(request)
    }

    // MARK: - 9. 신고

    /// One endpoint for both posts and comments — `targetType` says which.
    /// The server rejects a second report of the same target by the same
    /// user, and reports of already-deleted targets.
    private static func report(targetType: String, targetId: Int, reason: ReportReason) async throws {
        var request = authorizedRequest(path: "/api/reports", method: "POST")
        request.httpBody = formBody([
            "targetType": targetType,
            "targetId": String(targetId),
            "reason": reason.rawValue
        ])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        try await send(request)
    }

    static func reportComment(id: Int, reason: ReportReason) async throws {
        try await report(targetType: "COMMENT", targetId: id, reason: reason)
    }

    static func reportPost(id: Int, reason: ReportReason) async throws {
        try await report(targetType: "POST", targetId: id, reason: reason)
    }

    // MARK: - 3. 학생회공지

    static func fetchCouncilNotices() async throws -> [CouncilNotice] {
        try await send(authorizedRequest(path: "/api/notices/council", method: "GET"))
    }

    // MARK: - 3b. 학과공지 (크롤링)

    static func fetchSchoolNotices() async throws -> [SchoolNotice] {
        try await send(authorizedRequest(path: "/api/notices/school", method: "GET"))
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
