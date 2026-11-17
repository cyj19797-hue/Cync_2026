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
//  Admins also get the pending report count (`GET /api/reports/pending`)
//  for the red dot on the top bar's 신고 관리 button; a failure there only
//  hides the dot.
//
//  Search is client-side only (`filteredPosts`) — the API has no search
//  endpoint, and the feed already holds every post it fetched.
//

import Combine
import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var searchText: String = ""
    @Published private(set) var isBanned = false
    @Published private(set) var needsNicknameSetup = false
    @Published private(set) var profile: UserProfile?
    /// Stays `false` until the first fetch finishes, so the empty state
    /// doesn't flash before the feed has actually loaded.
    @Published private(set) var hasLoaded = false
    @Published var errorMessage: String?
    /// Unresolved reports — admins only; 0 otherwise.
    @Published private(set) var pendingReportCount = 0

    /// 신고 관리 button — `role == "ADMIN"` from `CurrentUserSession`.
    var isAdmin: Bool { CurrentUserSession.shared.profile?.isAdmin ?? false }

    var filteredPosts: [CommunityPost] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return posts }
        return posts.filter { $0.matches(query) }
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func load() async {
        do {
            async let postsTask = CyncAPI.fetchPosts()
            async let profileTask = CurrentUserSession.shared.refresh()
            let (fetchedPosts, profile) = try await (postsTask, profileTask)
            posts = fetchedPosts.sorted { $0.createdAt > $1.createdAt }
            isBanned = profile.currentlyBanned
            self.profile = profile
            needsNicknameSetup = !NicknameSetupStore.hasCompletedSetup(for: profile.studentId)
            await refreshPendingReports()
        } catch is CancellationError {
            // Pull-to-refresh released early / view went away — not an error.
        } catch let error as URLError where error.code == .cancelled {
            // Same, surfaced by URLSession instead of the task.
        } catch {
            errorMessage = error.localizedDescription
        }
        hasLoaded = true
    }

    /// Re-counts unresolved reports (admins only) — on load and when the
    /// admin comes back from 신고 관리.
    func refreshPendingReports() async {
        guard isAdmin else {
            pendingReportCount = 0
            return
        }
        if let reports = try? await CyncAPI.fetchPendingReports() {
            pendingReportCount = reports.count
        }
    }

    func completeNicknameSetup() {
        needsNicknameSetup = false
    }
}
