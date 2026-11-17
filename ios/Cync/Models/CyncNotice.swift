//
//  CyncNotice.swift
//  Cync
//
//  A single "Cync 공지" entry — in-app announcements posted by the Cync
//  team itself (e.g. version-update notes), shown on "6-2 Cync 공지" /
//  "6-2-1 공지사항 내용". Distinct from the school/student-council board
//  backing `Notice`/`NoticeListView`. Comes from `GET /api/app-notices`
//  (`AppNotice`, converted in AppNotice.swift).
//
//  Body format (proposed for the future API): `content` is Markdown, so
//  links (`[text](url)`) render tappable — the detail screen styles them
//  with the accent color + underline. Images are a separate `imageURLs`
//  list shown under the body at full width, since SwiftUI's `Text` can't
//  render inline Markdown images.
//

import Foundation

struct CyncNotice: Identifiable, Hashable {
    let id: Int
    var title: String
    var date: Date
    var content: String
    /// Pinned notices sit at the top of the list (with a pin icon),
    /// regardless of date.
    var isPinned: Bool = false
    var imageURLs: [URL] = []
    /// Shown as a popup when the app launches (`AppNotice.isPopup`) —
    /// marked with a "팝업" tag on the list and detail.
    var isPopup: Bool = false

    var dateText: String {
        RelativeTime.absoluteDateText(for: date)
    }

    /// `content` parsed as Markdown, keeping its line breaks. Falls back to
    /// the raw text if it isn't valid Markdown.
    var attributedContent: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: content, options: options))
            ?? AttributedString(content)
    }
}

extension CyncNotice {
    /// List order: pinned first, then newest first.
    static func sortedForList(_ notices: [CyncNotice]) -> [CyncNotice] {
        notices.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.date > rhs.date
        }
    }

    /// Shape-only stand-in for the loading skeleton (rendered under
    /// `.redacted`, so its text is never shown) and for `#Preview`s — not
    /// a real notice.
    static let placeholder = CyncNotice(
        id: 0,
        title: "Cync notice title placeholder",
        date: .now,
        content: "Notice body placeholder"
    )
}
