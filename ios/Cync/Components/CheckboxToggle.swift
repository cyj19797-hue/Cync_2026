//
//  CheckboxToggle.swift
//  test
//
//  Figma node `228:1775` ("checkbox") — the "익명" square checkbox on the
//  post-compose screen. iOS has no native checkbox control (SwiftUI's
//  `Toggle` renders as a switch), so this small custom button reproduces
//  Figma's square + checkmark look — a plain SwiftUI shape, not a case
//  needing UIKit.
//
//  `checkedFill`/`checkedBorderColor`/`checkmarkColor` all default to the
//  original gray-outline look (unaffected when unchecked either way), so
//  the "익명" checkbox above is unaffected. "1-5 로그인"'s "학번 기억하기"
//  checkbox overrides them to Figma's filled-blue-with-white-check style
//  instead of duplicating the whole component for one color variant.
//

import SwiftUI

struct CheckboxToggle: View {
    @Binding var isChecked: Bool
    let titleKey: LocalizedStringKey
    var checkedFill: Color = .surface
    var checkedBorderColor: Color = .borderLight
    var checkmarkColor: Color = .textPrimary

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: Spacing.xxs) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isChecked ? checkedFill : Color.surface)
                    .frame(width: 20, height: 20)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isChecked ? checkedBorderColor : Color.borderLight, lineWidth: 1.2)
                    }
                    .overlay {
                        if isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(checkmarkColor)
                        }
                    }

                Text(titleKey)
                    .font(.categoryBadge)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var isChecked = false
        var body: some View {
            CheckboxToggle(isChecked: $isChecked, titleKey: "익명")
                .padding()
        }
    }
    return PreviewHost()
}
