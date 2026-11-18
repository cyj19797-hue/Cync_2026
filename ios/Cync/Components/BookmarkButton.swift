//
//  BookmarkButton.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//
//  Figma node `I44:269;256:5689` ("bookmark"). The glyph is the project's own
//  vector asset (`Bookmark` outline / `BookmarkFill` — the same shape filled),
//  template-rendered so `foregroundStyle` colors it. Both SVGs are cropped to
//  the shape itself (stroke included), so the frame below is exactly what
//  you see — rows can center it precisely, and the size reads like the
//  other ~18pt icons on the same line.
//
//  The glyph is 18pt tall, but the tap target is padded out to 44×44pt
//  (Apple's minimum) and the padding is then taken back with a negative
//  padding, so call sites lay it out at its drawn size.
//  Off = `textSecondary`; on = `tint` — the notice's category color
//  (`NoticeCategory.accentColor`), `eventAccent` by default.
//
//  Removing a bookmark asks for confirmation first (`.confirmationDialog`,
//  same pattern as SettingsView's 로그아웃/회원탈퇴) — `action` only fires
//  once that's confirmed. Adding one (`isBookmarked == false`) fires
//  `action` immediately, no confirmation needed.
//

import SwiftUI

struct BookmarkButton: View {
    let isBookmarked: Bool
    /// Fill while bookmarked — pass `category.accentColor`.
    var tint: Color = .eventAccent
    let action: () -> Void

    @State private var isConfirmingRemoval = false

    /// Height of the drawn shape; width follows the SVG's 26.8 : 33.5.
    private static let glyphHeight: CGFloat = 18
    private static let glyphWidth: CGFloat = glyphHeight * 26.8334 / 33.5
    private static let hitPaddingH: CGFloat = (44 - glyphWidth) / 2
    private static let hitPaddingV: CGFloat = (44 - glyphHeight) / 2

    var body: some View {
        Button {
            if isBookmarked {
                isConfirmingRemoval = true
            } else {
                action()
            }
        } label: {
            Image(isBookmarked ? "BookmarkFill" : "Bookmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Self.glyphWidth, height: Self.glyphHeight)
                .padding(.horizontal, Self.hitPaddingH)
                .padding(.vertical, Self.hitPaddingV)
                .contentShape(Rectangle())
        }
        .padding(.horizontal, -Self.hitPaddingH)
        .padding(.vertical, -Self.hitPaddingV)
        .buttonStyle(.plain)
        .foregroundStyle(isBookmarked ? tint : Color.textSecondary)
        .accessibilityLabel(Text(isBookmarked ? LocalizedStringResource.bookmarkRemove : .bookmarkAdd))
        .confirmationDialog(Text(.bookmarkConfirmRemove), isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
            Button(.bookmarkRemoveAction, role: .destructive, action: action)
        }
    }
}

extension View {
    /// For a row laid out with `HStack(alignment: .firstTextBaseline)`:
    /// centers this (the bookmark) on the title's first line — on the middle
    /// of its capitals, `capHeight / 2` above the baseline — instead of on
    /// the whole row, so it lines up with where the text starts.
    /// `titleSize` is the title font's unscaled size; it's scaled like
    /// `Font.appDefault` does for the `.body` text style.
    func centeredOnFirstLine(titleSize: CGFloat, weight: UIFont.Weight = .bold) -> some View {
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: titleSize)
        let capHeight = UIFont.systemFont(ofSize: scaled, weight: weight).capHeight
        return alignmentGuide(.firstTextBaseline) { d in
            d[VerticalAlignment.center] + capHeight / 2
        }
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        BookmarkButton(isBookmarked: false) {}
        BookmarkButton(isBookmarked: true) {}
        BookmarkButton(isBookmarked: true, tint: NoticeCategory.studentCouncil.accentColor) {}
    }
    .padding()
}

