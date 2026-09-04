//
//  CommunityViewModel.swift
//  Cync
//
//  Backs CommunityView with the real `GET /api/posts` call (`docs/API.md`
//  §2), plus a `GET /api/me` check so a banned user's "글쓰기" button can be
//  disabled up front instead of failing on submit (§5's recommended UX).
//

import Combine
import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published private(set) var isBanned = false
    @Published var errorMessage: String?

    func load() async {
        do {
            async let postsTask = CyncAPI.fetchPosts()
            async let profileTask = CurrentUserSession.shared.refresh()
            let (fetchedPosts, profile) = try await (postsTask, profileTask)
            posts = fetchedPosts.sorted { $0.createdAt > $1.createdAt }
            isBanned = profile.currentlyBanned
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
