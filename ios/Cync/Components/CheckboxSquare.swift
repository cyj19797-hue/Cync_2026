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

struct CheckboxSquare: View {
    let isChecked: Bool
    var checkedFill: Color = .surface
    var checkedBorderColor: Color = .borderLight
    var checkmarkColor: Color = .textPrimary

    var body: some View {
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
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        CheckboxSquare(isChecked: false)
        CheckboxSquare(isChecked: true, checkedFill: .eventAccent, checkedBorderColor: .eventAccentDark, checkmarkColor: .white)
    }
    .padding()
}
