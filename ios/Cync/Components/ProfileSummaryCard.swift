//
//  ProfileSummaryCard.swift
//  test
//
//  Figma node `47:1067` ("마이페이지") — the bordered card at the top of the
//  settings screen: an avatar, the nickname, and an edit (pencil) button.
//

import SwiftUI

struct ProfileSummaryCard: View {
    let nickname: String
    /// `nil` while `GET /api/me` hasn't resolved yet — falls back to the
    /// same neutral gray the avatar used before `profileColor` existed.
    var profileColor: ProfileColor?
    let onEditNickname: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // TODO: Assets/서버에서 실제 프로필 이미지 추가 필요 — 지금은 색상 원으로만 표시.
            Circle()
                .fill(profileColor?.swatch.opacity(0.5) ?? Color.gray.opacity(0.3))
                .frame(width: 90, height: 90)

            Button(action: onEditNickname) {
                HStack(spacing: Spacing.xxs) {
                    Text(nickname)
                        .font(.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray50)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.borderLight)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.scheduleCard))
    }
}

#Preview {
    ProfileSummaryCard(nickname: "코딩하는펭귄", profileColor: .blue) {}
        .padding()
}
