//
//  FloatingComposeButton.swift
//  Cync
//
//  Round floating "write" button pinned to the bottom right of a feed —
//  커뮤니티 (글쓰기) and, for admins, 공지사항 (공지 작성). Place it with
//  `.overlay(alignment: .bottomTrailing) { FloatingComposeButton(...).padding(Spacing.md) }`
//  and give the list `.contentMargins(.bottom, FloatingComposeButton.reservedHeight, for: .scrollContent)`
//  so the last row isn't stuck behind it.
//

import SwiftUI

struct FloatingComposeButton: View {
    static let size: CGFloat = 56
    /// Bottom content margin a list needs under its last row: the button
    /// plus its `Spacing.md` inset, plus the same again as breathing room.
    static let reservedHeight: CGFloat = size + Spacing.md * 2

    let labelKey: LocalizedStringResource
    /// Gray and untappable — e.g. while the user is banned from the community.
    var isDisabled = false
    let action: () -> Void

    /// Side of the pencil glyph (`ComposeEdit` asset, 48×48 SVG drawn as a
    /// template so it takes `foregroundStyle`). Scales with Dynamic Type.
    @ScaledMetric(relativeTo: .headline) private var iconSize: CGFloat = 22

    var body: some View {
        Button(action: action) {
            Image("ComposeEdit")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Color.white)
                .frame(width: Self.size, height: Self.size)
                .background {
                    Circle().fill(isDisabled ? Color.gray300 : Color.buttonAccent)
                }
                .shadow(color: Color.textPrimary.opacity(0.18), radius: 8, y: 4)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(Text(labelKey))
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        FloatingComposeButton(labelKey: .communityWrite) {}
        FloatingComposeButton(labelKey: .communityWrite, isDisabled: true) {}
    }
    .padding()
}
