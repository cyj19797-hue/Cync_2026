//
//  LanguagePickerDialog.swift
//  Cync
//
//  설정 > "언어 설정" popup: 기기 설정 따르기 / 한국어 / English. Picking one
//  applies it immediately (see AppLanguage.swift) and closes the popup.
//  Same `DialogCard` chrome and radio rows as `CommentReportDialog`.
//
//  The two language names are written in their own language ("한국어",
//  "English") whatever the current UI language is, so someone who
//  switched by mistake can still find their way back — that's why they're
//  `verbatim` rather than localized.
//

import SwiftUI

struct LanguagePickerDialog: View {
    let selected: AppLanguage
    let onSelect: (AppLanguage) -> Void
    let onCancel: () -> Void

    var body: some View {
        DialogCard {
            Text(.settingsLanguage)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(AppLanguage.allCases) { language in
                    row(language)
                }
            }
            .padding(.bottom, Spacing.xs)

            HStack(spacing: Spacing.cardInset) {
                DialogActionButton(titleKey: .commonCancel, action: onCancel)
            }
        }
    }

    private func row(_ language: AppLanguage) -> some View {
        let isSelected = language == selected
        return Button {
            onSelect(language)
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.eventAccent : Color.gray400)
                Text(verbatim: Self.name(of: language))
                    .font(.dialogBody).tracking(Tracking.dialogBody)
                    .foregroundStyle(Color.textPrimary)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Option label — also used for the settings row's trailing value.
    static func name(of language: AppLanguage) -> String {
        switch language {
        case .system: return String(appLocalized: .settingsLanguageSystem)
        case .korean: return "한국어"
        case .english: return "English"
        }
    }
}

#Preview {
    LanguagePickerDialog(selected: .system, onSelect: { _ in }, onCancel: {})
        .padding()
}
