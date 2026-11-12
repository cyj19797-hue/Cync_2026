//
//  PostComposeConfiguration.swift
//  Cync
//
//  What differs between the screens built on `PostComposeView` — 커뮤니티
//  글쓰기, 학생회 공지 작성, 학생회 공지 수정. Everything else (layout,
//  등록 button, leave confirm, toast/error handling, focus, edge swipe)
//  lives once in `PostComposeView`, so changing it there changes every
//  mode at once.
//
//  Each mode builds its configuration next to the screen that opens it:
//  `.communityPost(onSubmit:)` in CommunityPostComposeView.swift,
//  `.councilNoticeCreate/.councilNoticeEdit` in NoticeComposeConfiguration.swift.
//

import Foundation

/// What the user typed, handed to `PostComposeConfiguration.submit`.
struct PostComposeDraft {
    let title: String
    let content: String
    /// Always `false` when the mode hides the 익명 row.
    let isAnonymous: Bool
    /// A newly picked photo, already shrunk to a ≤1MB JPEG. `nil` = none
    /// picked (in edit mode: keep the existing image).
    let image: Data?
}

struct PostComposeConfiguration {
    /// Top bar title — 글쓰기 / 공지 작성 / 공지 수정.
    var navigationTitleKey: LocalizedStringResource
    /// Top bar action — 등록 for new posts, 저장 when editing.
    var submitKey: LocalizedStringResource = .communityPostSubmit
    var titlePlaceholderKey: LocalizedStringResource = .communityTitlePlaceholder
    var contentPlaceholderKey: LocalizedStringResource = .communityContentPlaceholder

    /// The 익명 checkbox row (community only).
    var showsAnonymousToggle = false
    /// Restores the last 익명 choice and saves new ones
    /// (UserDefaults `postComposePostsAnonymously`). Community only.
    var remembersAnonymousChoice = false

    /// Pre-filled text for edit modes. Leaving without changing it doesn't
    /// ask for confirmation.
    var initialTitle = ""
    var initialContent = ""

    /// The 사진 첨부 row (학생회 공지 only) — one photo.
    var showsImageAttachment = false
    /// Edit mode: the notice's current image, previewed in the 사진 첨부
    /// row. It can only be replaced, not removed (the server can't delete
    /// an image), so it gets no X button.
    var initialImageURL: URL? = nil

    /// Popup message when `submit` throws — gets the error's description.
    var failureMessage: (String) -> String

    /// Sends the draft. Throwing shows `failureMessage` and keeps the
    /// screen open; returning closes it.
    var submit: (PostComposeDraft) async throws -> Void
}
