//
//  CommunityPostComposeViewModel.swift
//  Cync
//
//  State for CommunityPostComposeView. `submit()` calls the real
//  `POST /api/posts` (`docs/API.md` §2) — `nickname`/`color` are
//  intentionally omitted from the request so the server applies the
//  caller's profile defaults, per the doc's own guidance.
//

import Combine
import Foundation

@MainActor
final class CommunityPostComposeViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    /// Starts from the last choice made on this screen (unchecked the
    /// first time, as in Figma). Kept apart from the comment box's own
    /// remembered choice.
    @Published var isAnonymous: Bool = UserDefaults.standard.bool(forKey: CommunityPostComposeViewModel.anonymousKey) {
        didSet { UserDefaults.standard.set(isAnonymous, forKey: Self.anonymousKey) }
    }
    @Published var errorMessage: String?
    @Published var isSubmitting = false

    private static let anonymousKey = "postComposePostsAnonymously"

    var isTitleEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isContentEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSubmit: Bool {
        !isTitleEmpty && !isContentEmpty
    }

    /// Anything typed at all (even only spaces) — leaving then asks first.
    var hasInput: Bool {
        !title.isEmpty || !content.isEmpty
    }

    func submit() async -> CommunityPost? {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            return try await CyncAPI.createPost(title: title, content: content, isAnonymous: isAnonymous)
        } catch {
            errorMessage = String(appLocalized: .communityPostFailed(error.localizedDescription))
            return nil
        }
    }
}
