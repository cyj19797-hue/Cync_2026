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
    /// Default checked — comments are anonymous unless the user opts out.
    @State private var isAnonymous = true
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
            ScreenNavigationBar(titleKey: .communityBoardFree, onBack: { dismiss() })

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        postHeader
                        commentsSection
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.appBackground)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CommentInputBar(
                        text: $draft,
                        isAnonymous: $isAnonymous,
                        replyingTo: replyTarget.map { viewModel.authorLabel(for: $0).text },
                        isSubmitting: viewModel.isSubmittingComment,
                        isFocused: $isInputFocused,
                        onCancelReply: { replyTarget = nil },
                        onSubmit: submitComment
                    )
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
            // `.task`, not `.onAppear`: closing a popup here mustn't count
            // another view (the view model also guards against repeats).
            async let view: Void = viewModel.recordViewAndRefresh()
            async let comments: Void = viewModel.loadComments()
            _ = await (view, comments)
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
            HStack(alignment: .top, spacing: Spacing.xs) {
                AuthorLine(authorName: viewModel.post.displayAuthorName, createdAt: viewModel.post.createdAt)

                Spacer(minLength: 0)

                // Figma: "더보기(케밥) 버튼" — opens `postMenuItems` beneath
                // it. Hidden until `/api/me` says whose post this is.
                if !viewModel.postActions.isEmpty {
                    Button {
                        isInputFocused = false
                        openMenuID = openMenuID == Self.postMenuID ? nil : Self.postMenuID
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .minimumHitTarget(inset: 10)
                    .accessibilityLabel(Text(.communityMore))
                    .popupMenuAnchor(id: Self.postMenuID)
                }
            }

            Text(viewModel.displayedTitle)
                .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.top, Spacing.xxs)

            Text(viewModel.displayedContent)
                .font(.communityPostBody).tracking(Tracking.communityPostBody)
                .foregroundStyle(Color.textPrimary)

            if viewModel.canTranslate {
                translationButton
            }

            HStack(spacing: Spacing.xs) {
                Button {
                    viewModel.togglePostLike()
                } label: {
                    reactionLabel(
                        systemImage: viewModel.post.likedByMe ? "heart.fill" : "heart",
                        count: viewModel.post.likeCount
                    )
                    .frame(minHeight: 20)
                    .minimumHitTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.commentLike))
                .accessibilityValue(Text(viewModel.post.likeCount, format: .number))
                .accessibilityAddTraits(viewModel.post.likedByMe ? .isSelected : [])
                .foregroundStyle(viewModel.post.likedByMe ? Color.eventAccent : Color.textSecondary)

                // Comments still on screen as comments — replies included,
                // "삭제된 댓글입니다" placeholders not.
                reactionLabel(systemImage: "bubble.right", count: viewModel.visibleCommentCount)
                    .foregroundStyle(Color.textSecondary)

                Spacer(minLength: 0)

                // 조회수 — counted by the detail request on opening this screen.
                reactionLabel(systemImage: "eye", count: viewModel.post.viewCount)
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(.communityViewCount(viewModel.post.viewCount)))
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
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

    private func reactionLabel(systemImage: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: systemImage)
            Text(count, format: .number)
        }
        .font(.communityReactionCount).tracking(Tracking.communityReactionCount)
    }

    private static let postMenuID = "post"

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

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.commentTitle)
                .font(.commentsSectionTitle).tracking(Tracking.commentsSectionTitle)
                .foregroundStyle(Color.textPrimary)

            CommentListView(
                threads: viewModel.commentThreads,
                authorLabel: { viewModel.authorLabel(for: $0) },
                actions: { viewModel.actions(for: $0) },
                onLike: { viewModel.toggleCommentLike($0) },
                onReply: { comment in
                    replyTarget = comment
                    isInputFocused = true
                },
                onMore: { comment in
                    isInputFocused = false
                    let id = CommentRow.menuAnchorID(for: comment)
                    menuComment = comment
                    openMenuID = openMenuID == id ? nil : id
                }
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.calendarSurface)
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
                replyTarget = nil
                isInputFocused = false
            }
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
        case deletePost
        case reportDone(ReportTargetKind)
        case error(String)

        var id: String {
            switch self {
            case .delete(let comment): return "delete-\(comment.id)"
            case .report(let comment): return "report-\(comment.id)"
            case .edit(let comment): return "edit-\(comment.id)"
            case .reportPost: return "reportPost"
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
                dismissDialog()
                Task { await viewModel.reportComment(comment, reason: reason) }
            }
        case .edit(let comment):
            CommentEditDialog(initialText: comment.content, onCancel: dismissDialog) { text in
                dismissDialog()
                Task { await viewModel.editComment(comment, content: text) }
            }
        case .reportPost:
            CommentReportDialog(titleKey: .postReportConfirmTitle, onCancel: dismissDialog) { reason in
                dismissDialog()
                Task { await viewModel.reportPost(reason: reason) }
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
