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
//  `TextEditor` insets its text by 5pt on each side (the text container's
//  line padding) and 8pt on top. The editor is pulled out by those 5pt so
//  typed text starts exactly at this view's leading edge — level with a
//  `TextField` above it given the same padding — and the placeholder sits
//  at that same spot (8pt down, no leading offset).
//

import SwiftUI

struct PlaceholderTextEditor: View {
    /// `TextEditor`'s own space above the first line — callers subtract it
    /// to get an exact gap to the text.
    static let textTopInset: CGFloat = 8

    @Binding var text: String
    let placeholder: LocalizedStringResource
    var font: Font = .body
    var placeholderColor: Color = .gray400
    var textColor: Color = .textPrimary

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font).tracking(Tracking.standard)
                    .foregroundStyle(placeholderColor)
                    .padding(.top, Self.textTopInset)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(font).tracking(Tracking.standard)
                .foregroundStyle(textColor)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, -5)
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
