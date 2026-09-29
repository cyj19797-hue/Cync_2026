//
//  AgreementItemRow.swift
//  Cync
//
//  Figma node `252:5156`/`252:5185` ("동의 항목") on "1-4 이용약관 동의" — one
//  agreement line: a checkbox + label as one tap target (toggles agreement),
//  and a separate trailing chevron as another (opens the full terms text).
//  Two independent tap targets is exactly what `CheckboxToggle`'s
//  single-button "checkbox+label" API can't express, hence this dedicated
//  row instead of reusing it here.
//

import SwiftUI

struct AgreementItemRow: View {
    let titleKey: LocalizedStringKey
    @Binding var isAgreed: Bool
    var onViewDetail: () -> Void = {}

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Button {
                isAgreed.toggle()
            } label: {
                HStack(spacing: Spacing.xs) {
                    CheckboxSquare(
                        isChecked: isAgreed,
                        checkedFill: .eventAccent,
                        checkedBorderColor: .eventAccentDark,
                        checkmarkColor: .white
                    )

                    Text(titleKey)
                        .font(.termsItemLabel).tracking(Tracking.termsItemLabel)
                        .foregroundStyle(Color.textPrimary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button(action: onViewDetail) {
                NavigationChevron()
                    .padding(Spacing.xxs)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 52)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var isAgreed = false
        var body: some View {
            AgreementItemRow(titleKey: "[필수] 이용약관", isAgreed: $isAgreed)
                .padding()
        }
    }
    return PreviewHost()
}
