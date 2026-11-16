//
//  AdminReportManageView.swift
//  Cync
//
//  Figma "관리자 - 신고 관리 (미처리)" (`731:3889`) / "(전체)" (`731:4009`) /
//  "(작성자 정지)" (`731:4120`). Pushed from CommunityView's top bar, which
//  only admins see; the bottom tab bar hides on its own (pushed screens
//  aren't a tab root — TabBarVisibility).
//
//  Top to bottom: `ScreenNavigationBar` ("신고 관리" + "활동 정지 관리" on
//  the right) → tab chips (미처리 n in red / 전체) → guide line (미처리
//  only) → `AdminReportCard`s, one per reported target → empty message.
//
//  Actions (all resolve every report on the card, and only after the
//  action itself succeeded):
//  - 삭제: confirm (`AdminLockerConfirmDialog`, red) → delete → resolve.
//  - 문제없음: no confirm → resolve.
//  - 작성자 정지: `AdminBanCard` rises over a dim (custom overlay, not
//    `.sheet`) → ban → (delete) → resolve, stopping at the first failure
//    with an `ErrorDialog` saying how far it got.
//  Results go to a toast. No system `.alert`/`.sheet`.
//
//  Deviations from Figma, kept for consistency with the rest of the app:
//  the shared `ScreenNavigationBar` (dark chevron, Semibold 17 title vs.
//  Figma's pink chevron / 15pt) and 12pt from the bar to the first block
//  (`Spacing.screenContentTop`; Figma has 8). Figma has no right-side
//  button; "활동 정지 관리" was asked for on top of it.
//

import SwiftUI

struct AdminReportManageView: View {
    @StateObject private var viewModel: AdminReportManageViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var deleteTarget: ReportGroup?
    // 작성자 정지 card
    @State private var banTarget: ReportGroup?
    @State private var banPeriod = AdminBanPeriod.default
    @State private var banReason = ""
    @State private var banAlsoDelete = true
    @State private var isBanManagePresented = false

    init() {
        _viewModel = StateObject(wrappedValue: AdminReportManageViewModel())
    }

