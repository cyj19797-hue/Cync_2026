//
//  CommentComposeView.swift
//  Cync
//
//  Figma: "26 2 창학" file, component `294:1984` ("댓글 입력 영역") for the
//  익명 체크박스 + single-line input pill + inline "등록" button, wrapped in
//  `DialogCard` (Radius.card) per this project's UI rule (CLAUDE.md): a
//  centered custom popup, not `.sheet` — no drag handle, no forced bottom-
//  slide chrome. `CommunityPostDetailView` presents this as a ZStack +
//  dimmed-backdrop overlay (`composeOverlay`), the same pattern
//  `LockerApplicationConfirmDialog`/`NoticeDetailView` already use, rather
//  than a system sheet.
//
//  This view has no dismiss action of its own — tapping the dim backdrop
//  behind it (handled by the presenter) is the only way to cancel; tapping
//  "등록" just calls `onSubmit` and leaves closing the popup to the caller.
//
//  The "익명" checkbox reuses `CheckboxToggle` (the same "익명" control
//  CommunityPostComposeView already uses for posts) and finally gives
//  comments the anonymous toggle `CommunityPostDetailViewModel.addComment`
//  always hardcoded to `true` for, since no UI exposed it before.
//

import SwiftUI

struct CommentComposeView: View {
    /// The parent comment's author when replying, so the card can show
    /// "OO님에게 답글 남기는 중" and title itself "답글 달기"; nil for a new
    /// top-level comment ("댓글 달기").
    var replyingToAuthor: String?
    var onSubmit: (String, Bool) -> Void

    @State private var text: String = ""
    @State private var isAnonymous = true

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        DialogCard {
            Text(replyingToAuthor == nil ? "댓글 달기" : "답글 달기")
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)

            if let replyingToAuthor {
                Text("\(replyingToAuthor)님에게 답글 남기는 중")
                    .font(.noticeDate).tracking(Tracking.noticeDate)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.bottom, Spacing.xxs)
            }

            CheckboxToggle(isChecked: $isAnonymous, titleKey: "익명")
                .padding(.vertical, Spacing.xxs)

            HStack(spacing: Spacing.xs) {
                TextField("댓글을 입력하세요.", text: $text)
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(Color.textPrimary)

                Button("등록") {
                    onSubmit(text, isAnonymous)
                }
                .font(.categoryBadge).tracking(Tracking.categoryBadge)
                .foregroundStyle(canSubmit ? Color.eventAccent : Color.gray400)
                .disabled(!canSubmit)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.inputField)
                    .strokeBorder(Color.borderLight)
            }
        }
    }
}

#Preview("새 댓글") {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        CommentComposeView(onSubmit: { _, _ in })
            .padding(.horizontal, Spacing.md)
    }
}

#Preview("답글") {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        CommentComposeView(replyingToAuthor: "익명", onSubmit: { _, _ in })
            .padding(.horizontal, Spacing.md)
    }
}
