//
//  CommunityPostDetailViewModel.swift
//  Cync
//
//  Backs CommunityPostDetailView with the real `GET /api/posts/{id}/comments`
//  and `POST /api/posts/{id}/comments` calls (`docs/API.md` §2). Comments
//  aren't embedded in `CommunityPost` (the server doesn't return them from
//  the feed endpoint), so this view model owns its own `comments` array,
//  loaded once the detail screen appears.
//

import Combine
import Foundation

@MainActor
final class CommunityPostDetailViewModel: ObservableObject {
    @Published var post: CommunityPost
    @Published var comments: [Comment] = []
    @Published var errorMessage: String?

    init(post: CommunityPost) {
        self.post = post
    }

    func loadComments() async {
        do {
            comments = try await CyncAPI.fetchComments(postId: post.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Mock UI only has a single like state per user to simulate (no
    /// separate "did I like this" flag on the model, and no like/unlike API
    /// exists at all — see the gap table), so this just flips the count
    /// between 0 and 1 rather than truly incrementing, and never persists.
    func togglePostLike() {
        post.likeCount = post.likeCount > 0 ? 0 : 1
    }

    /// `comments` grouped back into top-level comments + their replies,
    /// oldest first — see `CommentThread.threads(from:)`.
    var commentThreads: [CommentThread] {
        CommentThread.threads(from: comments)
    }

    func toggleCommentLike(_ comment: Comment) {
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        comments[index].likeCount = comments[index].likeCount > 0 ? 0 : 1
    }

    /// Posts a new comment (or, with `parentCommentId` set, a reply) via
    /// `POST /api/posts/{id}/comments` and appends the server's response.
    /// No "익명" toggle exists in `CommentComposeView` yet (unlike the post
    /// composer), so every comment posts anonymously, matching this
    /// screen's previous local-only mock behavior (every comment showed
    /// "익명").
    func addComment(content: String, parentCommentId: Int? = nil) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let comment = try await CyncAPI.createComment(
                postId: post.id,
                content: trimmed,
                parentCommentId: parentCommentId,
                isAnonymous: true
            )
            comments.append(comment)
            post.commentCount += 1
        } catch {
            errorMessage = "댓글을 등록하지 못했습니다. \(error.localizedDescription)"
        }
    }
}

/// A top-level comment paired with its replies (comments whose
/// `parentCommentId` points back to it). The server only allows one level
/// of nesting, so replies aren't grouped recursively.
struct CommentThread: Identifiable {
    let comment: Comment
    let replies: [Comment]
    var id: Int { comment.id }

    /// Groups a flat `comments` array into oldest-first top-level threads,
    /// each carrying its own oldest-first replies.
    static func threads(from comments: [Comment]) -> [CommentThread] {
        let topLevel = comments
            .filter { $0.parentCommentId == nil }
            .sorted { $0.createdAt < $1.createdAt }

        return topLevel.map { top in
            let replies = comments
                .filter { $0.parentCommentId == top.id }
                .sorted { $0.createdAt < $1.createdAt }
            return CommentThread(comment: top, replies: replies)
        }
    }
}