    /// Previews inject sample data (and can open the ban card on a group).
    init(viewModel: AdminReportManageViewModel, openBanCardFor groupID: String? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        if let groupID, let group = viewModel.visibleGroups.first(where: { $0.id == groupID }) {
            _banTarget = State(initialValue: group)
            _banReason = State(initialValue: viewModel.defaultBanReason(for: group))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .adminReportTitle, onBack: { dismiss() }) {
                banManageButton
            }

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.cardInset) {
                    tabRow
                    if viewModel.selectedTab == .pending {
                        Text(.adminReportGuide)
                            .font(.adminFootnote).tracking(Tracking.adminFootnote)
                            .foregroundStyle(Color.textSecondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.screenContentTop)
                .padding(.bottom, Spacing.md)
            }
            .refreshable { await viewModel.load() }
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isBanManagePresented) {
            AdminBanManageView()
        }
        .overlay { banCardOverlay }
        .overlay { dialogs }
        // Above the dim, so results stay visible.
        .toast(message: $viewModel.toastMessage)
        .animation(.easeOut(duration: 0.2), value: banTarget?.id)
        .animation(.easeOut(duration: 0.2), value: deleteTarget?.id)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .animation(.easeOut(duration: 0.2), value: viewModel.visibleGroups.map(\.id))
        .task { await viewModel.load() }
    }

    // MARK: - Header

    /// "활동 정지 관리" → the 학번-entry ban screen (`AdminBanManageView`).
    private var banManageButton: some View {
        Button {
            isBanManagePresented = true
        } label: {
            Text(.adminBanManageTitle)
                .font(.adminTextAction).tracking(Tracking.adminTextAction)
                .foregroundStyle(Color.accentStrong)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var tabRow: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(AdminReportTab.allCases, id: \.self) { tab in
                SelectableChip(
                    titleKey: tab.titleKey,
                    isSelected: viewModel.selectedTab == tab,
                    appearance: .tab,
                    count: tab == .pending ? viewModel.pendingCount : nil,
                    countColor: .adminDanger
                ) {
                    viewModel.selectedTab = tab
                }
            }
        }
    }

    // MARK: - List

    @ViewBuilder
    private var content: some View {
        if viewModel.hasLoaded && viewModel.visibleGroups.isEmpty {
            Text(viewModel.selectedTab == .pending ? .adminReportEmptyPending : .adminReportEmptyAll)
                .font(.emptyStateMessage).tracking(Tracking.emptyStateMessage)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
        } else {
            LazyVStack(spacing: Spacing.cardInset) {
                ForEach(viewModel.visibleGroups) { group in
                    card(for: group)
                        .transition(.opacity)
                }
            }
        }
    }

    private func card(for group: ReportGroup) -> some View {
        let preview = viewModel.preview(for: group)
        let status: AdminReportCard.Status = group.status == .resolved
            ? .resolved(summary: viewModel.resolvedSummary(for: group))
            : .pending(canDelete: preview != .deleted, canBan: viewModel.canBan(group))

        return AdminReportCard(
            kind: group.target.kind,
            reasonKey: group.reason.label,
            count: group.count,
            timeText: RelativeTime.text(for: group.latestDate),
            preview: cardPreview(preview, kind: group.target.kind),
            detail: group.detail,
            status: status,
            isProcessing: viewModel.processingGroupIDs.contains(group.id),
            onDelete: { deleteTarget = group },
            onBan: { openBanCard(for: group) },
            onDismiss: { Task { await viewModel.dismiss(group) } }
        )
    }

    private func cardPreview(_ preview: ReportTargetPreview, kind: ReportTargetKind) -> AdminReportCard.Preview {
        switch preview {
        case .loading:
            return .loading
        case .post(let post):
            return .content(authorName: post.displayAuthorName, authorColor: preview.authorColor,
                            createdAt: post.createdAt, title: post.title, body: post.content,
                            studentId: post.authorId)
        case .comment(let comment):
            return .content(authorName: comment.displayAuthorName, authorColor: preview.authorColor,
                            createdAt: comment.createdAt, title: nil, body: comment.content,
                            studentId: comment.authorId)
        case .commentUnavailable:
            return .unavailable(.adminReportCommentUnavailable)
        case .failed:
            return .unavailable(.adminReportPreviewFailed)
        case .deleted:
            return .unavailable(kind == .post ? .adminReportPostDeleted : .adminReportCommentDeleted)
        }
    }

    // MARK: - 작성자 정지

    private func openBanCard(for group: ReportGroup) {
        banPeriod = .default
        banReason = viewModel.defaultBanReason(for: group)
        banAlsoDelete = true
        banTarget = group
    }

    @ViewBuilder
    private var banCardOverlay: some View {
        if let group = banTarget {
            let preview = viewModel.preview(for: group)
            ZStack(alignment: .bottom) {
                Color.dimOverlay
                    .ignoresSafeArea()
                    .onTapGesture { closeBanCard() }

                AdminBanCard(
                    authorName: preview.authorDisplayName ?? "",
                    authorColor: preview.authorColor,
                    studentId: preview.authorId ?? "-",
                    targetKind: group.target.kind,
                    period: $banPeriod,
                    reason: $banReason,
                    alsoDelete: $banAlsoDelete,
                    isProcessing: viewModel.processingGroupIDs.contains(group.id),
                    onClose: closeBanCard,
                    onConfirm: {
                        Task {
                            let banned = await viewModel.ban(group, period: banPeriod, reason: banReason,
                                                             alsoDelete: banAlsoDelete)
                            if banned { banTarget = nil }
                        }
                    }
                )
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .transition(.opacity)
        }
    }

    private func closeBanCard() {
        guard let group = banTarget, !viewModel.processingGroupIDs.contains(group.id) else { return }
        banTarget = nil
    }

    // MARK: - Dialogs

    @ViewBuilder
    private var dialogs: some View {
        if deleteTarget != nil || viewModel.errorMessage != nil {
            ZStack {
                Color.dimOverlay
                    .ignoresSafeArea()
                    .onTapGesture {
                        deleteTarget = nil
                        viewModel.errorMessage = nil
                    }

                Group {
                    if let message = viewModel.errorMessage {
                        ErrorDialog(titleKey: .commonError, message: message) {
                            viewModel.errorMessage = nil
                        }
                    } else if let group = deleteTarget {
                        AdminLockerConfirmDialog(
                            titleKey: group.target.kind == .post ? .adminReportDeletePostConfirmTitle : .adminReportDeleteCommentConfirmTitle,
                            messageKey: .adminReportDeleteConfirmMessage,
                            confirmKey: .adminReportActionDelete,
                            onCancel: { deleteTarget = nil },
                            onConfirm: {
                                deleteTarget = nil
                                Task { await viewModel.delete(group) }
                            },
                            confirmTint: .adminDanger
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Previews

#Preview("미처리 목록") {
    NavigationStack {
        AdminReportManageView(viewModel: AdminReportManageViewModel(
            previewReports: Report.previewList,
            previews: AdminReportManageViewModel.previewTargets
        ))
    }
}

#Preview("전체 목록") {
    NavigationStack {
        AdminReportManageView(viewModel: AdminReportManageViewModel(
            previewReports: Report.previewList,
            previews: AdminReportManageViewModel.previewTargets,
            selectedTab: .all,
            actionHistory: [6: [.dismissed]]
        ))
    }
}

#Preview("미처리 0건") {
    NavigationStack {
        AdminReportManageView(viewModel: AdminReportManageViewModel(
            previewReports: Report.previewList.filter { $0.status == .resolved },
            previews: AdminReportManageViewModel.previewTargets
        ))
    }
}

#Preview("작성자 정지 카드") {
    NavigationStack {
        AdminReportManageView(
            viewModel: AdminReportManageViewModel(
                previewReports: Report.previewList,
                previews: AdminReportManageViewModel.previewTargets
            ),
            openBanCardFor: "P6-PENDING"
        )
    }
}

#Preview("댓글 대체 표시") {
    var previews = AdminReportManageViewModel.previewTargets
    previews[ReportTarget(kind: .comment, id: 5)] = .commentUnavailable
    return NavigationStack {
        AdminReportManageView(viewModel: AdminReportManageViewModel(
            previewReports: Report.previewList,
            previews: previews
        ))
    }
}
