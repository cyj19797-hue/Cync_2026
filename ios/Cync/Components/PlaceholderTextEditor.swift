//
//  PlaceholderTextEditor.swift
//  test
//
//  Figma node `228:1719` ("content") — the multi-line post body field with
//  placeholder "내용을 자유롭게 입력하세요.".
//
//  WHY this needs a small wrapper (still no UIKit): SwiftUI's `TextEditor`
//  has no placeholder parameter at all, unlike `TextField`. The standard
//  fix — and the one used here — is a `Text` placeholder laid under the
//  editor in a `ZStack`, shown only while `text.isEmpty`. `UITextView`
//  (the UIKit editor) has the exact same missing-placeholder gap, so
//  wrapping it via `UIViewRepresentable` would need this same overlay
//  trick anyway, plus delegate boilerplate — not a case where UIKit buys
//  anything.
//
//  The small top/leading padding below compensates for `TextEditor`'s own
//  built-in text-container insets, which don't match a plain `Text`'s
//  default position — without it the placeholder sits visibly offset from
//  where typed text actually starts.
//

import SwiftUI

struct PlaceholderTextEditor: View {
    @Binding var text: String
    let placeholder: LocalizedStringKey
    var font: Font = .body
    var placeholderColor: Color = .gray400
    var textColor: Color = .textPrimary

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(placeholderColor)
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(font)
                .foregroundStyle(textColor)
                .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var text = ""
        var body: some View {
            PlaceholderTextEditor(text: $text, placeholder: "내용을 자유롭게 입력하세요.")
                .padding()
        }
    }
    return PreviewHost()
}
