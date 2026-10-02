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

import SwiftUI

struct CyncNoticeDetailView: View {
    let notice: CyncNotice
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .settingsCyncNotice, onBack: { dismiss() })

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
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.md)
            }
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            CyncNoticeReadStore.shared.markRead(notice.id)
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

#Preview {
    NavigationStack {
        CyncNoticeDetailView(notice: .placeholder)
    }
}
