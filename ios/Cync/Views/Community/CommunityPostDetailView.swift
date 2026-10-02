//
//  CommunityPostDetailView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `228:1790` ("5-1 게시글").
//  Post header (`228:1994`: author, title, body, reactions, kebab) +
//  "댓글 섹션" (`299:2001`): a `calendarSurface` panel listing `CommentRow`s
//  via `CommentListView`. Pushed from CommunityView via NavigationLink; the
//  back chevron comes from `ScreenNavigationBar` (system nav bar hidden),
//  with the board name ("자유게시판") centered like the other sub-screens.
//  The server has no post categories yet, so every post is in the one
//  free board.
//
//  Only this screen has the kebab — CommunityView's row list doesn't. It
//  opens a `PopupMenu` (custom dropdown, not a system menu) with 신고 on
//  someone else's post or 삭제 on your own (`viewModel.postActions`). Both
//  go through the same confirm popups as a comment's (reason picker /
//  delete confirmation) with post wording; a deleted post pops back to the
//  list and `onPostDeleted` drops it from there.
//
//  Commenting happens in `CommentInputBar`, pinned to the bottom with
//  `.safeAreaInset(edge: .bottom)` so it rides up on top of the keyboard.
//  "답글" on a comment switches the bar into reply mode and focuses it.
//  No bottom tab bar here: only the five main tab screens show it — see
//  TabBarVisibility.swift.
//
//  Each comment's ⋮ opens the same `PopupMenu` as the post's (one menu
//  for the screen, opened under whichever ⋮ was tapped — `openMenuID`);
//  everything it leads to — delete/report confirmations, the moderator
//  edit box, and error popups — is a custom dialog over a dimmed backdrop
//  (`dialogOverlay`), not `.alert`, per this project's UI rule (CLAUDE.md).
//
//  "번역 보기" translates the title and body on-device; see
//  PostTranslation.swift.
//
//  No UIKit anywhere on this screen.
//

import SwiftUI

struct CommunityPostDetailView: View {
    @StateObject private var viewModel: CommunityPostDetailViewModel
    @Environment(\.dismiss) private var dismiss
    /// Called after this post is deleted, so the list can drop its row.
    private let onPostDeleted: (Int) -> Void
    /// Called whenever the post changes here (fresh view count, a like),
    /// so the list row shows the same numbers on the way back.
    private let onPostChanged: (CommunityPost) -> Void

    /// Which ⋮ menu is open: `postMenuID`, a comment's
    /// `CommentRow.menuAnchorID(for:)`, or `nil`.
    @State private var openMenuID: String?
    /// The comment whose ⋮ menu is open.
    @State private var menuComment: Comment?
    @State private var draft = ""
    /// "익명으로 작성" — on by default, then whatever the user last chose
    /// (kept across posts and launches).
    @AppStorage("commentPostsAnonymously") private var isAnonymous = true
    @ScaledMetric(relativeTo: .subheadline) private var reactionIconSize: CGFloat = 17

    /// The comment input is showing.
    @State private var isComposing = false
    /// Whose comment `draft` was typed for: a comment's id when replying,
    /// `postDraftOwner` for a comment on the post itself. Closing the input
    /// keeps the draft; opening it for someone else starts a fresh one.
    @State private var draftOwnerID = Self.postDraftOwner
    /// Set for a moment when a reply/comment icon opens or retargets the
    /// input, so the "tap anywhere to close" gesture firing for the same
    /// tap doesn't immediately close it again.
    @State private var isOpeningComposer = false
    @State private var replyTarget: Comment?
    @State private var dialog: Dialog?
    @FocusState private var isInputFocused: Bool

