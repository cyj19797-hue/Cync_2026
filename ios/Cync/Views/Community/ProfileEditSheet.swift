//
//  ProfileEditSheet.swift
//  Cync
//
//  `PUT /api/me/profile` (`docs/API.md` §1) takes a nickname *and* a color
//  together, and the doc's own suggested UI is "닉네임 입력창 + 9가지 색상
//  팔레트" — no Figma frame for this exists yet, so this sheet is a plain,
//  minimal form rather than a designed screen. Replaces SettingsView's old
//  nickname-only `.alert`, which had nowhere to put the color picker a
//  native alert can't host.
//

import SwiftUI

struct ProfileEditSheet: View {
    let currentNickname: String
    let currentColor: ProfileColor
    let onSave: (String, ProfileColor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String
    @State private var color: ProfileColor

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5)

    init(currentNickname: String, currentColor: ProfileColor, onSave: @escaping (String, ProfileColor) -> Void) {
        self.currentNickname = currentNickname
        self.currentColor = currentColor
        self.onSave = onSave
        _nickname = State(initialValue: currentNickname)
        _color = State(initialValue: currentColor)
    }

    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("닉네임")
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(Color.textSecondary)
                TextField("닉네임", text: $nickname)
                    .font(.noticeTitle).tracking(Tracking.noticeTitle)
                    .foregroundStyle(Color.textPrimary)
                    .padding(Spacing.xs)
                    .background(Color.gray50)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.chipDefault))
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("프로필 색상")
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(Color.textSecondary)
                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(ProfileColor.allCases, id: \.self) { option in
                        colorSwatch(option)
                    }
                }
            }

            PrimaryActionButton(titleKey: "저장", isEnabled: canSave) {
                onSave(nickname, color)
                dismiss()
            }
        }
        .padding(Spacing.md)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Text("프로필 수정")
                .font(.myLockerTitle).tracking(Tracking.myLockerTitle)
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
    }

    private func colorSwatch(_ option: ProfileColor) -> some View {
        Button {
            color = option
        } label: {
            Circle()
                .fill(option.swatch)
                .frame(width: 36, height: 36)
                .overlay {
                    if color == option {
                        Circle().strokeBorder(Color.textPrimary, lineWidth: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ProfileEditSheet(currentNickname: "코딩하는펭귄", currentColor: .blue) { _, _ in }
        }
}
