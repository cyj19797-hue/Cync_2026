//
//  CyncNoticeComposeConfiguration.swift
//  Cync
//
//  Cync 공지 작성/수정 (admin only, Figma `734:4284`) — the shared
//  `PostComposeView` with the "Cync 공지 작성/수정" title, no 익명 or 사진
//  첨부 row, and an "앱 실행 시 팝업으로 띄우기" switch in their place.
//  Posts to `/api/app-notices` (`docs/API.md` §8, form-urlencoded).
//
//  `CyncNoticeComposeTarget` is what CyncNoticeListView pushes to open it.
//

import Foundation

/// Which Cync 공지 compose screen to push.
enum CyncNoticeComposeTarget: Hashable {
    case create
    case edit(CyncNotice)
}

extension PostComposeConfiguration {
    private static func appNoticePopupToggle(initialValue: Bool) -> PostComposeExtraToggle {
        PostComposeExtraToggle(
            labelKey: .appNoticeComposePopupToggle,
            hintKey: .appNoticeComposePopupHint,
            initialValue: initialValue
        )
    }

    static func appNoticeCreate(initialPopup: Bool = false, onCreated: @escaping (CyncNotice) -> Void) -> Self {
        PostComposeConfiguration(
            navigationTitleKey: .appNoticeComposeTitle,
            contentPlaceholderKey: .noticeComposeContentPlaceholder,
            extraToggle: appNoticePopupToggle(initialValue: initialPopup),
            failureMessage: { String(appLocalized: .appNoticeComposeCreateFailed($0)) },
            submit: { draft in
                let notice = try await CyncAPI.createAppNotice(
                    title: draft.title,
                    content: draft.content,
                    isPopup: draft.extraToggle
                )
                await MainActor.run { onCreated(CyncNotice(notice)) }
            }
        )
    }

    /// Pre-filled with the notice's title, content and popup flag.
    static func appNoticeEdit(notice: CyncNotice, onUpdated: @escaping (CyncNotice) -> Void) -> Self {
        PostComposeConfiguration(
            navigationTitleKey: .appNoticeComposeEdit,
            submitKey: .commonSave,
            contentPlaceholderKey: .noticeComposeContentPlaceholder,
            initialTitle: notice.title,
            initialContent: notice.content,
            extraToggle: appNoticePopupToggle(initialValue: notice.isPopup),
            failureMessage: { String(appLocalized: .appNoticeComposeUpdateFailed($0)) },
            submit: { draft in
                let updated = try await CyncAPI.updateAppNotice(
                    id: notice.id,
                    title: draft.title,
                    content: draft.content,
                    isPopup: draft.extraToggle
                )
                await MainActor.run { onUpdated(CyncNotice(updated)) }
            }
        )
    }
}
