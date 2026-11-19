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
//  Both modes have the 행사 날짜 section (`PostComposeEventDateOption`);
//  editing opens with the notice's current date.
//
//  `NoticeComposeTarget` is what NoticeListView pushes to open it.
//

import SwiftUI

/// Which 공지 compose screen to push from NoticeListView.
enum NoticeComposeTarget: Hashable {
    case create
    /// `noticeId` is the list's `Notice.id`, `councilId` the server row.
    case edit(
        noticeId: Int,
        councilId: Int,
        title: String,
        content: String,
        imageURL: URL?,
        eventStart: Date?,
        eventEnd: Date?
    )

    init?(editing notice: Notice) {
        guard let councilId = notice.councilId else { return nil }
        self = .edit(
            noticeId: notice.id,
            councilId: councilId,
            title: notice.title,
            content: notice.originalText,
            imageURL: notice.imageURL,
            eventStart: notice.eventStartDate,
            eventEnd: notice.eventEndDate
        )
    }
}

extension PostComposeConfiguration {
    static func councilNoticeCreate(onCreated: @escaping (CouncilNotice) -> Void) -> Self {
        PostComposeConfiguration(
            navigationTitleKey: .noticeComposeTitle,
            contentPlaceholderKey: .noticeComposeContentPlaceholder,
            showsImageAttachment: true,
            eventDate: PostComposeEventDateOption(),
            failureMessage: { String(appLocalized: .noticeComposeCreateFailed($0)) },
            submit: { draft in
                let notice = try await withEventDateErrors(draft) {
                    try await CyncAPI.createCouncilNotice(
                        title: draft.title,
                        content: draft.content,
                        image: draft.image,
                        eventDate: draft.eventDate
                    )
                }
                await MainActor.run { onCreated(notice) }
            }
        )
    }

    static func councilNoticeEdit(
        councilId: Int,
        title: String,
        content: String,
        imageURL: URL?,
        eventStart: Date? = nil,
        eventEnd: Date? = nil,
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
            eventDate: PostComposeEventDateOption(initialStart: eventStart, initialEnd: eventEnd),
            failureMessage: { String(appLocalized: .noticeComposeUpdateFailed($0)) },
            submit: { draft in
                let notice = try await withEventDateErrors(draft) {
                    try await CyncAPI.updateCouncilNotice(
                        id: councilId,
                        title: draft.title,
                        content: draft.content,
                        image: draft.image,
                        eventDate: draft.eventDate
                    )
                }
                await MainActor.run { onUpdated(notice) }
            }
        )
    }

    /// The server answers a bad date range (end without start, end before
    /// start) with 400 — shown as "날짜를 다시 확인해 주세요" instead of the
    /// generic failure message. Without date parameters a 400 isn't about
    /// the date, so it falls through unchanged.
    private static func withEventDateErrors<T>(
        _ draft: PostComposeDraft,
        _ send: () async throws -> T
    ) async throws -> T {
        do {
            return try await send()
        } catch CyncAPIError.badStatus(400) where draft.eventDate != .none {
            throw PostComposeDisplayError(message: String(appLocalized: .noticeEventDateInvalid))
        }
    }
}
