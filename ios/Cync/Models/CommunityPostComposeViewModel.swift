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
    /// Figma shows the "익명" checkbox unchecked by default.
    @Published var isAnonymous: Bool = false
    @Published var errorMessage: String?
    @Published var isSubmitting = false

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit() async -> CommunityPost? {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            return try await CyncAPI.createPost(title: title, content: content, isAnonymous: isAnonymous)
        } catch {
            errorMessage = "게시글을 등록하지 못했습니다. \(error.localizedDescription)"
            return nil
        }
    }
}
