//
//  ProfileEditSheet.swift
//  Cync
//
//  "프로필 수정" — nickname + profile color, saved together with
//  `PUT /api/me/profile` (`docs/API.md` §1). No Figma frame exists for it.
//
//  A custom bottom sheet (not a system `.sheet`, per CLAUDE.md): a dimmed
//  backdrop plus a white card pinned to the bottom with a drag handle. The
//  host shows it as a full-screen overlay. Built this way so closing can be
//  intercepted — tapping the backdrop, dragging the card down, or ✕ with
//  unsaved changes asks "변경사항을 버릴까요?" first (no changes: it just
//  closes).
//
//  Layout, top to bottom: handle, title + ✕, one-line note on where the
//  nickname/color show up, then a scrolling body (live avatar preview,
//  nickname field with the 2~10자 rule + counter + errors, 3×3 color grid)
//  and the save button pinned under it. The card sits above the keyboard
//  (it follows the keyboard safe area), and the body scrolls when space is
//  short — small phones, the keyboard up, or large text sizes — so the
//  save button stays visible.
//
//  Saving: the button is disabled until the nickname is valid and
//  something changed; while saving it reads "저장 중…" and ignores taps.
//  Success closes the sheet (the settings card updates from the view
//  model at once); failure shows the message inside the sheet and keeps
//  what was typed.
//

import SwiftUI

struct ProfileEditSheet: View {
    let currentNickname: String
    let currentColor: ProfileColor
    /// Saves and returns `nil` on success, or the error to show.
    let onSave: (String, ProfileColor) async -> String?
    let onClose: () -> Void

    @State private var nickname: String
    @State private var color: ProfileColor
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var isDiscardConfirmPresented = false
    @State private var dragOffset: CGFloat = 0
    /// Natural height of the scrolling body, so the card hugs its content
    /// and only scrolls once it runs out of room.
    @State private var bodyHeight: CGFloat = 0