    init(
        post: CommunityPost,
        previewComments: [Comment] = [],
        onPostDeleted: @escaping (Int) -> Void = { _ in },
        onPostChanged: @escaping (CommunityPost) -> Void = { _ in }
    ) {
        let viewModel = CommunityPostDetailViewModel(post: post)
        viewModel.comments = previewComments
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onPostDeleted = onPostDeleted
        self.onPostChanged = onPostChanged
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .tabCommunity, onBack: { dismiss() }) {
                postMenuButton
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        postHeader
                        commentsSection
                    }
                    // Tap anywhere above the input to close it (the draft
                    // stays). Simultaneous, so buttons still work.
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { requestCloseComposer() })
                }
                .scrollDismissesKeyboard(.interactively)
                // White above the post (pulling down at the top). The gray
                // below the comments scrolls with them — see
                // `commentsSection` — instead of a fixed half-white /
                // half-gray backdrop, which let white show through under
                // the comments when the list bounced at the bottom.
                .background {
                    Color.appBackground
                        // The empty area below short comments closes it too.
                        .onTapGesture { requestCloseComposer() }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CommentInputBar(
                        text: $draft,
                        isAnonymous: $isAnonymous,
                        isComposing: $isComposing,
                        isSubmitting: viewModel.isSubmittingComment,
                        isFocused: $isInputFocused,
                        onSubmit: submitComment
                    )
                }
                .animation(.easeOut(duration: 0.2), value: isComposing)
                // Keyboard swiped away → input closes too (draft kept).
                .onChange(of: isInputFocused) { _, isFocused in
                    if !isFocused && !isOpeningComposer { closeComposer() }
                }
                .onChange(of: viewModel.lastPostedCommentId) { _, id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .popupMenu(presentedID: $openMenuID, items: openMenuItems)
        .postTranslationTask(
            requestID: viewModel.translationRequestID,
            texts: [viewModel.post.title, viewModel.post.content],
            onResult: { viewModel.finishTranslation($0) }
        )
        .task {
            // No `GET /api/posts/{id}` here: that call bumps the view count,
            // and 조회수 isn't used. The list's copy (with `likedByMe`) is
            // what this screen shows.
            await viewModel.loadComments()
        }
        .onChange(of: viewModel.post) { _, post in
            onPostChanged(post)
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message { dialog = .error(message) }
        }
        .onChange(of: viewModel.submittedReport) { _, target in
            if let target { dialog = .reportDone(target) }
        }
        .onChange(of: viewModel.didDeletePost) { _, didDelete in
            guard didDelete else { return }
            onPostDeleted(viewModel.post.id)
            dismiss()
        }
        .overlay { dialogOverlay }
        .animation(.easeOut(duration: 0.2), value: dialog?.id)
    }

    // MARK: - Post

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            AuthorLine(authorName: viewModel.post.displayAuthorName, createdAt: viewModel.post.createdAt)

            Text(viewModel.displayedTitle)
                .font(.communityPostDetailTitle).tracking(Tracking.communityPostDetailTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.top, Spacing.xxs)
                // 12pt to the body (stack spacing 8 + 4).
                .padding(.bottom, Spacing.xxs)

            Text(viewModel.displayedContent)
                .font(.communityPostBody).tracking(Tracking.communityPostBody)
                .foregroundStyle(Color.textPrimary)

            if viewModel.canTranslate {
                translationButton
            }

            // Heart ↔ bubble.
            HStack(spacing: Spacing.cardInset) {
                Button {
                    viewModel.togglePostLike()
                } label: {
                    reactionLabel(
                        systemImage: viewModel.post.likedByMe ? "heart.fill" : "heart",
                        count: viewModel.post.likeCount
                    )
                    // ≥20pt visible box so the 12pt inset reaches 44×44,
                    // even with no number next to the icon.
                    .frame(minWidth: 20, minHeight: 20)
                    .minimumHitTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.commentLike))
                .accessibilityValue(viewModel.post.likeCount > 0 ? Text(viewModel.post.likeCount, format: .number) : Text(verbatim: ""))
                .accessibilityAddTraits(viewModel.post.likedByMe ? .isSelected : [])
                .foregroundStyle(viewModel.post.likedByMe ? Color.eventAccent : Color.textSecondary)

                // Comments still on screen as comments — replies included,
                // "삭제된 댓글입니다" placeholders not. Tapping opens the
                // comment input (a new comment, not a reply).
                Button {
                    startComposing(replyingTo: nil)
                } label: {
                    reactionLabel(systemImage: "bubble.right", count: viewModel.visibleCommentCount)
                        .frame(minWidth: 20, minHeight: 20)
                        .minimumHitTarget()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.textSecondary)
                .accessibilityLabel(Text(.commentWrite))
                .accessibilityValue(viewModel.visibleCommentCount > 0 ? Text(viewModel.visibleCommentCount, format: .number) : Text(verbatim: ""))
            }
            .padding(.top, Spacing.xs)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.screenContentTop)
        .padding(.bottom, Spacing.md)
        // Its own white, so a long post never shows the scroll view's gray
        // lower half behind it.
        .background(Color.appBackground)
    }

    private var translationButton: some View {
        Button {
            viewModel.toggleTranslation()
        } label: {
            HStack(spacing: Spacing.xxs) {
                switch viewModel.translationPhase {
                case .original:
                    Text(.communityTranslate)
                case .loading:
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.textSecondary)
                    Text(.communityTranslating)
                case .translated:
                    Text(.communityShowOriginal)
                }
            }
            .font(.commentReplyButton).tracking(Tracking.commentReplyButton)
            .foregroundStyle(viewModel.translationPhase == .loading ? Color.textSecondary : Color.eventAccent)
            .frame(minHeight: 20)
            .minimumHitTarget()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.translationPhase == .loading)
        .padding(.top, Spacing.xxs)
    }

    /// Icon + count, with no number at 0 (an unliked post shows just the
    /// heart; liking it shows "1", unliking goes back to the bare heart).
    /// The next reaction sits right after whatever's there, so a missing
    /// number doesn't leave a gap.
    private func reactionLabel(systemImage: String, count: Int) -> some View {
        HStack(spacing: Spacing.xxs) {
            // Same fitted square as the comments' icons, so the heart and
            // the bubble come out the same size.
            ReactionIcon(systemName: systemImage, size: reactionIconSize)
            if count > 0 {
                Text(count, format: .number)
            }
        }
        .font(.communityReactionCount).tracking(Tracking.communityReactionCount)
    }

    private static let postMenuID = "post"

    /// Figma's "더보기(케밥) 버튼", in the nav bar's trailing slot — opens
    /// `postMenuItems` beneath it. Empty until `/api/me` says whose post
    /// this is (the slot just stays blank).
    @ViewBuilder
    private var postMenuButton: some View {
        if !viewModel.postActions.isEmpty {
            Button {
                isInputFocused = false
                openMenuID = openMenuID == Self.postMenuID ? nil : Self.postMenuID
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 44, height: 44, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.communityMore))
            .popupMenuAnchor(id: Self.postMenuID)
        }
    }

    private var openMenuItems: [PopupMenuItem] {
        if openMenuID == Self.postMenuID { return postMenuItems }
        guard let menuComment else { return [] }
        return commentMenuItems(for: menuComment)
    }

    private func commentMenuItems(for comment: Comment) -> [PopupMenuItem] {
        viewModel.actions(for: comment).map { action in
            switch action {
            case .edit:
                PopupMenuItem(id: "edit", systemImage: "pencil", titleKey: .commentEdit) {
                    handle(comment, .edit)
                }
            case .report:
                PopupMenuItem(id: "report", systemImage: "exclamationmark.bubble", titleKey: .commentReport) {
                    handle(comment, .report)
                }
            case .delete:
                PopupMenuItem(id: "delete", systemImage: "trash", titleKey: .commentDelete, role: .destructive) {
                    handle(comment, .delete)
                }
            }
        }
    }

    private var postMenuItems: [PopupMenuItem] {
        viewModel.postActions.map { action in
            switch action {
            case .report:
                PopupMenuItem(id: "report", systemImage: "exclamationmark.bubble", titleKey: .commentReport) {
                    dialog = .reportPost
                }
            case .delete:
                PopupMenuItem(id: "delete", systemImage: "trash", titleKey: .commentDelete, role: .destructive) {
                    dialog = .deletePost
                }
            }
        }
    }

    // MARK: - Comments

    /// How far the comments' gray reaches below their content — more
    /// than any screen is tall.
    private static let commentsGrayOverscroll: CGFloat = 2000

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.commentTitleCount(viewModel.visibleCommentCount))
                .font(.commentsSectionTitle).tracking(Tracking.commentsSectionTitle)
                .foregroundStyle(Color.textPrimary)

            CommentListView(
                threads: viewModel.commentThreads,
                authorLabel: { viewModel.authorLabel(for: $0) },
                postAuthorName: viewModel.post.displayAuthorName,
                isMine: { viewModel.isMine($0) },
                replyTargetID: replyTarget?.id,
                actions: { viewModel.actions(for: $0) },
                onLike: { viewModel.toggleCommentLike($0) },
                onReply: { comment in
                    startComposing(replyingTo: comment)
                },
                onMore: { comment in
                    isInputFocused = false
                    let id = CommentRow.menuAnchorID(for: comment)
                    menuComment = comment
                    openMenuID = openMenuID == id ? nil : id
                },
                onAction: { comment, action in
                    handle(comment, action)
                }
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        // The gray runs on well past the last comment, so short comments
        // still fill down to the input bar and a bounce at the bottom
        // shows gray, not white.
        .background(alignment: .top) {
            Color.calendarSurface
                .padding(.bottom, -Self.commentsGrayOverscroll)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray300)
                .frame(height: 1)
        }
    }

    private func submitComment() {
        let parentId = replyTarget?.id
        Task {
            let didPost = await viewModel.addComment(
                content: draft,
                parentCommentId: parentId,
                isAnonymous: isAnonymous
            )
            if didPost {
                draft = ""
                closeComposer()
            }
        }
    }

    /// Opens the comment input — the composer focuses its own field as it
    /// appears, so the keyboard always comes up.
    private static let postDraftOwner = -1

    private func startComposing(replyingTo comment: Comment?) {
        openMenuID = nil
        isOpeningComposer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isOpeningComposer = false }

        let owner = comment?.id ?? Self.postDraftOwner
        if owner != draftOwnerID {
            // A different post/comment than the draft was for — start over.
            draft = ""
            draftOwnerID = owner
        }
        replyTarget = comment
        if isComposing {
            // Already open (retargeting): keep the keyboard up.
            isInputFocused = true
        } else {
            isComposing = true
        }
    }

    /// Closes the input, keeping `draft` (and whom it was for) so reopening
    /// it for the same target picks up where the user left off.
    private func closeComposer() {
        guard isComposing else { return }
        isInputFocused = false
        replyTarget = nil
        isComposing = false
    }

    /// From the "tap anywhere" gestures — deferred a turn so a tap that
    /// also hit a reply/comment icon (which opens it) wins.
    private func requestCloseComposer() {
        DispatchQueue.main.async {
            guard !isOpeningComposer else { return }
            closeComposer()
        }
    }

    private func handle(_ comment: Comment, _ action: CommentAction) {
        isInputFocused = false
        switch action {
        case .delete: dialog = .delete(comment)
        case .report: dialog = .report(comment)
        case .edit: dialog = .edit(comment)
        }
    }

    // MARK: - Dialogs

    private enum Dialog: Identifiable {
        case delete(Comment)
        case report(Comment)
        case edit(Comment)
        case reportPost
        /// "정말 신고할까요?" after a reason was picked — `nil` comment means
        /// the post itself.
        case confirmReport(Comment?, ReportReason)
        case deletePost
        case reportDone(ReportTargetKind)
        case error(String)

        var id: String {
            switch self {
            case .delete(let comment): return "delete-\(comment.id)"
            case .report(let comment): return "report-\(comment.id)"
            case .edit(let comment): return "edit-\(comment.id)"
            case .reportPost: return "reportPost"
            case .confirmReport(let comment, let reason): return "confirmReport-\(comment?.id ?? -1)-\(reason.rawValue)"
            case .deletePost: return "deletePost"
            case .reportDone: return "reportDone"
            case .error(let message): return "error-\(message)"
            }
        }
    }

    @ViewBuilder
    private var dialogOverlay: some View {
        if let dialog {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { dismissDialog() }

                dialogCard(dialog)
                    .padding(.horizontal, Spacing.md)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func dialogCard(_ dialog: Dialog) -> some View {
        switch dialog {
        case .delete(let comment):
            CommentDeleteDialog(onCancel: dismissDialog) {
                dismissDialog()
                Task { await viewModel.deleteComment(comment) }
            }
        case .report(let comment):
            CommentReportDialog(onCancel: dismissDialog) { reason in
                self.dialog = .confirmReport(comment, reason)
            }
        case .edit(let comment):
            CommentEditDialog(initialText: comment.content, onCancel: dismissDialog) { text in
                dismissDialog()
                Task { await viewModel.editComment(comment, content: text) }
            }
        case .reportPost:
            CommentReportDialog(titleKey: .postReportConfirmTitle, onCancel: dismissDialog) { reason in
                self.dialog = .confirmReport(nil, reason)
            }
        case .confirmReport(let comment, let reason):
            ReportConfirmDialog(reason: reason, onCancel: dismissDialog) {
                dismissDialog()
                Task {
                    if let comment {
                        await viewModel.reportComment(comment, reason: reason)
                    } else {
                        await viewModel.reportPost(reason: reason)
                    }
                }
            }
        case .deletePost:
            CommentDeleteDialog(
                titleKey: .postDeleteConfirmTitle,
                messageKey: .postDeleteConfirmMessage,
                // Only mention comments when there are some to lose.
                detailKey: viewModel.visibleCommentCount > 0
                    ? .postDeleteConfirmComments(viewModel.visibleCommentCount)
                    : nil,
                onCancel: dismissDialog
            ) {
                dismissDialog()
                Task { await viewModel.deletePost() }
            }
        case .reportDone(let target):
            ErrorDialog(
                titleKey: .commentReportDoneTitle,
                message: String(appLocalized: target == .post ? .postReportDoneMessage : .commentReportDoneMessage),
                onConfirm: dismissDialog
            )
        case .error(let message):
            ErrorDialog(titleKey: .commonError, message: message, onConfirm: dismissDialog)
        }
    }

    private func dismissDialog() {
        // Clear whatever raised it, so the same error/report can show again.
        viewModel.errorMessage = nil
        viewModel.submittedReport = nil
        dialog = nil
    }
}

#Preview("댓글 없음") {
    NavigationStack {
        CommunityPostDetailView(post: CommunityPost.mockList[0])
    }
    .environmentObject(TabBarVisibility())
}

#Preview("댓글 1개 이상") {
    NavigationStack {
        CommunityPostDetailView(
            post: CommunityPost.mockList[0],
            previewComments: [Comment.mockList[0]]
        )
    }
    .environmentObject(TabBarVisibility())
}

#Preview("댓글 + 대댓글") {
    NavigationStack {
        CommunityPostDetailView(post: CommunityPost.mockList[0], previewComments: Comment.mockList)
    }
    .environmentObject(TabBarVisibility())
}
