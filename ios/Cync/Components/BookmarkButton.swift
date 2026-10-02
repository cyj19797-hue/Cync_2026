//
//  BookmarkButton.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//
//  Figma node `I44:269;256:5689` ("bookmark") — Code Connect mapped it to a
//  Material 3 `Bookmark` component with no literal SwiftUI snippet, so it is
//  reproduced here with the matching SF Symbol (`bookmark`/`bookmark.fill`,
//  not the `.square` variant — that one draws its own square border box,
//  which isn't wanted here). `.resizable().scaledToFit()` in a fixed square
//  frame keeps the glyph's own proportions (no stretching/cropping) while
//  giving it an even, slightly larger square footprint than the symbol's
//  default (taller-than-wide) rendered size.
//
//  The glyph stays 16pt, but the tap target is padded out to 44×44pt (Apple's
//  minimum) and the padding is then taken back with a negative padding, so
//  every call site (notice row/detail, calendar row) keeps its 16pt layout.
//  Bookmarked color is the brand blue (`eventAccent`) — red read as a
//  warning/urgent state rather than "saved".
//
//  Removing a bookmark asks for confirmation first (`.confirmationDialog`,
//  same pattern as SettingsView's 로그아웃/회원탈퇴) — `action` only fires
//  once that's confirmed. Adding one (`isBookmarked == false`) fires
//  `action` immediately, no confirmation needed.
//

import SwiftUI

struct BookmarkButton: View {
    let isBookmarked: Bool
    let action: () -> Void

    @State private var isConfirmingRemoval = false

    private static let glyphSize: CGFloat = 16
    private static let hitPadding: CGFloat = (44 - glyphSize) / 2

    var body: some View {
        Button {
            if isBookmarked {
                isConfirmingRemoval = true
            } else {
                action()
            }
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .resizable()
                .scaledToFit()
                .frame(width: Self.glyphSize, height: Self.glyphSize)
                .padding(Self.hitPadding)
                .contentShape(Rectangle())
        }
        .padding(-Self.hitPadding)
        .buttonStyle(.plain)
        .foregroundStyle(isBookmarked ? Color.eventAccent : Color.textSecondary)
        .accessibilityLabel(Text(isBookmarked ? LocalizedStringResource.bookmarkRemove : .bookmarkAdd))
        .confirmationDialog(Text(.bookmarkConfirmRemove), isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
            Button(.bookmarkRemoveAction, role: .destructive, action: action)
        }
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        BookmarkButton(isBookmarked: false) {}
        BookmarkButton(isBookmarked: true) {}
    }
    .padding()
}

