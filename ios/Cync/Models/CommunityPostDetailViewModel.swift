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
//  Also owns:
//    - comment author labels ("익명1", "글쓴이") — `CommentAuthorLabel`
//    - the ⋮ menu's per-viewer actions and their API calls (delete via
//      `DELETE /api/comments/{id}`, report via `POST /api/reports`, and a
//      moderator edit whose endpoint the server doesn't have yet)
//    - "번역 보기" state + cache (see PostTranslation.swift)
//

import Combine
import Foundation

@MainActor
final class CommunityPostDetailViewModel: ObservableObject {
    enum TranslationPhase: Equatable {
        case original, loading, translated
    }

    @Published var post: CommunityPost
    @Published var comments: [Comment] = []
    @Published var errorMessage: String?
    /// What a report that just went through was about, to show the
    /// matching "신고 완료" popup. `nil` when there's nothing to show.
    @Published var submittedReport: ReportTargetKind?
    /// Set once this post has been deleted — the view pops back to the list.
    @Published private(set) var didDeletePost = false
    @Published private(set) var isSubmittingComment = false
    /// The newest comment this user posted — the view scrolls to it.
    @Published private(set) var lastPostedCommentId: Int?
    @Published private(set) var currentUser: UserProfile?

    @Published private(set) var translationPhase: TranslationPhase = .original
    @Published private(set) var translation: TranslatedPost?
    /// Bumped to ask `.postTranslationTask` for a fresh translation.
    @Published private(set) var translationRequestID = 0

    /// Server roles allowed to edit/delete anyone's comment. The backend
    /// only defines `USER` / `ADMIN` today — add the 부방장 role's name
    /// here once the server has one.
    private static let moderatorRoles: Set<String> = ["ADMIN"]

    /// The detail request (which bumps the view count) has been made for
    /// this opening — never again, even if the view's task re-runs.
    private var hasRecordedView = false
    /// A like request is in flight — further taps wait for it.
    private var isTogglingLike = false

    init(post: CommunityPost) {
        self.post = post
        self.currentUser = CurrentUserSession.shared.profile
    }

    /// `GET /api/posts/{id}`: counts this opening as one view and swaps in
    /// the fresh post (new `viewCount`, current `likeCount`/`likedByMe`).
    /// Once per detail screen. On failure the list's copy stays on screen
    /// — nothing the user needs to act on.
    func recordViewAndRefresh() async {
        guard !hasRecordedView else { return }
        hasRecordedView = true
        if let fresh = try? await CyncAPI.fetchPostDetail(id: post.id) {
            post = fresh
        }
    }