    /// No length rule in the API spec, so the app sets one.
    static let nicknameLength = 2...10

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 3)

    init(
        currentNickname: String,
        currentColor: ProfileColor,
        onSave: @escaping (String, ProfileColor) async -> String?,
        onClose: @escaping () -> Void
    ) {
        self.currentNickname = currentNickname
        self.currentColor = currentColor
        self.onSave = onSave
        self.onClose = onClose
        _nickname = State(initialValue: currentNickname)
        _color = State(initialValue: currentColor)
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNicknameValid: Bool {
        Self.nicknameLength.contains(trimmedNickname.count)
    }

    private var hasChanges: Bool {
        trimmedNickname != currentNickname || color != currentColor
    }

    private var canSave: Bool {
        isNicknameValid && hasChanges && !isSaving
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { attemptClose() }

            // Space above the keyboard (or the home indicator). The card is
            // never more than 90% of it — the body scrolls instead — and is
            // pinned to its bottom (`alignment: .bottom`: a max-height frame
            // otherwise centers a shorter card inside itself).
            GeometryReader { proxy in
                card
                    .frame(maxHeight: proxy.size.height * 0.9, alignment: .bottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .offset(y: dragOffset)
            }

            if isDiscardConfirmPresented {
                discardConfirm
            }
        }
        .animation(.easeOut(duration: 0.2), value: isDiscardConfirmPresented)
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            dragArea

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ProfileAvatar(nickname: trimmedNickname, color: color, size: 64)
                        .frame(maxWidth: .infinity)
                    nicknameSection
                    colorSection
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.md)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bodyHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: bodyHeight > 0 ? bodyHeight : nil)

            saveButton
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.cardInset)
        }
        .frame(maxWidth: .infinity)
        // The white runs on past the card's bottom, under the home
        // indicator to the screen edge (and, with the keyboard up, behind
        // it), so there's no gap below the sheet.
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: Radius.card, topTrailingRadius: Radius.card)
                .fill(Color.appBackground)
                .padding(.bottom, -100)
        }
    }

    /// Handle + title + ✕ + note — dragging here pulls the card down.
    private var dragArea: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Capsule()
                .fill(Color.gray300)
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xs)
                .accessibilityHidden(true)

            HStack {
                Text(.profileEditTitle)
                    .font(.myLockerTitle).tracking(Tracking.myLockerTitle)
                    .foregroundStyle(Color.textPrimary)
                Spacer(minLength: 0)
                Button {
                    attemptClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.navigationChevron)
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.commonClose))
            }

            Text(.profileEditHint)
                .font(.noticeDate).tracking(Tracking.noticeDate)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.md)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.height)
                }
                .onEnded { value in
                    let shouldClose = value.translation.height > 100
                    withAnimation(.easeOut(duration: 0.2)) { dragOffset = 0 }
                    if shouldClose { attemptClose() }
                }
        )
    }

    // MARK: - Nickname

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.commonNickname)
                .font(.categoryBadge).tracking(Tracking.categoryBadge)
                .foregroundStyle(Color.gray700)

            // Bordered field: `borderLight`, `accentStrong` while focused.
            LabeledInputField(
                placeholder: .profileSetupNicknamePlaceholder,
                text: $nickname,
                submitLabel: .done,
                onSubmit: save,
                showsClearButton: true,
                focusesOnAppear: true
            )
            .onChange(of: nickname) { _, _ in saveError = nil }

            HStack(alignment: .firstTextBaseline) {
                if let message = nicknameMessage {
                    Text(message)
                        .foregroundStyle(Color.accentRed)
                } else {
                    Text(.profileEditLengthRule(Self.nicknameLength.lowerBound, Self.nicknameLength.upperBound))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: Spacing.xs)
                Text(.commonCounter(trimmedNickname.count, Self.nicknameLength.upperBound))
                    .foregroundStyle(trimmedNickname.count > Self.nicknameLength.upperBound ? Color.accentRed : Color.textSecondary)
                    .monospacedDigit()
            }
            .font(.noticeDate).tracking(Tracking.noticeDate)
        }
    }

    /// A length problem (only once the nickname has been edited — an
    /// existing nickname that predates the rule isn't flagged on open) or
    /// the last save's error; `nil` shows the rule instead.
    private var nicknameMessage: String? {
        if let saveError { return saveError }
        if trimmedNickname != currentNickname && !trimmedNickname.isEmpty && !isNicknameValid {
            return String(appLocalized: .profileEditLengthError(Self.nicknameLength.lowerBound, Self.nicknameLength.upperBound))
        }
        return nil
    }

    // MARK: - Color

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(.profileEditColor)
                .font(.categoryBadge).tracking(Tracking.categoryBadge)
                .foregroundStyle(Color.gray700)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(ProfileColor.allCases, id: \.self) { option in
                    colorSwatch(option)
                }
            }
        }
    }

    /// A 36pt dot inside a 44×44pt tap target; the selected one gets a ring
    /// and a check mark, so selection doesn't depend on the ring alone.
    private func colorSwatch(_ option: ProfileColor) -> some View {
        let isSelected = color == option
        return Button {
            color = option
        } label: {
            Circle()
                .fill(option.swatch)
                .frame(width: 36, height: 36)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.navigationChevron)
                            .foregroundStyle(option == .yellow ? Color.textPrimary : Color.white)
                    }
                }
                .padding(3)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(Color.textPrimary, lineWidth: 2)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(option.nameKey))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Save

    private var saveButton: some View {
        PrimaryActionButton(
            titleKey: isSaving ? .profileEditSaving : .commonSave,
            isEnabled: canSave,
            tint: .buttonAccent,
            action: save
        )
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        saveError = nil
        Task {
            let error = await onSave(trimmedNickname, color)
            isSaving = false
            if let error {
                saveError = error
            } else {
                onClose()
            }
        }
    }

    // MARK: - Closing

    private func attemptClose() {
        guard !isSaving else { return }
        if hasChanges {
            isDiscardConfirmPresented = true
        } else {
            onClose()
        }
    }

    private var discardConfirm: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isDiscardConfirmPresented = false }

            DialogCard {
                Text(.profileEditDiscardTitle)
                    .font(.dialogTitle).tracking(Tracking.dialogTitle)
                    .foregroundStyle(Color.textPrimary)
                    .dialogTitleGap()

                Text(.profileEditDiscardMessage)
                    .font(.dialogBody).tracking(Tracking.dialogBody)
                    .foregroundStyle(Color.textSecondary)
                    .dialogBodyGap()

                DialogActionRow {
                    DialogActionButton(titleKey: .profileEditKeepEditing) {
                        isDiscardConfirmPresented = false
                    }
                    DialogActionButton(titleKey: .profileEditDiscard, style: .primary) {
                        isDiscardConfirmPresented = false
                        onClose()
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .transition(.opacity)
    }
}

#Preview {
    ProfileEditSheet(
        currentNickname: "코딩하는펭귄",
        currentColor: .blue,
        onSave: { _, _ in nil },
        onClose: {}
    )
}
