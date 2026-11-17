//
//  CommentInputBar.swift
//  Cync
//
//  Figma `294:1984` ("댓글 입력 영역") — pinned to the bottom of
//  "5-1 게시글" with `.safeAreaInset(edge: .bottom)`, which SwiftUI already
//  lifts to sit right above the keyboard. Always on screen, so a first-time
//  visitor can see where to comment:
//
//  - Collapsed (default): a short gray pill reading "댓글을 입력하세요." —
//    lower than the expanded bar so it covers as little of the comments'
//    gray panel as possible. With a draft in progress it shows the draft's
//    first line instead (still gray). Tapping it expands the bar
//    (`onExpand`).
//  - Expanded (`isComposing`): 익명 checkbox | growing text field | 등록,
//    and it focuses the field itself so the keyboard always comes up. The
//    screen collapses it again once the keyboard is dismissed.
//  - Replying (`replyingToName` set, expanded only): a one-line strip above
//    the bar — "익명2에게 답글 작성 중" with ✕ (`onCancelReply`, back to a
//    plain comment; the draft stays).
//  - Banned (`isBanned`): the collapsed pill is drawn disabled with the ban
//    notice in it; tapping it calls `onBannedTap` (the screen shows a toast).
//
//  The field grows up to 5 lines (`TextField(axis: .vertical)`), then
//  scrolls inside itself. "등록" stays gray and disabled until there's
//  non-blank text.
//

import SwiftUI

struct CommentInputBar: View {
    @Binding var text: String
    @Binding var isAnonymous: Bool
    /// Expanded — see the header comment.
    @Binding var isComposing: Bool
    var isSubmitting: Bool = false
    /// Name of the comment being replied to, as shown on its row ("익명2").
    var replyingToName: String?
    var isBanned: Bool = false
    var isFocused: FocusState<Bool>.Binding
    /// The collapsed pill was tapped (not banned).
    var onExpand: () -> Void = {}
    /// ✕ on the reply strip.
    var onCancelReply: () -> Void = {}
    /// The collapsed pill was tapped while banned.
    var onBannedTap: () -> Void = {}
    let onSubmit: () -> Void

    private var canSubmit: Bool {
        !isSubmitting && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// First non-blank line of the draft, shown in the collapsed pill.
    private var draftPreview: String? {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isComposing && !isBanned {
                if let replyingToName {
                    replyStrip(name: replyingToName)
                        .transition(.opacity)
                }
                composer
                    .transition(.opacity)
                    // Focus once the composer is actually in place — setting
                    // it in the same instant it's inserted can be dropped
                    // mid-transition, leaving no cursor (and no keyboard).
                    .task {
                        try? await Task.sleep(for: .milliseconds(100))
                        isFocused.wrappedValue = true
                    }
            } else {
                collapsedPill
                    .transition(.opacity)
            }
        }
        .background(Color.appBackground.ignoresSafeArea(.container, edges: .bottom))
        .overlay(alignment: .top) {
            Divider().overlay(Color.borderLight)
        }
        .animation(.easeOut(duration: 0.15), value: replyingToName)
    }

    // MARK: - Collapsed

    /// One line of text plus padding — lower than the expanded field.
    private static let collapsedHeight: CGFloat = 36

    private var collapsedPill: some View {
        Button {
            isBanned ? onBannedTap() : onExpand()
        } label: {
            HStack(spacing: Spacing.xs) {
                if isBanned {
                    Image(systemName: "nosign")
                        .accessibilityHidden(true)
                }
                Group {
                    if isBanned {
                        Text(.commentInputBanned)
                    } else if let draftPreview {
                        Text(verbatim: draftPreview)
                    } else {
                        Text(.commentPlaceholder)
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.categoryBadge).tracking(Tracking.categoryBadge)
            // `textSecondary` (~4.7:1 on the pill's gray) for the hint and
            // the draft; banned is paler to read as disabled.
            .foregroundStyle(isBanned ? Color.gray400 : Color.textSecondary)
            .padding(.horizontal, Spacing.cardInset)
            .frame(minHeight: Self.collapsedHeight)
            .background {
                Capsule().fill(isBanned ? Color.surface : Color.calendarSurface)
            }
            .overlay {
                Capsule().strokeBorder(Color.borderLight)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .accessibilityLabel(Text(isBanned ? .commentInputBanned : .commentWrite))
        .accessibilityValue(draftPreview.map { Text(verbatim: $0) } ?? Text(verbatim: ""))
    }

    // MARK: - Reply strip

    private func replyStrip(name: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(.commentReplyingTo(name))
                .font(.commentReplyButton).tracking(Tracking.commentReplyButton)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onCancelReply) {
                Image(systemName: "xmark")
                    .font(.commentReplyButton)
                    .foregroundStyle(Color.textSecondary)
                    .frame(minWidth: 20, minHeight: 20)
                    .minimumHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.commentReplyCancel))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xs)
    }

    // MARK: - Expanded

    /// One line of field text plus its vertical padding — "등록" is pinned
    /// to this height so it lines up with a single-line field, then stays
    /// at the bottom as the field grows.
    private static let fieldMinHeight: CGFloat = 40

    private var composer: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            // Small, in front of the field. The choice is remembered
            // between comments (see the detail screen).
            CheckboxToggle(isChecked: $isAnonymous, titleKey: .commonAnonymous, spacing: Spacing.xxs)
                .frame(minHeight: Self.fieldMinHeight)
                .accessibilityHint(Text(.commentAnonymousHint))

            // Placeholder in `textSecondary` (~4.7:1 on the field's light
            // gray) instead of the system's much paler default.
            TextField(
                text: $text,
                prompt: Text(.commentPlaceholder).foregroundStyle(Color.textSecondary),
                axis: .vertical
            ) {
                Text(.commentPlaceholder)
            }
            .lineLimit(1...5)
            .font(.categoryBadge).tracking(Tracking.categoryBadge)
            .foregroundStyle(Color.textPrimary)
            .focused(isFocused)
            .padding(.horizontal, Spacing.cardInset)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: Self.fieldMinHeight)
            .background {
                RoundedRectangle(cornerRadius: Radius.inputField)
                    .fill(Color.calendarSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.inputField)
                    .strokeBorder(Color.borderLight)
            }

            Button(action: onSubmit) {
                // Ready: bold `accentStrong` (~4.5:1). Empty: regular gray
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
}

// MARK: - Previews

private struct CommentInputBarPreview: View {
    @State var text = ""
    @State var isComposing = false
    var replyingToName: String?
    var isBanned = false
    @State private var isAnonymous = true
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Color.calendarSurface
            CommentInputBar(
                text: $text,
                isAnonymous: $isAnonymous,
                isComposing: $isComposing,
                replyingToName: replyingToName,
                isBanned: isBanned,
                isFocused: $isFocused,
                onExpand: { isComposing = true },
                onSubmit: {}
            )
        }
    }
}

#Preview("접힘") {
    CommentInputBarPreview()
}

#Preview("펼침") {
    CommentInputBarPreview(isComposing: true)
}

#Preview("답글 작성 중") {
    CommentInputBarPreview(text: "저도 궁금해요!", isComposing: true, replyingToName: "익명2")
}

#Preview("정지된 사용자") {
    CommentInputBarPreview(isBanned: true)
}
