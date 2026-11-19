//
//  NoticeDetailView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `186:1967` ("2-1 공지글").
//  The frame is a full-screen dim scrim (`rgba(53,53,53,0.6)`) behind a
//  centered, all-four-corners-rounded white card — a floating dialog, not a
//  bottom sheet. `.sheet`/`.fullScreenCover` always pin content to (or grow
//  from) the bottom edge and can't reproduce a vertically centered card, so
//  this is presented as a plain SwiftUI overlay from NoticeListView instead
//  (see the `.toolbar(_:for:.tabBar)` + `ZStack` wiring there). No UIKit
//  needed anywhere on this screen — a `GeometryReader`-sized `ZStack` plus a
//  `ScrollView` reproduces the dim-backdrop-plus-card look and the
//  scrollable body natively.
//
//  Two layouts (`showsNavigationBar`):
//  - 공지사항 tab (`true`, default): the 이전 글 / 목록 / 다음 글 bar at
//    the bottom of a full-height card.
//  - 캘린더 (`false`): no bar — just the notice, in a card that hugs its
//    content (up to 92% of the screen, then scrolls).
//  Both share the top bar: 원문 / AI 번역 on the left, ✕ on the right
//  (a tap on the dim area closes it too).
//
//  Takes a `NoticeDetailContent`, so it also shows a 캘린더 schedule that
//  has no notice behind it (title, category and period only — the body,
//  the 원문/AI번역 toggle and "원문 보기" are dropped).
//
//  Admin actions: when `onEdit`/`onDelete` are given (NoticeListView passes
//  them only to admins, only for 학생회 notices), a ⋮ in the top bar opens a
//  `PopupMenu` with 수정/삭제. 삭제 asks first (`CommentDeleteDialog`, the
//  same confirm as a post's) and shows a failure in `ErrorDialog`.
//

import SwiftUI

struct NoticeDetailView: View {
    let content: NoticeDetailContent
    let onToggleBookmark: () -> Void
    let onDismiss: () -> Void
    /// 이전 글 / 다음 글 — `nil` disables that side of the bar.
    var onPrevious: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    /// `false` on 캘린더 — see the header comment.
    var showsNavigationBar = true
    /// Admin 수정 — `nil` hides it.
    var onEdit: (() -> Void)? = nil
    /// Admin 삭제, run after the confirm — `nil` hides it.
    var onDelete: (() async throws -> Void)? = nil

    init(
        content: NoticeDetailContent,
        onToggleBookmark: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onPrevious: (() -> Void)? = nil,
        onNext: (() -> Void)? = nil,
        showsNavigationBar: Bool = true,
        onEdit: (() -> Void)? = nil,
        onDelete: (() async throws -> Void)? = nil
    ) {
        self.content = content
        self.onToggleBookmark = onToggleBookmark
        self.onDismiss = onDismiss
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.showsNavigationBar = showsNavigationBar
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    init(
        notice: Notice,
        onToggleBookmark: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onPrevious: (() -> Void)? = nil,
        onNext: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() async throws -> Void)? = nil
    ) {
        self.init(
            content: NoticeDetailContent(notice: notice),
            onToggleBookmark: onToggleBookmark,
            onDismiss: onDismiss,
            onPrevious: onPrevious,
            onNext: onNext,
            onEdit: onEdit,
            onDelete: onDelete
        )
    }

    @State private var isShowingTranslation = false
    /// Drives the open motion — see the card's `.mask`.
    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAdminMenuOpen = false
    @State private var isDeleteConfirmPresented = false
    @State private var deleteErrorMessage: String?

