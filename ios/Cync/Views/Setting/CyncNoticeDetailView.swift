//
//  CyncNoticeDetailView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `466:2742` ("6-2-1 공지사항 내용").
//  Pushed from CyncNoticeListView — a plain full-screen push, not the
//  centered dim-scrim dialog card `NoticeDetailView` uses for "2-1 공지글".
//
//  Layout beyond Figma: title, date, body and images all share one
//  left/right inset (`Spacing.screenHorizontal`) so they start at the same
//  x; a divider separates the title block from the body, 16pt above and
//  below it. The body is Markdown (see `CyncNotice`) — links get the accent
//  color + underline and open in Safari; images follow the body at full
//  width. The whole page scrolls, so a long body just keeps going.
//
//  Opening a notice marks it read for the list's unread dot. No bottom tab
//  bar here: only the five main tab screens show it — see
//  TabBarVisibility.swift.
//
//  For admins, a "팝업" tag (`PopupTag`) sits under the date when the notice pops up at
//  launch. Admins get a ⋮ button on the bar opening the same `.popupMenu`
//  as 학생회 공지 (`NoticeDetailView`) — Figma `734:4342` draws a bottom
//  sheet, but the app's admin menus are kept alike:
//    수정 → the shared compose screen in edit mode (pushed from here)
//    팝업 끄기 / 팝업 켜기 → re-sends the notice with the flag flipped, no confirm
//    삭제 → `CommentDeleteDialog` confirm, then back to the list
//  The notice shown is read from the list's view model by id, so an edit
//  or popup switch shows here and on the list at once.
//

import SwiftUI

struct CyncNoticeDetailView: View {
    /// The notice as it was when opened — used until/unless the list has it.
    let initialNotice: CyncNotice
    @ObservedObject var viewModel: CyncNoticeListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isAdminMenuOpen = false
    @State private var isDeleteConfirmPresented = false
    @State private var deleteErrorMessage: String?
    @State private var isEditPresented = false
    @State private var isTogglingPopup = false

    init(notice: CyncNotice, viewModel: CyncNoticeListViewModel, opensAdminMenu: Bool = false) {
        initialNotice = notice
        self.viewModel = viewModel
        _isAdminMenuOpen = State(initialValue: opensAdminMenu)
    }

