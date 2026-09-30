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

import SwiftUI

struct NoticeDetailView: View {
    let notice: Notice
    let onToggleBookmark: () -> Void
    let onDismiss: () -> Void
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?

    @State private var isShowingTranslation = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Figma fill `rgba(53,53,53,0.6)` on the top-level frame.
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)

                card(maxHeight: proxy.size.height * 0.92)
                    .frame(
                        maxWidth: proxy.size.width - Spacing.md * 2,
                        maxHeight: proxy.size.height * 0.92
                    )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    /// Height of `NoticeDetailNavigationBar` (its own fixed `frame(height:)`).
    private static let navigationBarHeight: CGFloat = 42

    /// 이전 글/다음 글 is part of the scroll content, so a long body only
    /// reveals it once scrolled to the end. The content is also stretched to
    /// at least the scroll viewport's height with the bar overlaid at its
    /// bottom, so under a short body the bar still sits flush with the
    /// bottom of the card instead of floating right under the text.
    ///
    /// (A `Spacer` between body and bar can't do this: a `ScrollView`
    /// proposes unbounded height, so the `Spacer` collapses even under
    /// `.frame(minHeight:)`. The overlay is sized by that frame instead, so
    /// it lands on the frame's bottom edge either way.)
    private func card(maxHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            topSection

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
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            header

            bodyContent
                .font(.noticeDetailBody).tracking(Tracking.noticeDetailBody)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let sourceURL = notice.sourceURL {
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
            Divider()
                .overlay(Color.borderLight)
        }
    }

    /// "목록으로" back button + the 원문/AI번역 토글, side by side.
    private var topBar: some View {
        HStack(spacing: Spacing.xs) {
            backButton
            Spacer(minLength: Spacing.xs)
            TranslationToggle(isShowingTranslation: $isShowingTranslation)
        }
    }

    private var backButton: some View {
        Button(action: onDismiss) {
            HStack(spacing: 2) {
                NavigationChevron(direction: .left, color: .textSecondary)
                Text(.noticeBackToList)
                    .font(.noticeDetailBackLabel).tracking(Tracking.noticeDetailBackLabel)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                FilterChip(category: notice.category, style: .badge)

                Text(notice.dateText)
                    .font(.noticeDetailDate).tracking(Tracking.noticeDetailDate)
                    .foregroundStyle(Color.textSecondary)

                if let deadlineDays = notice.deadlineDays {
                    separatorDot

                    Text(.noticeDeadline(deadlineDays))
                        .font(.noticeDeadline).tracking(Tracking.noticeDeadline)
                        .foregroundStyle(Color.accentRed)
                }
            }

            HStack(alignment: .top, spacing: Spacing.xs) {
                Text(notice.title)
                    .font(.noticeDetailTitle).tracking(Tracking.noticeDetailTitle)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                BookmarkButton(isBookmarked: notice.isBookmarked, action: onToggleBookmark)
            }
        }
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.gray400)
            .frame(width: 4, height: 4)
    }

    @ViewBuilder
    private var bodyContent: some View {
        if isShowingTranslation {
            if let translatedText = notice.translatedText {
                Text(translatedText)
            } else {
                Text(.noticeNoTranslation)
                    .foregroundStyle(Color.gray400)
            }
        } else if notice.originalText.isEmpty {
            Text(.noticeOriginalUnavailable)
                .foregroundStyle(Color.gray400)
        } else {
            Text(notice.originalText)
        }
    }
}

#Preview {
    NoticeDetailView(
        notice: Notice.mockList[2],
        onToggleBookmark: {},
        onDismiss: {},
        onPrevious: nil,
        onNext: { }
    )
}
