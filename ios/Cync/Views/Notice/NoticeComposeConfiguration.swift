//
//  NoticeComposeConfiguration.swift
//  Cync
//
//  학생회 공지 작성/수정 (admin only) — the shared `PostComposeView` with
//  the 공지 title, a 사진 첨부 row instead of 익명, and
//  `/api/notices/council` (`docs/API.md` §3, multipart). The author isn't
//  typed on screen: `CyncAPI.createCouncilNotice` takes it from
//  `CurrentUserSession`. Editing previews the current image; it can be
//  replaced but not removed (the server has no way to delete it).
//
//  `NoticeComposeTarget` is what NoticeListView pushes to open it.
//

import SwiftUI

/// Which 공지 compose screen to push from NoticeListView.
enum NoticeComposeTarget: Hashable {
    case create
    /// `noticeId` is the list's `Notice.id`, `councilId` the server row.
    case edit(noticeId: Int, councilId: Int, title: String, content: String, imageURL: URL?)

    init?(editing notice: Notice) {
        guard let councilId = notice.councilId else { return nil }
        self = .edit(
            noticeId: notice.id,
            councilId: councilId,
            title: notice.title,
            content: notice.originalText,
            imageURL: notice.imageURL
        )
    }
}

extension PostComposeConfiguration {
    static func councilNoticeCreate(onCreated: @escaping (CouncilNotice) -> Void) -> Self {
        PostComposeConfiguration(
            navigationTitleKey: .noticeComposeTitle,
            contentPlaceholderKey: .noticeComposeContentPlaceholder,
            showsImageAttachment: true,
            failureMessage: { String(appLocalized: .noticeComposeCreateFailed($0)) },
            submit: { draft in
                let notice = try await CyncAPI.createCouncilNotice(
                    title: draft.title,
                    content: draft.content,
                    image: draft.image
                )
                await MainActor.run { onCreated(notice) }
            }
        )
    }

    static func councilNoticeEdit(
        councilId: Int,
        title: String,
        content: String,
        imageURL: URL?,
        onUpdated: @escaping (CouncilNotice) -> Void
    ) -> Self {
        PostComposeConfiguration(
            navigationTitleKey: .noticeComposeEdit,
            submitKey: .commonSave,
            contentPlaceholderKey: .noticeComposeContentPlaceholder,
            initialTitle: title,
            initialContent: content,
            showsImageAttachment: true,
            initialImageURL: imageURL,
            failureMessage: { String(appLocalized: .noticeComposeUpdateFailed($0)) },
            submit: { draft in
                let notice = try await CyncAPI.updateCouncilNotice(
                    id: councilId,
                    title: draft.title,
                    content: draft.content,
                    image: draft.image
                )
                await MainActor.run { onUpdated(notice) }
            }
        )
    }
}