    /// The live copy — reflects 수정 / 팝업 changes.
    private var notice: CyncNotice { viewModel.notice(id: initialNotice.id) ?? initialNotice }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .settingsCyncNotice, onBack: { dismiss() }) {
                if viewModel.isAdmin {
                    adminMenuButton
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    header

                    Divider()
                        .overlay(Color.borderLight)

                    bodyText

                    ForEach(notice.imageURLs, id: \.self) { url in
                        NoticeImage(url: url)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.screenContentTop)
                .padding(.bottom, Spacing.md)
            }
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .popupMenu(isPresented: $isAdminMenuOpen, items: adminMenuItems)
        .overlay { dialogs }
        .toast(message: $viewModel.toastMessage)
        .animation(.easeOut(duration: 0.2), value: isDeleteConfirmPresented)
        .animation(.easeOut(duration: 0.2), value: deleteErrorMessage)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .navigationDestination(isPresented: $isEditPresented) {
            PostComposeView(configuration: .appNoticeEdit(notice: notice) { updated in
                viewModel.replace(updated)
            })
        }
        .onAppear {
            CyncNoticeReadStore.shared.markRead(notice.id)
        }
    }

    // MARK: - Admin

    private static let adminMenuIconWidth: CGFloat = 24
    private static let adminMenuTouchExtension = (44 - adminMenuIconWidth) / 2

    /// ⋮ — the same button as 학생회 공지's detail.
    private var adminMenuButton: some View {
        Button {
            isAdminMenuOpen.toggle()
        } label: {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundStyle(Color.textPrimary)
                .frame(width: Self.adminMenuIconWidth, height: 44)
                .padding(.horizontal, Self.adminMenuTouchExtension)
                .contentShape(Rectangle())
                .padding(.horizontal, -Self.adminMenuTouchExtension)
        }
        .buttonStyle(.plain)
        .disabled(isTogglingPopup)
        .accessibilityLabel(Text(.appNoticeMenuAccessibility))
        .popupMenuAnchor()
    }

    private var adminMenuItems: [PopupMenuItem] {
        [
            PopupMenuItem(id: "edit", systemImage: "pencil", titleKey: .commentEdit) {
                isEditPresented = true
            },
            PopupMenuItem(
                id: "popup",
                systemImage: notice.isPopup ? "bell.slash" : "bell",
                titleKey: notice.isPopup ? .appNoticeMenuPopupOff : .appNoticeMenuPopupOn
            ) {
                togglePopup()
            },
            PopupMenuItem(id: "delete", systemImage: "trash", titleKey: .commentDelete, role: .destructive) {
                isDeleteConfirmPresented = true
            }
        ]
    }

    private func togglePopup() {
        guard !isTogglingPopup else { return }
        isTogglingPopup = true
        Task {
            _ = await viewModel.togglePopup(notice)
            isTogglingPopup = false
        }
    }

    @ViewBuilder
    private var dialogs: some View {
        if isDeleteConfirmPresented || deleteErrorMessage != nil || viewModel.errorMessage != nil {
            ZStack {
                Color.dimOverlay
                    .ignoresSafeArea()
                    .onTapGesture {
                        isDeleteConfirmPresented = false
                        deleteErrorMessage = nil
                        viewModel.errorMessage = nil
                    }

                Group {
                    if let message = deleteErrorMessage ?? viewModel.errorMessage {
                        ErrorDialog(titleKey: .commonError, message: message) {
                            deleteErrorMessage = nil
                            viewModel.errorMessage = nil
                        }
                    } else {
                        CommentDeleteDialog(
                            titleKey: .noticeDeleteConfirmTitle,
                            messageKey: .noticeDeleteConfirmMessage,
                            onCancel: { isDeleteConfirmPresented = false }
                        ) {
                            isDeleteConfirmPresented = false
                            delete()
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .transition(.opacity)
        }
    }

    private func delete() {
        let target = notice
        Task {
            do {
                try await viewModel.delete(target)
                dismiss()
            } catch {
                deleteErrorMessage = String(appLocalized: .noticeDeleteFailed(error.localizedDescription))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(notice.title)
                .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
                .foregroundStyle(Color.textPrimary)

            Text(notice.dateText)
                .font(.cyncNoticeDetailDate).tracking(Tracking.cyncNoticeDetailDate)
                .foregroundStyle(Color.textSecondary)

            // Admins only — students don't need to know it pops up.
            if viewModel.isAdmin && notice.isPopup {
                PopupTag()
                    .padding(.top, Spacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bodyText: some View {
        Text(styledContent)
            .font(.noticeDetailBody).tracking(Tracking.noticeDetailBody)
            .foregroundStyle(Color.textPrimary)
            .lineSpacing(4)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// `notice.attributedContent` with every link run in the accent color
    /// and underlined, so links stand out from plain body text.
    private var styledContent: AttributedString {
        var content = notice.attributedContent
        for run in content.runs where run.link != nil {
            content[run.range].foregroundColor = Color.eventAccentDark
            content[run.range].underlineStyle = .single
        }
        return content
    }
}

/// One notice image at the content's full width, keeping its aspect ratio.
/// While loading (or if it fails) a light 16:9 box holds its place so the
/// text below doesn't jump when it arrives.
private struct NoticeImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                Rectangle()
                    .fill(Color.surface)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        if phase.error != nil {
                            Image(systemName: "photo")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.chipSelected))
        .accessibilityElement()
        .accessibilityLabel(Text(.cyncNoticeImage))
        .accessibilityAddTraits(.isImage)
    }
}

#Preview("관리자 - 관리 메뉴 열림") {
    let notices = AppNotice.previewList.map(CyncNotice.init)
    return NavigationStack {
        CyncNoticeDetailView(
            notice: notices[1],
            viewModel: CyncNoticeListViewModel(previewNotices: notices, isAdmin: true),
            opensAdminMenu: true
        )
    }
}

#Preview("일반 사용자") {
    let notices = AppNotice.previewList.map(CyncNotice.init)
    return NavigationStack {
        CyncNoticeDetailView(
            notice: notices[1],
            viewModel: CyncNoticeListViewModel(previewNotices: notices, isAdmin: false)
        )
    }
}
