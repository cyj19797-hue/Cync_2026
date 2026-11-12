//
//  CommunityPostComposeView.swift
//  Cync
//
//  "5-2 게시글 등록" — 커뮤니티 글쓰기. A thin wrapper: the screen itself is
//  the shared `PostComposeView` (Views/Shared/PostComposeView.swift); this
//  file only says what's community-specific — the 글쓰기 title, the 익명
//  row (remembered between posts), and `POST /api/posts` (`docs/API.md`
//  §2; `nickname`/`color` are left out so the server applies the caller's
//  profile defaults).
//

import SwiftUI

struct CommunityPostComposeView: View {
    /// Called with the created post before the screen closes — lets
    /// CommunityView prepend it to its feed.
    var onSubmit: (CommunityPost) -> Void = { _ in }

    var body: some View {
        PostComposeView(configuration: .communityPost(onSubmit: onSubmit))
    }
}

extension PostComposeConfiguration {
    static func communityPost(onSubmit: @escaping (CommunityPost) -> Void) -> Self {
        PostComposeConfiguration(
            navigationTitleKey: .communityWrite,
            showsAnonymousToggle: true,
            remembersAnonymousChoice: true,
            failureMessage: { String(appLocalized: .communityPostFailed($0)) },
            submit: { draft in
                let post = try await CyncAPI.createPost(
                    title: draft.title,
                    content: draft.content,
                    isAnonymous: draft.isAnonymous
                )
                await MainActor.run { onSubmit(post) }
            }
        )
    }
}

#Preview {
    NavigationStack {
        CommunityPostComposeView()
    }
}
