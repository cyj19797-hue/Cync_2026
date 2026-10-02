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
//  `style` picks one of two `CheckboxStyle` color variants: `.standard`
//  (the default — gray fill + dark check, e.g. "익명") or `.accent`
//  (blue fill + white check, e.g. "1-5 로그인"'s "학번 기억하기" and
//  "1-4 이용약관 동의"'s "전체 동의"). Unchecked looks the same either way.
//
//  The square itself is `CheckboxSquare` — pulled out so "1-4 이용약관 동의"'s
//  `AgreementItemRow` (checkbox + label + a separate trailing chevron tap
//  target) can draw the identical square without needing this component's
//  single "checkbox+label is one button" shape.
//
//  `font` defaults to the original `.categoryBadge` so the "익명" checkbox
//  (and "1-5 로그인"'s "학번 기억하기", which doesn't override it either) are
//  unaffected; "1-4 이용약관 동의"'s "전체 동의" passes `.termsAgreeAllLabel`
//  instead, since an external `.font()` modifier can't reach past this
//  view's own `Text` once it sets a font explicitly. `tracking` mirrors
//  `font` the same way — a call site overriding `font:` must also override
//  `tracking:` to the matching `Tracking.*` value.
//

import SwiftUI

struct CheckboxToggle: View {
    @Binding var isChecked: Bool
    let titleKey: LocalizedStringResource
    var style: CheckboxStyle = .standard
    var font: Font = .categoryBadge
    var tracking: CGFloat = Tracking.categoryBadge
    /// Gap between the square and its label — "1-5 로그인" passes a tighter one.
    var spacing: CGFloat = Spacing.md

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: spacing) {
                CheckboxSquare(isChecked: isChecked, style: style)

                Text(titleKey)
                    .font(font)
                    .tracking(tracking)
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
