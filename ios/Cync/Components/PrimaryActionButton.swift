//
//  PrimaryActionButton.swift
//  test
//
//  Figma nodes `434:2345`/`434:2372`/`434:2393` ("button") — the full-width
//  submit button used across the report-reason and report-submitted
//  sheets. Disabled: Surface fill, gray400 label, 10pt radius. Enabled:
//  brandPrimary fill, white label, 7.5pt radius — the same
//  radius-changes-with-state quirk already seen on `DialogActionButton`.
//
//  `tint`/`font` default to that original look so every existing call site
//  is unaffected; "1-5 로그인"'s button reuses this component with its own
//  accent color (`eventAccent`) and a Bold (not Medium) label instead of
//  duplicating the whole button.
//

import SwiftUI

struct PrimaryActionButton: View {
    let titleKey: LocalizedStringKey
    var isEnabled: Bool = true
    var tint: Color = .brandPrimary
    var font: Font = .categoryChip
    /// Optional 1pt border, e.g. "1-3 앱 소개"'s "연결하기" button
    /// (`eventAccentLight` border around an `eventAccent` fill). `nil` (the
    /// default) keeps every existing call site borderless.
    var borderColor: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(font)
                .foregroundStyle(isEnabled ? Color.white : Color.gray400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background {
                    RoundedRectangle(cornerRadius: isEnabled ? Radius.chipDefault : Radius.chipSelected)
                        .fill(isEnabled ? tint : Color.surface)
                }
                .overlay {
                    if isEnabled, let borderColor {
                        RoundedRectangle(cornerRadius: Radius.chipDefault)
                            .strokeBorder(borderColor)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        PrimaryActionButton(titleKey: "신고 제출하기", isEnabled: false) {}
        PrimaryActionButton(titleKey: "신고 제출하기", isEnabled: true) {}
    }
    .padding()
}
