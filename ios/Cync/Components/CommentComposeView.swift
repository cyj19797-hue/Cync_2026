//
//  CommentComposeView.swift
//  Cync
//
//  Comment/reply composer, presented as a `.sheet` from
//  CommunityPostDetailView — same bottom-sheet chrome as
//  Views/ReportReasonSheet.swift (header + close button,
//  `.presentationDetents([.medium])` + drag indicator) and the same
//  enabled/disabled submit-button pattern as CommunityPostComposeView's
//  "완료" button, reused directly via `PrimaryActionButton` rather than
//  redrawing it.
//

import SwiftUI

struct CommentComposeView: View {
    /// The parent comment's author when replying, so the header can show
    /// "OO님에게 답글 남기는 중"; nil for a new top-level comment.
    var replyingToAuthor: String?
    var onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            header

            if let replyingToAuthor {
                Text("\(replyingToAuthor)님에게 답글 남기는 중")
                    .font(.noticeDate)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.sm)
            }

            Divider()
                .overlay(Color.borderLight)

            PlaceholderTextEditor(
                text: $text,
                placeholder: "댓글을 입력하세요.",
                font: .communityPostBody,
                placeholderColor: .gray400,
                textColor: .textPrimary
            )
            .frame(height: 120)
            .padding(Spacing.sm)

            PrimaryActionButton(titleKey: "등록", isEnabled: canSubmit) {
                onSubmit(text)
                dismiss()
            }
            .padding(Spacing.md)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Text(replyingToAuthor == nil ? "댓글 달기" : "답글 달기")
                .font(.myLockerTitle)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.gray50))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.sm)
    }
}

#Preview("새 댓글") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CommentComposeView(onSubmit: { _ in })
        }
}

#Preview("답글") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CommentComposeView(replyingToAuthor: "익명", onSubmit: { _ in })
        }
}
