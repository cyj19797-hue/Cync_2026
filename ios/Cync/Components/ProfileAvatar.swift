//
//  ProfileAvatar.swift
//  Cync
//
//  Round avatar: the nickname's first letter on the profile color (50%
//  tint), gray before a color is known. Used by the settings profile card
//  and live in the profile editor's preview, so both look identical.
//

import SwiftUI

struct ProfileAvatar: View {
    let nickname: String
    let color: ProfileColor?
    var size: CGFloat = 56

    var body: some View {
        Circle()
            .fill(color?.swatch.opacity(0.5) ?? Color.gray300)
            .frame(width: size, height: size)
            .overlay {
                Text(verbatim: initial)
                    .font(.postDetailTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            .accessibilityHidden(true)
    }

    /// First character of the nickname (a whole Hangul syllable, or an
    /// uppercased letter); empty while there's no nickname.
    private var initial: String {
        nickname.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? ""
    }
}

#Preview {
    HStack {
        ProfileAvatar(nickname: "냥", color: .pink)
        ProfileAvatar(nickname: "cync", color: .blue)
        ProfileAvatar(nickname: "", color: nil)
    }
}
