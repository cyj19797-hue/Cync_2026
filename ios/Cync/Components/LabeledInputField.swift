//
//  LabeledInputField.swift
//  Cync
//
//  Figma nodes `219:2611`/`219:2616` ("학번입력"/"비밀번호 입력") — the bordered
//  input box shared by both fields on "1-5 로그인". Factored out as its own
//  component since a labeled bordered text field is likely to recur on any
//  future form screen, not just this one.
//
//  Beyond Figma: the border turns `accentStrong` (and slightly thicker)
//  while the field is being edited, and secure fields get an eye button
//  to show/hide what was typed. `textContentType` hooks the field up to
//  iOS password AutoFill (`.username` / `.password`); fields with one, and
//  secure fields, skip autocorrect/auto-capitalization.
//

import SwiftUI

struct LabeledInputField: View {
    let placeholder: LocalizedStringResource
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}

    /// Which of the two underlying fields has focus — a secure field swaps
    /// between `SecureField` and `TextField` when revealed, and focus is
    /// carried over so the keyboard doesn't drop.
    private enum Field { case secure, plain }
    @FocusState private var focusedField: Field?
    @State private var isRevealed = false

    private var isFocused: Bool { focusedField != nil }

    /// No autocorrect/caps for credentials — they'd "fix" ids and passwords.
    private var isCredential: Bool { isSecure || textContentType != nil }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Group {
                if isSecure && !isRevealed {
                    SecureField(String(appLocalized: placeholder), text: $text)
                        .focused($focusedField, equals: .secure)
                } else {
                    TextField(String(appLocalized: placeholder), text: $text)
                        .keyboardType(keyboardType)
                        .focused($focusedField, equals: .plain)
                }
            }
            .textContentType(textContentType)
            .autocorrectionDisabled(isCredential)
            .textInputAutocapitalization(isCredential ? .never : nil)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)

            if isSecure {
                revealButton
            }
        }
        .font(.loginFieldValue).tracking(Tracking.loginFieldValue)
        .foregroundStyle(Color.textPrimary)
        .padding(Spacing.xs)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.inputField)
                .strokeBorder(isFocused ? Color.accentStrong : Color.borderLight, lineWidth: isFocused ? 1.5 : 1)
        }
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    private var revealButton: some View {
        Button {
            let wasFocused = isFocused
            isRevealed.toggle()
            if wasFocused {
                focusedField = isRevealed ? .plain : .secure
            }
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .foregroundStyle(Color.textSecondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .minimumHitTarget(inset: 10)
        .accessibilityLabel(Text(isRevealed ? .loginHidePassword : .loginShowPassword))
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
