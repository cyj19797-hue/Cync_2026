//
//  CheckboxSquare.swift
//  Cync
//
//  The plain checkbox square (no label), pulled out of `CheckboxToggle` so
//  both it and "1-4 이용약관 동의"'s `AgreementItemRow` draw the exact same
//  fill/border/checkmark instead of maintaining two copies. `AgreementItemRow`
//  needs the checkbox and its label as independent tap targets alongside a
//  third (a trailing chevron), which doesn't fit `CheckboxToggle`'s
//  single-button "checkbox + label" API.
//

import SwiftUI

/// 체크됐을 때의 색 조합. 체크 안 된 상태는 두 스타일 모두 동일
/// (`surface` 배경 + `borderLight` 테두리).
enum CheckboxStyle {
    /// 기본 — 회색 배경 + 검정 체크 ("익명" 체크박스 등).
    case standard
    /// 강조 — 파란 배경 + 흰 체크 ("1-4 이용약관 동의", "1-5 로그인").
    case accent

    var checkedFill: Color {
        switch self {
        case .standard: return .surface
        case .accent: return .eventAccent
        }
    }

    var checkedBorderColor: Color {
        switch self {
        case .standard: return .borderLight
        case .accent: return .eventAccentLight
        }
    }

    var checkmarkColor: Color {
        switch self {
        case .standard: return .textPrimary
        case .accent: return .white
        }
    }
}

struct CheckboxSquare: View {
    let isChecked: Bool
    var style: CheckboxStyle = .standard

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isChecked ? style.checkedFill : Color.surface)
            .frame(width: 20, height: 20)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isChecked ? style.checkedBorderColor : Color.borderLight, lineWidth: 1.2)
            }
            .overlay {
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(style.checkmarkColor)
                }
            }
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        CheckboxSquare(isChecked: false)
        CheckboxSquare(isChecked: true)
        CheckboxSquare(isChecked: true, style: .accent)
    }
    .padding()
}
