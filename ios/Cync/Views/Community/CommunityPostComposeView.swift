//
//  CommunityPostComposeView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `228:1697` ("5-2 게시글 등록").
//  Back-chevron + centered "글쓰기" title + "완료" submit button
//  (`228:1708`), a title field + "익명" checkbox (`228:1714`/`228:1774`),
//  and a placeholder-driven content editor (`228:1719`).
//
//  Frame-naming convention (design-to-code guide §2): a name like "…등록"
//  (not "Sheet"/"Modal") plus Figma's own back-chevron (not an X button)
//  means this is a *pushed* destination, not a `.sheet` — the back chevron
//  is the cancel/dismiss affordance, matching what CommunityView wires
//  below via `.navigationDestination(isPresented:)`.
//
//  Beyond Figma:
//  - "등록" (same word as the comment box) is gray on `surface` until both
//    title and content are filled, then white on `accentStrong` (~4.5:1).
//    It stays tappable while gray: a tap then says what's missing in a
//    toast and moves the cursor to the empty field.
//  - Leaving (back button or edge swipe) with anything typed asks
//    "나가면 작성글이 사라집니다. 그래도 나가시겠습니까?" (취소 / 확인)
//    first; with nothing typed it just leaves.
//  - The title field is focused on open; "다음" on the keyboard moves to
//    the content.
//  - "익명" sits on its own row under the divider (it used to share the
//    title row and squeeze long titles), with what it does written beside
//    it when checked, and is remembered for next time.
//  - Vertical rhythm (kept tight): header → title 12 (as on every screen),
//    title → divider 12, divider → 익명 row 0 (the 44pt row has its own
//    air), 익명 row → content text 8.
//
//  No UIKit anywhere on this screen — see PlaceholderTextEditor.swift and
//  CheckboxToggle.swift for why the two trickiest-looking controls
//  (placeholder text editor, square checkbox) still don't need it.
//

import SwiftUI

struct CommunityPostComposeView: View {
    @StateObject private var viewModel = CommunityPostComposeViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Called when "등록" is tapped with a valid draft — lets CommunityView
    /// prepend the new post to its feed.
    var onSubmit: (CommunityPost) -> Void = { _ in }

    private enum Field {
        case title
        case content
    }

