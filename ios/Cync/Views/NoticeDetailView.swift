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

                card
                    .frame(maxWidth: 353, maxHeight: proxy.size.height * 0.85)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            backButton

            VStack(alignment: .leading, spacing: Spacing.sm) {
                header
                TranslationToggle(isShowingTranslation: $isShowingTranslation)

                Divider()
                    .overlay(Color.borderLight)

                ScrollView {
                    bodyContent
                        .font(.noticeDetailBody)
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.xxs)
                }

                NoticeDetailNavigationBar(
                    onPrevious: onPrevious,
                    onGoToList: onDismiss,
                    onNext: onNext
                )
            }
            .padding(Spacing.xs)
        }
        .padding(Spacing.xs)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }

    private var backButton: some View {
        Button(action: onDismiss) {
            HStack(spacing: 2) {
                NavigationChevron(direction: .left, color: .textSecondary)
                Text("목록으로")
                    .font(.noticeDetailBackLabel)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .padding(Spacing.sm)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                NoticeCategoryBadge(category: notice.category)
                Text(notice.dateText)
                    .font(.noticeDetailDate)
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)

                if let deadlineDays = notice.deadlineDays {
                    Text("D-\(deadlineDays)")
                        .font(.noticeDeadline)
                        .foregroundStyle(Color.accentRed)
                }
            }

            HStack(alignment: .top, spacing: Spacing.xs) {
                Text(notice.title)
                    .font(.noticeDetailTitle)
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
