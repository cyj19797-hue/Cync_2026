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

/// Measures `mainContent` (header + body, no nav bar) — a plain, non-
/// scrolling, non-flexible view, so this reads reliably. `card` uses it to
/// compute exactly how much blank space to insert before the nav bar: a
/// `Spacer` can't do this job here — under a `ScrollView`'s (unbounded)
/// layout proposal, a `Spacer` collapses to its `minLength` instead of
/// expanding, even with `.frame(minHeight:)` on an ancestor, so the gap has
/// to be sized explicitly instead of left to `Spacer` to fill.
private struct MainContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct NoticeDetailView: View {
    let notice: Notice
    let onToggleBookmark: () -> Void
    let onDismiss: () -> Void
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?

    /// `topSection` (topBar + divider) + `card`'s own outer padding + the
    /// one `VStack` spacing gap above the `ScrollView` — all fixed-height,
    /// device-independent amounts. Subtracted from `card`'s max height to
    /// get the `ScrollView`'s own viewport height (`scrollAreaHeight`).
    private static let fixedChromeHeight: CGFloat = 140

    @State private var isShowingTranslation = false
    @State private var mainContentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Figma fill `rgba(53,53,53,0.6)` on the top-level frame.
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)

                card(maxHeight: proxy.size.height * 0.85)
                    .frame(maxWidth: 353, maxHeight: proxy.size.height * 0.85)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    /// `card`'s fixed inner content width (`.frame(maxWidth: 353)` in
    /// `body`, minus the `Spacing.xl` padding on both sides) — needed to
    /// measure `mainContent`'s natural height at the same width it wraps
    /// text at for real, via the hidden copy below.
    private static let contentWidth: CGFloat = 353 - Spacing.xl * 2

    private func card(maxHeight: CGFloat) -> some View {
        let scrollAreaHeight = max(0, maxHeight - Self.fixedChromeHeight)
        // `mainContentHeight` starts at 0 (unmeasured); `max(0, ...)` then
        // reduces to `scrollAreaHeight` itself, which would shove the nav
        // bar off the bottom of a long body it hasn't actually measured
        // yet. Only fill the gap once a real (non-zero) measurement is in.
        let bottomGap = mainContentHeight > 0 ? max(0, scrollAreaHeight - mainContentHeight) : 0

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            topSection

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    mainContent

                    // Fills whatever's left of the scroll viewport when the
                    // body's short, so 이전글/목록으로/다음글 sits flush
                    // with the bottom of the card instead of floating
                    // right under a short body. Tapping this empty
                    // stretch — like tapping the dim backdrop outside the
                    // card — dismisses, same as "목록으로".
                    Color.clear
                        .frame(height: bottomGap)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onDismiss)

                    // Part of the scroll content (not fixed) — reaching
                    // the end of the body is what reveals
                    // 이전글/목록으로/다음글.
                    NoticeDetailNavigationBar(
                        onPrevious: onPrevious,
                        onGoToList: onDismiss,
                        onNext: onNext
                    )
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .background(
            // Hidden twin of `mainContent`, laid out at the same width but
            // outside the `ScrollView` — measuring it there is reliable,
            // unlike measuring `mainContent` in place inside the
            // ScrollView, where the same technique kept reporting a stale
            // 0 and never updated (ScrollView proposes unbounded height to
            // its content, which this hidden copy — sitting outside any
            // ScrollView — never receives, so it always reports its real
            // natural size).
            mainContent
                .frame(width: Self.contentWidth, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .hidden()
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: MainContentHeightKey.self, value: geo.size.height)
                    }
                )
        )
        .onPreferenceChange(MainContentHeightKey.self) { mainContentHeight = $0 }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            header

            bodyContent
                .font(.noticeDetailBody).tracking(Tracking.noticeDetailBody)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                Text("목록으로")
                    .font(.noticeDetailBackLabel).tracking(Tracking.noticeDetailBackLabel)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                NoticeCategoryBadge(category: notice.category)
                Text(notice.dateText)
                    .font(.noticeDetailDate).tracking(Tracking.noticeDetailDate)
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)

                if let deadlineDays = notice.deadlineDays {
                    Text("D-\(deadlineDays)")
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

    @ViewBuilder
    private var bodyContent: some View {
        if isShowingTranslation {
            if let translatedText = notice.translatedText {
                Text(translatedText)
            } else {
                Text("아직 번역 결과가 없습니다")
                    .foregroundStyle(Color.gray400)
            }
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
