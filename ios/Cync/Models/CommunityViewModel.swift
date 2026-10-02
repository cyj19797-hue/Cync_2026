//
//  CommunityViewModel.swift
//  Cync
//
//  Backs CommunityView with the real `GET /api/posts` call (`docs/API.md`
//  §2), plus a `GET /api/me` check so a banned user's "글쓰기" button can be
//  disabled up front instead of failing on submit (§5's recommended UX).
//
//  That same `GET /api/me` call also drives `needsNicknameSetup` —
//  `CommunityView`'s one-time `ProfileSetupView` gate (see
//  `NicknameSetupStore`'s header comment for why this can't be derived from
//  the profile response's `nickname` field alone).
//

import Combine
import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published private(set) var isBanned = false
    @Published private(set) var needsNicknameSetup = false
    @Published private(set) var profile: UserProfile?
    @Published var errorMessage: String?

    func load() async {
        do {
            async let postsTask = CyncAPI.fetchPosts()
            async let profileTask = CurrentUserSession.shared.refresh()
            let (fetchedPosts, profile) = try await (postsTask, profileTask)
            posts = fetchedPosts.sorted { $0.createdAt > $1.createdAt }
            isBanned = profile.currentlyBanned
            self.profile = profile
            needsNicknameSetup = !NicknameSetupStore.hasCompletedSetup(for: profile.studentId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeNicknameSetup() {
        needsNicknameSetup = false
    }
}
