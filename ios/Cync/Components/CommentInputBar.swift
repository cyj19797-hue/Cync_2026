//
//  CommentInputBar.swift
//  Cync
//
//  Figma `294:1984` ("댓글 입력 영역") — pinned to the bottom of
//  "5-1 게시글": 익명 checkbox | growing text field | 등록. It replaced the
//  old centered popup (`CommentComposeView`), which covered the comments it
//  was replying to, overlapped the keyboard, and only took one line.
//
//  The field grows up to 5 lines (`TextField(axis: .vertical)`), then
//  scrolls inside itself. "등록" stays gray and disabled until there's
//  non-blank text. When replying, a strip above the bar says who to
//  ("익명1에게 답글 작성 중") with ✕ to go back to a plain comment.
//
//  The bar itself doesn't handle the keyboard — the detail screen places it
//  with `.safeAreaInset(edge: .bottom)`, which SwiftUI already lifts to sit
//  right above the keyboard.
//

import SwiftUI

struct CommentInputBar: View {
    @Binding var text: String
    @Binding var isAnonymous: Bool
    /// Who the reply is to ("익명1", "글쓴이"); `nil` for a plain comment.
    var replyingTo: String?
    var isSubmitting: Bool = false
    var isFocused: FocusState<Bool>.Binding
    let onCancelReply: () -> Void
    let onSubmit: () -> Void

    private var canSubmit: Bool {
        !isSubmitting && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if let replyingTo {
                replyBanner(replyingTo)
            }

            HStack(alignment: .bottom, spacing: Spacing.xs) {
                CheckboxToggle(isChecked: $isAnonymous, titleKey: .commonAnonymous, spacing: Spacing.xxs)
                    .frame(minHeight: Self.fieldMinHeight)

                TextField(String(appLocalized: .commentPlaceholder), text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(Color.textPrimary)
                    .focused(isFocused)
                    .padding(.horizontal, Spacing.cardInset)
                    .padding(.vertical, Spacing.xs)
                    .frame(minHeight: Self.fieldMinHeight)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.inputField)
                            .fill(Color.surface)
                    }

                Button(action: onSubmit) {
                    // Ready: bold `accentStrong` (~5:1). Empty: regular gray
                    // — weight and color both change, so the two states
                    // don't rely on a color difference alone.
                    Text(.commentSubmit)
                        .font(.categoryChip).tracking(Tracking.categoryChip)
                        .fontWeight(canSubmit ? .bold : .regular)
                        .foregroundStyle(canSubmit ? Color.accentStrong : Color.gray400)
                        .frame(minWidth: 44, minHeight: Self.fieldMinHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
        .background(Color.appBackground.ignoresSafeArea(.container, edges: .bottom))
        .overlay(alignment: .top) {
            Divider().overlay(Color.borderLight)
        }
        .animation(.easeOut(duration: 0.2), value: replyingTo)
    }

    /// One line of field text plus its vertical padding — the checkbox and
    /// "등록" are pinned to this height so they line up with a single-line
    /// field, then stay at the bottom as the field grows.
    private static let fieldMinHeight: CGFloat = 40

    private func replyBanner(_ name: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(.commentReplyingTo(name))
                .font(.commentReplyButton).tracking(Tracking.commentReplyButton)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Button(action: onCancelReply) {
                Image(systemName: "xmark")
                    .font(.commentReplyButton)
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 20, height: 20)
                    .minimumHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.commentCancelReply))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.calendarSurface)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var text = ""
        @State private var isAnonymous = true
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()
                CommentInputBar(
                    text: $text,
                    isAnonymous: $isAnonymous,
                    replyingTo: "익명1",
                    isFocused: $isFocused,
                    onCancelReply: {},
                    onSubmit: {}
                )
            }
        }
    }
    return PreviewHost()
}
