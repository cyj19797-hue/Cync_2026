//
//  ProfileSummaryCard.swift
//  test
//
//  Figma node `47:1067` ("마이페이지") — the card at the top of the
//  settings screen: avatar, nickname, and the way into profile editing.
//
//  Beyond Figma: the avatar shows the nickname's first letter on the
//  profile color (a plain colored circle looked unfinished), and the whole
//  card is one button to the profile editor with a chevron on the right —
//  instead of a small pencil next to the name that was well under the
//  44pt touch minimum. A "프로필 수정" line under the nickname says what the
//  tap does. The card sits on `surface` with a `gray200` outline so its
//  edge reads against the white screen.
//

import SwiftUI

struct ProfileSummaryCard: View {
    let nickname: String
    /// `nil` while `GET /api/me` hasn't resolved yet — falls back to a
    /// neutral gray.
    var profileColor: ProfileColor?
    let onEditProfile: () -> Void

    private static let avatarSize: CGFloat = 56

    var body: some View {
        Button(action: onEditProfile) {
            HStack(spacing: Spacing.cardInset) {
                ProfileAvatar(nickname: nickname, color: profileColor, size: Self.avatarSize)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(nickname)
                        .font(.noticeTitle).tracking(Tracking.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Text(.settingsEditProfile)
                        .font(.noticeDate).tracking(Tracking.noticeDate)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer(minLength: 0)

                NavigationChevron()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .strokeBorder(Color.gray200)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.scheduleCard))
            .contentShape(RoundedRectangle(cornerRadius: Radius.scheduleCard))
        }
        .buttonStyle(.plain)
        // "닉네임, 프로필 수정"
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        ProfileSummaryCard(nickname: "코딩하는펭귄", profileColor: .blue) {}
        ProfileSummaryCard(nickname: "cync", profileColor: .pink) {}
        ProfileSummaryCard(nickname: "", profileColor: nil) {}
    }
    .padding()
}