    func loadComments() async {
        do {
            comments = try await CyncAPI.fetchComments(postId: post.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        if currentUser == nil {
            currentUser = try? await CurrentUserSession.shared.refresh()
        }
    }

    /// `POST /api/posts/{id}/like` toggles on the server. The heart and
    /// count change right away (the response has no count to wait for)
    /// and go back if the request fails — e.g. a banned user.
    func togglePostLike() {
        guard !isTogglingLike else { return }
        isTogglingLike = true
        let wasLiked = post.likedByMe
        post.likedByMe.toggle()
        post.likeCount = max(0, post.likeCount + (wasLiked ? -1 : 1))

        Task {
            defer { isTogglingLike = false }
            do {
                let isLiked = try await CyncAPI.togglePostLike(id: post.id)
                // Trust the server if it disagrees with our guess.
                if isLiked != post.likedByMe {
                    post.likedByMe = isLiked
                    post.likeCount = max(0, post.likeCount + (isLiked ? 1 : -1))
                }
            } catch {
                post.likedByMe = wasLiked
                post.likeCount = max(0, post.likeCount + (wasLiked ? 1 : -1))
                errorMessage = String(appLocalized: .commentActionFailed(error.localizedDescription))
            }
        }
    }

    /// `comments` grouped back into top-level comments + their replies,
    /// oldest first — see `CommentThread.threads(from:)`.
    var commentThreads: [CommentThread] {
        CommentThread.threads(from: comments)
    }

    /// Comments still shown as real comments (not "삭제된 댓글입니다").
    var visibleCommentCount: Int {
        comments.filter { !$0.deleted }.count
    }

    var authorLabels: [Int: CommentAuthorLabel] {
        CommentAuthorLabel.labels(for: comments, postAuthorId: post.authorId)
    }

    func authorLabel(for comment: Comment) -> CommentAuthorLabel {
        authorLabels[comment.id] ?? .named(comment.displayAuthorName)
    }

    /// Local only (no comment-like API yet) — see `Comment.likeCount`.
    func toggleCommentLike(_ comment: Comment) {
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        comments[index].isLikedByMe.toggle()
        comments[index].likeCount = max(0, comments[index].likeCount + (comments[index].isLikedByMe ? 1 : -1))
    }

    /// Posts a new comment (or, with `parentCommentId` set, a reply) via
    /// `POST /api/posts/{id}/comments` and appends the server's response.
    /// Returns whether it went through, so the input bar only clears on
    /// success and the user doesn't lose what they typed.
    func addComment(content: String, parentCommentId: Int? = nil, isAnonymous: Bool) async -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmittingComment else { return false }
        isSubmittingComment = true
        defer { isSubmittingComment = false }
        do {
            let comment = try await CyncAPI.createComment(
                postId: post.id,
                content: trimmed,
                parentCommentId: parentCommentId,
                isAnonymous: isAnonymous
            )
            comments.append(comment)
            post.commentCount += 1
            lastPostedCommentId = comment.id
            return true
        } catch {
            errorMessage = String(appLocalized: .commentPostFailed(error.localizedDescription))
            return false
        }
    }

    // MARK: - ⋮ menu

    private var isModerator: Bool {
        currentUser.map { Self.moderatorRoles.contains($0.role) } ?? false
    }

    /// 내 댓글 → 삭제, 남의 댓글 → 신고, 관리자·부방장 → 수정·삭제 (any
    /// comment). Empty for a deleted comment, or before `/api/me` loads.
    /// The post's own ⋮ menu: 내 글 → 삭제, 남의 글 → 신고. Empty before
    /// `/api/me` loads (we can't tell whose post it is yet).
    var postActions: [PostAction] {
        guard let currentUser else { return [] }
        return post.authorId == currentUser.studentId ? [.delete] : [.report]
    }

    func reportPost(reason: ReportReason) async {
        do {
            try await CyncAPI.reportPost(id: post.id, reason: reason)
            submittedReport = .post
        } catch {
            errorMessage = String(appLocalized: .commentActionFailed(error.localizedDescription))
        }
    }

    func deletePost() async {
        do {
            try await CyncAPI.deletePost(id: post.id)
            didDeletePost = true
        } catch {
            errorMessage = String(appLocalized: .commentActionFailed(error.localizedDescription))
        }
    }

    func actions(for comment: Comment) -> [CommentAction] {
        guard !comment.deleted, let currentUser else { return [] }
        if isModerator { return [.edit, .delete] }
        return comment.authorId == currentUser.studentId ? [.delete] : [.report]
    }

    func deleteComment(_ comment: Comment) async {
        do {
            try await CyncAPI.deleteComment(id: comment.id)
            guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
            // Mirror the server's soft delete locally instead of refetching.
            comments[index].deleted = true
            comments[index].content = String(appLocalized: .commentDeleted)
        } catch {
            errorMessage = String(appLocalized: .commentActionFailed(error.localizedDescription))
        }
    }

    func reportComment(_ comment: Comment, reason: ReportReason) async {
        do {
            try await CyncAPI.reportComment(id: comment.id, reason: reason)
            submittedReport = .comment
        } catch {
            errorMessage = String(appLocalized: .commentActionFailed(error.localizedDescription))
        }
    }

    /// Moderator edit — see `CyncAPI.updateComment` (endpoint not on the
    /// server yet, so this currently ends in the error popup).
    func editComment(_ comment: Comment, content: String) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let updated = try await CyncAPI.updateComment(id: comment.id, content: trimmed)
            if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                comments[index].content = updated.content
            }
        } catch {
            errorMessage = String(appLocalized: .commentActionFailed(error.localizedDescription))
        }
    }

    // MARK: - 번역 보기

    var canTranslate: Bool {
        PostTranslation.needsTranslation(post.title + "\n" + post.content)
    }

    var displayedTitle: String {
        translationPhase == .translated ? (translation?.title ?? post.title) : post.title
    }

    var displayedContent: String {
        translationPhase == .translated ? (translation?.content ?? post.content) : post.content
    }

    /// "번역 보기" ↔ "원문 보기". Uses the cached translation when this post
    /// was translated earlier in the session.
    func toggleTranslation() {
        switch translationPhase {
        case .loading:
            return
        case .translated:
            translationPhase = .original
        case .original:
            if let cached = PostTranslationCache.shared[post] {
                translation = cached
                translationPhase = .translated
            } else {
                translationPhase = .loading
                translationRequestID += 1
            }
        }
    }

    func finishTranslation(_ result: Result<[String], Error>) {
        guard translationPhase == .loading else { return }
        switch result {
        case .success(let texts) where texts.count == 2:
            let translated = TranslatedPost(title: texts[0], content: texts[1])
            PostTranslationCache.shared[post] = translated
            translation = translated
            translationPhase = .translated
        default:
            translationPhase = .original
            errorMessage = String(appLocalized: .communityTranslationFailed)
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
    /// each carrying its own oldest-first replies. Deleted comments are
    /// soft-deleted on the server (the row stays, `deleted == true`), so
    /// they're filtered here: a deleted reply disappears, and a deleted
    /// top-level comment stays only as a "삭제된 댓글입니다" placeholder
    /// when it still has live replies hanging off it.
    static func threads(from comments: [Comment]) -> [CommentThread] {
        let topLevel = comments
            .filter { $0.parentCommentId == nil }
            .sorted { $0.createdAt < $1.createdAt }

        return topLevel.compactMap { top in
            let replies = comments
                .filter { $0.parentCommentId == top.id && !$0.deleted }
                .sorted { $0.createdAt < $1.createdAt }
            if top.deleted && replies.isEmpty { return nil }
            return CommentThread(comment: top, replies: replies)
        }
    }
}
