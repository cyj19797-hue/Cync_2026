//
//  CommentInputBar.swift
//  Cync
//
//  Figma `294:1984` ("댓글 입력 영역") — pinned to the bottom of
//  "5-1 게시글", but only while composing: nothing is shown until the
//  post's comment icon or a comment's reply icon is tapped, so the
//  comments' gray panel runs to the bottom of the screen. When opened it's
//  익명 checkbox | growing text field | 등록, and it focuses the field
//  itself so the keyboard always comes up. It goes away again once the
//  keyboard is dismissed with nothing typed and no reply in progress (the
//  screen owns that rule).
//
//  There's no "OO에게 답글 작성 중" strip: which comment you're replying
//  to is shown on that comment itself (its reply icon turns
//  `secondaryAccent` — see `CommentRow.isReplyTarget`).
//
//  The field grows up to 5 lines (`TextField(axis: .vertical)`), then
//  scrolls inside itself. "등록" stays gray and disabled until there's
//  non-blank text.
//
//  The bar itself doesn't handle the keyboard — the detail screen places it
//  with `.safeAreaInset(edge: .bottom)`, which SwiftUI already lifts to sit
//  right above the keyboard.
//

import SwiftUI

struct CommentInputBar: View {
    @Binding var text: String
    @Binding var isAnonymous: Bool
    /// Shown at all — see the header comment.
    @Binding var isComposing: Bool
    var isSubmitting: Bool = false
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    private var canSubmit: Bool {
        !isSubmitting && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        if isComposing {
            composer
            .background(Color.appBackground.ignoresSafeArea(.container, edges: .bottom))
            .overlay(alignment: .top) {
                Divider().overlay(Color.borderLight)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            // Focus once the composer is actually in place — setting it in
            // the same instant it's inserted can be dropped mid-transition,
            // leaving the field without a cursor (and no keyboard).
            .task {
                try? await Task.sleep(for: .milliseconds(100))
                isFocused.wrappedValue = true
            }
        }
    }

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

#Preview {
    struct PreviewHost: View {
        @State private var text = ""
        @State private var isAnonymous = true
        @State private var isComposing = true
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()
                CommentInputBar(
                    text: $text,
                    isAnonymous: $isAnonymous,
                    isComposing: $isComposing,
                    isFocused: $isFocused,
                    onSubmit: {}
                )
            }
        }
    }
    return PreviewHost()
}