    private var hasAdminActions: Bool { onEdit != nil || onDelete != nil }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Figma fill `rgba(53,53,53,0.6)` on the top-level frame.
                Color.dimOverlayStrong
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)

                card(maxHeight: proxy.size.height * 0.92)
                    .frame(
                        maxWidth: proxy.size.width - Spacing.md * 2,
                        maxHeight: proxy.size.height * 0.92
                    )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            // Outside the card's clip so the menu can overhang it.
            .popupMenu(isPresented: $isAdminMenuOpen, items: adminMenuItems)
            .overlay {
                adminDialog
            }
            .animation(.easeOut(duration: 0.2), value: isDeleteConfirmPresented)
            .animation(.easeOut(duration: 0.2), value: deleteErrorMessage)
        }
    }

    /// Height of the strip the card unrolls from (about its top bar).
    private static let revealStartHeight: CGFloat = 96

    /// Height of `NoticeDetailNavigationBar` (its own fixed `frame(height:)`).
    private static let navigationBarHeight: CGFloat = 42

    private func card(maxHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            topSection

            if showsNavigationBar {
                scrollWithNavigationBar
            } else {
                huggingScroll
            }
        }
        .padding(Spacing.sm)
        .background(Color.appBackground)
        // Opens by unrolling from the middle: the card is laid out at its
        // final size from the start, and only this rounded mask grows from
        // a strip to the full card. Nothing inside moves, so no part (the
        // 원문/AI 번역 tabs used to) trails behind — animating the layout
        // itself made text views run their own, later position animation.
        .mask {
            GeometryReader { proxy in
                let full = proxy.size.height
                let start = min(Self.revealStartHeight, full)
                RoundedRectangle(cornerRadius: Radius.card)
                    .frame(height: isRevealed ? full : start)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // 동작 줄이기: fade only, no unrolling.
            if reduceMotion {
                isRevealed = true
            } else {
                withAnimation(.noticeDetail) { isRevealed = true }
            }
        }
    }

    /// 공지사항 tab. 이전 글/다음 글 is part of the scroll content, so a long
    /// body only reveals it once scrolled to the end. The content is also
    /// stretched to at least the viewport's height with the bar overlaid at
    /// its bottom, so under a short body the bar still sits flush with the
    /// bottom of the card instead of floating right under the text.
    ///
    /// (A `Spacer` between body and bar can't do this: a `ScrollView`
    /// proposes unbounded height, so the `Spacer` collapses even under
    /// `.frame(minHeight:)`. The overlay is sized by that frame instead, so
    /// it lands on the frame's bottom edge either way.)
    private var scrollWithNavigationBar: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    mainContent

                    // Reserves the bar's space so it never covers text.
                    Color.clear
                        .frame(height: Self.navigationBarHeight)
                }
                .frame(minHeight: viewport.size.height, alignment: .top)
                .overlay(alignment: .bottom) {
                    NoticeDetailNavigationBar(
                        onPrevious: onPrevious,
                        onGoToList: onDismiss,
                        onNext: onNext
                    )
                }
                .padding(.horizontal, Self.scrollIndicatorGutter)
            }
            .padding(.horizontal, -Self.scrollIndicatorGutter)
        }
    }

    /// The scroll views reach this far into the card's side padding while
    /// their content stays put, so the scroll bar runs in that margin
    /// instead of over the text's right edge.
    private static let scrollIndicatorGutter: CGFloat = Spacing.cardInset

    /// 캘린더: as tall as the content, never taller — the card's own max
    /// height still caps it, and then it scrolls.
    private var huggingScroll: some View {
        ViewThatFits(in: .vertical) {
            mainContent
                .padding(.bottom, Spacing.xs)
            ScrollView {
                mainContent
                    .padding(.bottom, Spacing.xs)
                    .padding(.horizontal, Self.scrollIndicatorGutter)
            }
            .padding(.horizontal, -Self.scrollIndicatorGutter)
        }
    }

    /// Height held for a 학생회 notice's photo while it loads (or failed).
    private static let imagePlaceholderHeight: CGFloat = 200

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            header

            if let imageURL = content.imageURL {
                RemoteImage(url: imageURL, contentMode: .fit, placeholderHeight: Self.imagePlaceholderHeight)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.inputField))
                    .accessibilityLabel(Text(.noticeImage))
            }

            if let body = content.body {
                bodyContent(body)
                    .font(.noticeDetailBody).tracking(Tracking.noticeDetailBody)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let sourceURL = content.sourceURL {
                originalLink(sourceURL)
            }
        }
    }

    /// "학과 홈페이지에서 원문 보기 ↗" under the body — the crawled body is
    /// plain text only (images, tables and attachments are dropped), so the
    /// department page is where those live. Opens in Safari via `Link`
    /// rather than an in-app `SFSafariViewController`, which would need a
    /// system `.sheet`.
    private func originalLink(_ url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: Spacing.xxs) {
                Text(.noticeViewOriginal)
                    .tracking(Tracking.noticeDetailBackLabel)
                Image(systemName: "arrow.up.right")
            }
            .font(.noticeDetailBackLabel)
            .foregroundStyle(Color.eventAccent)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
    }

    private var topSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            topBar
            // Separates the 원문/AI번역 toggle from the notice; with only ✕
            // up there (a schedule) it would just box in empty space.
            if content.body != nil {
                Divider()
                    .overlay(Color.borderLight)
            }
        }
    }

    /// 원문/AI번역 toggle on the left (notices only), admin ⋮ and ✕ on the
    /// right — the same on 공지사항 and 캘린더.
    private var topBar: some View {
        HStack(spacing: Spacing.sm) {
            if content.body != nil {
                TranslationToggle(isShowingTranslation: $isShowingTranslation)
            }
            Spacer(minLength: Spacing.xs)
            if hasAdminActions {
                adminMenuButton
            }
            closeButton
        }
        // Keeps the bar's height when it holds only ✕ (schedules).
        .frame(minHeight: 28)
    }

    private static let closeIconSize: CGFloat = 16

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: Self.closeIconSize, height: Self.closeIconSize)
                .foregroundStyle(Color.textSecondary)
                .minimumHitTarget(inset: (44 - Self.closeIconSize) / 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.commonClose))
    }

    // MARK: - Admin

    private static let adminMenuIconWidth: CGFloat = 24
    /// Draws 24pt wide but taps at 44×44: the shape reaches past the icon
    /// without changing the bar's layout.
    private static let adminMenuTouchExtension = (44 - adminMenuIconWidth) / 2

    private var adminMenuButton: some View {
        Button {
            isAdminMenuOpen.toggle()
        } label: {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundStyle(Color.textPrimary)
                .frame(width: Self.adminMenuIconWidth)
                .padding(Self.adminMenuTouchExtension)
                .contentShape(Rectangle())
                .padding(-Self.adminMenuTouchExtension)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.communityMore))
        .popupMenuAnchor()
    }

    private var adminMenuItems: [PopupMenuItem] {
        var items: [PopupMenuItem] = []
        if let onEdit {
            items.append(PopupMenuItem(id: "edit", systemImage: "pencil", titleKey: .commentEdit, action: onEdit))
        }
        if onDelete != nil {
            items.append(PopupMenuItem(id: "delete", systemImage: "trash", titleKey: .commentDelete, role: .destructive) {
                isDeleteConfirmPresented = true
            })
        }
        return items
    }

    @ViewBuilder
    private var adminDialog: some View {
        if isDeleteConfirmPresented || deleteErrorMessage != nil {
            ZStack {
                Color.dimOverlay
                    .ignoresSafeArea()
                    .onTapGesture {
                        isDeleteConfirmPresented = false
                        deleteErrorMessage = nil
                    }

                Group {
                    if let deleteErrorMessage {
                        ErrorDialog(titleKey: .commonError, message: deleteErrorMessage) {
                            self.deleteErrorMessage = nil
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
        guard let onDelete else { return }
        Task {
            do {
                try await onDelete()
            } catch {
                deleteErrorMessage = String(appLocalized: .noticeDeleteFailed(error.localizedDescription))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                FilterChip(category: content.category, style: .badge)

                Text(content.dateText)
                    .font(.noticeDetailDate).tracking(Tracking.noticeDetailDate)
                    .foregroundStyle(Color.textSecondary)

                if let deadlineDays = content.deadlineDays {
                    separatorDot

                    Text(.noticeDeadline(deadlineDays))
                        .font(.noticeDeadline).tracking(Tracking.noticeDeadline)
                        .foregroundStyle(Color.accentRed)
                }
            }

            HStack(alignment: .top, spacing: Spacing.xs) {
                Text(content.title)
                    .font(.noticeDetailTitle).tracking(Tracking.noticeDetailTitle)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                BookmarkButton(
                    isBookmarked: content.isBookmarked,
                    tint: content.category.accentColor,
                    action: onToggleBookmark
                )
            }
        }
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.gray400)
            .frame(width: 4, height: 4)
    }

    @ViewBuilder
    private func bodyContent(_ body: String) -> some View {
        if isShowingTranslation {
            if let translatedText = content.translatedText {
                Text(translatedText)
            } else {
                Text(.noticeNoTranslation)
                    .foregroundStyle(Color.gray400)
            }
        } else if body.isEmpty {
            Text(.noticeOriginalUnavailable)
                .foregroundStyle(Color.gray400)
        } else {
            Text(body)
        }
    }
}

#Preview("공지") {
    NoticeDetailView(
        notice: Notice.mockList[2],
        onToggleBookmark: {},
        onDismiss: {},
        onNext: {}
    )
}

#Preview("캘린더 — 공지 일정") {
    var notice = Notice.mockList[0]
    notice.category = .studentCouncil
    notice.isBookmarked = true
    return NoticeDetailView(content: NoticeDetailContent(notice: notice), onToggleBookmark: {}, onDismiss: {}, showsNavigationBar: false)
}

#Preview("캘린더 — 학사일정") {
    let start = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 20))!
    let end = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 22))!
    return NoticeDetailView(
        content: NoticeDetailContent(schedule: CalendarEvent(id: 1, category: .academic, title: "2학기 기말고사 기간", startDate: start, endDate: end)),
        onToggleBookmark: {},
        onDismiss: {},
        showsNavigationBar: false
    )
}

// MARK: - Shared motion

extension Animation {
    /// How the notice detail card comes and goes — 공지사항 and 캘린더 use
    /// this one value so both open with exactly the same motion: the fade
    /// (`noticeDetailTransition`) and the card unrolling from the middle
    /// (the card's mask in `NoticeDetailView`).
    static let noticeDetail: Animation = .default
}

extension View {
    /// Transition for the notice detail card (a plain fade), paired with
    /// `.animation(.noticeDetail, value:)` on the screen hosting it.
    func noticeDetailTransition() -> some View {
        transition(.opacity).zIndex(1)
    }
}
