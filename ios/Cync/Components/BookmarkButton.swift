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
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isBookmarked ? Color.accentRed : Color.textPrimary)
        .accessibilityLabel(isBookmarked ? "북마크 해제" : "북마크")
        .confirmationDialog("북마크를 취소하시겠습니까?", isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
            Button("북마크 취소", role: .destructive, action: action)
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

