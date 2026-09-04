//
//  BookmarkButton.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//
//  Figma node `I44:269;256:5689` ("bookmark") — Code Connect mapped it to a
//  Material 3 `Bookmark` component with no literal SwiftUI snippet, so it is
//  reproduced here with the matching SF Symbol (`bookmark` / `bookmark.fill`).
//

import SwiftUI

struct BookmarkButton: View {
    let isBookmarked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
        }
        .buttonStyle(.plain)
        .foregroundStyle(isBookmarked ? Color.accentRed : Color.textPrimary)
        .accessibilityLabel(isBookmarked ? "북마크 해제" : "북마크")
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        BookmarkButton(isBookmarked: false) {}
        BookmarkButton(isBookmarked: true) {}
    }
    .padding()
}

