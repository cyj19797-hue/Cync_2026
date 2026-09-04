//
//  NoticeDetailNavigationBar.swift
//  test
//
//  Figma node `55:3647` ("리모콘") — the pill-shaped 이전 글 / 목록으로 / 다음 글
//  control at the bottom of the "2-1 공지글" detail card. Code Connect
//  fell back to generic icon-library names (`ArrowLeftCircle`, `List`,
//  `ArrowRightCircle`); mapped here to their closest SF Symbols.
//

import SwiftUI

struct NoticeDetailNavigationBar: View {
    let onPrevious: (() -> Void)?
    let onGoToList: () -> Void
    let onNext: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            button(systemImage: "arrow.left.circle", titleKey: "이전 글", iconLeading: true, action: onPrevious)
            Spacer(minLength: 0)
            button(systemImage: "list.bullet", titleKey: "목록으로", iconLeading: true, action: onGoToList)
            Spacer(minLength: 0)
            button(systemImage: "arrow.right.circle", titleKey: "다음 글", iconLeading: false, action: onNext)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 42)
        .background(Capsule().fill(Color.controlPillBackground))
    }

    private func button(
        systemImage: String,
        titleKey: LocalizedStringKey,
        iconLeading: Bool,
        action: (() -> Void)?
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Spacing.xxs) {
                if iconLeading {
                    Image(systemName: systemImage)
                }
                Text(titleKey)
                    .font(.remoteNavLabel)
                if !iconLeading {
                    Image(systemName: systemImage)
                }
            }
            .foregroundStyle(action == nil ? Color.gray400 : Color.textPrimary)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

#Preview {
    NoticeDetailNavigationBar(onPrevious: nil, onGoToList: {}, onNext: {})
        .padding()
}
