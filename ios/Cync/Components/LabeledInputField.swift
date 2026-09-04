//
//  LabeledInputField.swift
//  Cync
//
//  Figma nodes `219:2611`/`219:2616` ("학번입력"/"비밀번호 입력") — the bordered
//  input box shared by both fields on "1-5 로그인". Factored out as its own
//  component since a labeled bordered text field is likely to recur on any
//  future form screen, not just this one.
//

import SwiftUI

struct LabeledInputField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .font(.loginFieldValue)
        .foregroundStyle(Color.textPrimary)
        .padding(Spacing.xs)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.inputField)
                .strokeBorder(Color.borderLight)
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var text = ""
        var body: some View {
            VStack(spacing: Spacing.md) {
                LabeledInputField(placeholder: "학번을 입력해주세요", text: $text, keyboardType: .numberPad)
                LabeledInputField(placeholder: "비밀번호를 입력해주세요", text: $text, isSecure: true)
            }
            .padding()
        }
    }
    return PreviewHost()
}
