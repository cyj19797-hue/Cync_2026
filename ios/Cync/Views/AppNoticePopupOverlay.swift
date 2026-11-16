//
//  AppNoticePopupOverlay.swift
//  Cync
//
//  Full-screen host for the app-launch popup notices
//  (`AppNoticePopupController`): a `dimOverlayStrong` backdrop and the
//  current `AppNoticePopupCard`. Placed by `RootView` above everything the
//  logged-in app shows — every tab, pushed screens and the tab bar — so it
//  dims the tab bar too and nothing else can open on top of it. A custom
//  overlay, not `.sheet`/`.alert` (CLAUDE.md).
//
//  - Tapping the backdrop does nothing: these are must-read notices, closed
//    only with 확인 / 다시 보지 않기.
//  - Appears with a slight grow (0.96 → 1) plus fade; with "동작 줄이기"
//    (Reduce Motion) on, fade only. Moving to the next card is the same,
//    shorter, transition.
//

import SwiftUI

struct AppNoticePopupOverlay: View {
    @ObservedObject var controller: AppNoticePopupController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Card's max height as a share of the screen.
    private static let maxHeightRatio: CGFloat = 0.75

    /// Overlay's height, for the card's 75% cap.
    @State private var containerHeight: CGFloat = .infinity

    var body: some View {
            ZStack {
                // Always in the tree, faded by opacity — an inserted
                // `Color` with an opacity transition here stayed invisible.
                Color.dimOverlayStrong
                    .ignoresSafeArea()
                    .opacity(controller.current == nil ? 0 : 1)
                    // Swallows taps so nothing underneath reacts, and
                    // deliberately doesn't close the popup.
                    .contentShape(Rectangle())
                    .onTapGesture {}
                    .accessibilityHidden(true)

                if let notice = controller.current {
                    AppNoticePopupCard(
                        notice: notice,
                        position: controller.currentPosition,
                        total: controller.total,
                        maxHeight: containerHeight * Self.maxHeightRatio,
                        onConfirm: { controller.confirm() },
                        onDontShowAgain: { controller.dismissForever() },
                        onViewDetail: { controller.openDetail() }
                    )
                    .padding(.horizontal, Spacing.sm)
                    // A new identity per notice so the next card transitions in.
                    .id(notice.id)
                    .transition(cardTransition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { containerHeight = $0 }
        .animation(.easeOut(duration: 0.22), value: controller.current?.id)
        .allowsHitTesting(controller.current != nil)
    }

    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96))
    }
}

#Preview("짧은 공지 1개") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        AppNoticePopupOverlay(controller: AppNoticePopupController(previewNotices: [.mockShortPopup]))
    }
}

#Preview("긴 본문 (스크롤)") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        AppNoticePopupOverlay(controller: AppNoticePopupController(previewNotices: [.mockLongPopup()]))
    }
}

#Preview("2개 중 첫 번째") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        AppNoticePopupOverlay(controller: AppNoticePopupController(previewNotices: [.mockShortPopup, .mockLongPopup()]))
    }
}

#Preview("큰 글자 크기") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        AppNoticePopupOverlay(controller: AppNoticePopupController(previewNotices: [.mockShortPopup, .mockLongPopup()]))
    }
    .environment(\.dynamicTypeSize, .accessibility2)
}

/// Full notice opened from the popup's 자세히 보기: `CyncNoticeDetailView`
/// pushed onto its own stack over the app (slides in from the right, back
/// button / edge swipe slides it away), so it works from any tab. The
/// stack's root is clear — popping back to it closes the host.
struct AppNoticePopupDetailHost: View {
    let notice: AppNotice
    let onClose: () -> Void

    @StateObject private var viewModel: CyncNoticeListViewModel
    @State private var path: [Int] = []

    init(notice: AppNotice, onClose: @escaping () -> Void) {
        self.notice = notice
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: CyncNoticeListViewModel(viewing: CyncNotice(notice)))
    }

    var body: some View {
        NavigationStack(path: $path) {
            Color.clear
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Int.self) { _ in
                    CyncNoticeDetailView(notice: CyncNotice(notice), viewModel: viewModel)
                }
        }
        .onAppear { path = [notice.id] }
        .onChange(of: path) { _, newPath in
            if newPath.isEmpty { onClose() }
        }
    }
}