    @FocusState private var focusedField: Field?
    @State private var isDiscardConfirmPresented = false
    @State private var toastMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .communityWrite, onBack: attemptLeave) {
                submitButton
            }

            titleRow

            Divider()
                .overlay(Color.borderLight)

            anonymousRow

            // The editor fills the rest of the screen, so a tap anywhere
            // below the text starts typing too.
            PlaceholderTextEditor(
                text: $viewModel.content,
                placeholder: .communityContentPlaceholder,
                font: .communityPostBody,
                placeholderColor: .textSecondary,
                textColor: .textPrimary
            )
            .focused($focusedField, equals: .content)
            .padding(.horizontal, Spacing.screenHorizontal)
            // 8pt from the 익명 row to the first line of text — the
            // editor's own top inset.
            .padding(.top, Spacing.xs - PlaceholderTextEditor.textTopInset)
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        // With something typed, the system swipe-back is switched off (it
        // can't be intercepted) and the edge strip below takes its place,
        // asking first. With nothing typed the normal swipe works.
        .navigationBarBackButtonHidden(viewModel.hasInput)
        .overlay(alignment: .leading) {
            if viewModel.hasInput {
                edgeSwipeArea
            }
        }
        .toast(message: $toastMessage)
        .overlay {
            if isDiscardConfirmPresented {
                discardConfirm
            } else if let message = viewModel.errorMessage {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ErrorDialog(titleKey: .commonError, message: message) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: isDiscardConfirmPresented)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .task {
            // Wait out the push transition, or the focus doesn't take.
            try? await Task.sleep(for: .milliseconds(150))
            focusedField = .title
        }
    }

    private var titleRow: some View {
        TextField(
            "",
            text: $viewModel.title,
            prompt: Text(.communityTitlePlaceholder).foregroundStyle(Color.textSecondary)
        )
        .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
        .foregroundStyle(Color.textPrimary)
        .focused($focusedField, equals: .title)
        .submitLabel(.next)
        .onSubmit { focusedField = .content }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.screenContentTop)
        .padding(.bottom, Spacing.cardInset)
    }

    /// "익명" checkbox (one 44pt-tall tap target with its label) and, when
    /// checked, what it does — beside the label, on the same 44pt row, so
    /// checking or unchecking never moves the content below.
    private var anonymousRow: some View {
        HStack(spacing: Spacing.xxs) {
            CheckboxToggle(isChecked: $viewModel.isAnonymous, titleKey: .commonAnonymous, minHeight: 44)

            if viewModel.isAnonymous {
                Text(.communityAnonymousHint)
                    .font(.noticeDate).tracking(Tracking.noticeDate)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private static let submitButtonHeight: CGFloat = 32
    private static let submitTouchExtension = (44 - submitButtonHeight) / 2

    /// Gray until both fields are filled. 32pt tall to look at, at least
    /// 44×44pt to tap: the tappable shape reaches 6pt past the top and
    /// bottom without changing the layout.
    private var submitButton: some View {
        Button(action: submit) {
            Text(.communityPostSubmit)
                .font(.headerActionButton).tracking(Tracking.headerActionButton)
                .foregroundStyle(viewModel.canSubmit ? Color.white : Color.textSecondary)
                .padding(.horizontal, Spacing.md)
                .frame(minWidth: 44, minHeight: Self.submitButtonHeight)
                .background {
                    // Active: `accentStrong`, so the white label is ~4.5:1.
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(viewModel.canSubmit ? Color.accentStrong : Color.surface)
                }
                .padding(.vertical, Self.submitTouchExtension)
                .contentShape(Rectangle())
                .padding(.vertical, -Self.submitTouchExtension)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSubmitting)
        .accessibilityHint(viewModel.canSubmit ? Text(verbatim: "") : Text(.communityComposeMissingFields))
    }

    private func submit() {
        guard viewModel.canSubmit else {
            toastMessage = String(appLocalized: .communityComposeMissingFields)
            focusedField = viewModel.isTitleEmpty ? .title : .content
            return
        }
        Task {
            if let post = await viewModel.submit() {
                onSubmit(post)
                dismiss()
            }
        }
    }

    // MARK: - Leaving

    private func attemptLeave() {
        if viewModel.hasInput {
            focusedField = nil
            isDiscardConfirmPresented = true
        } else {
            dismiss()
        }
    }

    /// Stands in for the system swipe-back while there's input: a drag
    /// from the left edge asks before leaving. As wide as the side margin,
    /// so it never covers the text.
    private var edgeSwipeArea: some View {
        Color.clear
            .frame(width: Spacing.screenHorizontal)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        if value.translation.width > 60 && abs(value.translation.height) < value.translation.width {
                            attemptLeave()
                        }
                    }
            )
    }

    private var discardConfirm: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isDiscardConfirmPresented = false }

            DialogCard {
                Text(.communityLeaveDraftTitle)
                    .font(.dialogTitle).tracking(Tracking.dialogTitle)
                    .foregroundStyle(Color.textPrimary)
                    .dialogTitleGap()

                Text(.communityLeaveDraftMessage)
                    .font(.dialogBody).tracking(Tracking.dialogBody)
                    .foregroundStyle(Color.textSecondary)
                    .dialogBodyGap()

                DialogActionRow {
                    DialogActionButton(titleKey: .commonCancel) {
                        isDiscardConfirmPresented = false
                    }
                    DialogActionButton(titleKey: .commonOk, style: .primary) {
                        isDiscardConfirmPresented = false
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .transition(.opacity)
    }
}

#Preview {
    NavigationStack {
        CommunityPostComposeView()
    }
}
