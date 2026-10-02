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
//  No UIKit anywhere on this screen — see PlaceholderTextEditor.swift and
//  CheckboxToggle.swift for why the two trickiest-looking controls
//  (placeholder text editor, square checkbox) still don't need it.
//

import SwiftUI

struct CommunityPostComposeView: View {
    @StateObject private var viewModel = CommunityPostComposeViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Called when "완료" is tapped with a valid draft — lets CommunityView
    /// prepend the new post to its feed.
    var onSubmit: (CommunityPost) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .communityWrite, onBack: { dismiss() }) {
                submitButton
            }

            titleRow

            Divider()
                .overlay(Color.borderLight)

            PlaceholderTextEditor(
                text: $viewModel.content,
                placeholder: .communityContentPlaceholder,
                font: .communityPostBody,
                placeholderColor: .gray400,
                textColor: .textPrimary
            )
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            Text(.commonError),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
            )
        ) {
            Button(.commonOk, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var titleRow: some View {
        HStack(spacing: Spacing.xs) {
            TextField(String(appLocalized: .communityTitlePlaceholder), text: $viewModel.title)
                .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
                .foregroundStyle(Color.textPrimary)

            CheckboxToggle(isChecked: $viewModel.isAnonymous, titleKey: .commonAnonymous)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.screenContentTop)
        .padding(.bottom, Spacing.cardInset)
    }

    private var submitButton: some View {
        Button {
            Task {
                if let post = await viewModel.submit() {
                    onSubmit(post)
                    dismiss()
                }
            }
        } label: {
            Text(.commonDone)
                .font(.categoryChip).tracking(Tracking.categoryChip)
                .foregroundStyle(viewModel.canSubmit ? Color.white : Color.gray400)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(viewModel.canSubmit ? Color.eventAccent : Color.surface)
                }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
    }
}

#Preview {
    NavigationStack {
        CommunityPostComposeView()
    }
}
