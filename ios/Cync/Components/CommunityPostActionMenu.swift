//
//  CommunityPostActionMenu.swift
//  test
//
//  Figma: "26 2 창학" file, frame `433:2329` ("커뮤니티 - 액션메뉴") — the
//  공유하기/저장하기/신고하기(+시스템 취소) sheet behind every post's "더보기"
//  kebab button. This maps directly to `.confirmationDialog`: a native
//  action sheet already renders exactly this — rounded card, one row per
//  option, a destructive option in red, and a separate Cancel button below
//  (added automatically) — so no custom `.sheet` or hand-drawn handle bar
//  is used here, unlike the two report-reason sheets below.
//
//  Shared by CommunityView and CommunityPostDetailView (both have their own
//  "더보기" button) via the `.communityPostActionMenu(target:)` modifier,
//  instead of duplicating this 3-step confirmationDialog → report sheet →
//  success sheet chain in both screens.
//

import SwiftUI

extension View {
    /// `target` is the post a "더보기" button was tapped for; the row/header
    /// sets it, this modifier drives the whole 공유/저장/신고 → 신고사유입력 →
    /// 신고완료 flow, and resets `target` back to `nil` when finished.
    func communityPostActionMenu(target: Binding<CommunityPost?>) -> some View {
        modifier(CommunityPostActionMenuModifier(target: target))
    }
}

private struct CommunityPostActionMenuModifier: ViewModifier {
    @Binding var target: CommunityPost?
    @State private var reportingPost: CommunityPost?
    @State private var isReportSubmittedPresented = false
    @State private var didSubmitReport = false

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "더보기",
                isPresented: Binding(
                    get: { target != nil && reportingPost == nil },
                    set: { isPresented in if !isPresented { target = nil } }
                ),
                titleVisibility: .hidden
            ) {
                Button("공유하기") {
                    // TODO: UIActivityViewController 기반 공유 시트 연동 필요
                    target = nil
                }
                Button("저장하기") {
                    // TODO: 게시글 저장/북마크 기능 연동 필요
                    target = nil
                }
                Button("신고하기", role: .destructive) {
                    reportingPost = target
                }
            }
            .sheet(item: $reportingPost, onDismiss: {
                target = nil
                if didSubmitReport {
                    didSubmitReport = false
                    isReportSubmittedPresented = true
                }
            }) { _ in
                ReportReasonSheet {
                    didSubmitReport = true
                    reportingPost = nil
                }
            }
            .sheet(isPresented: $isReportSubmittedPresented) {
                ReportSubmittedView {
                    isReportSubmittedPresented = false
                }
            }
    }
}
