//
//  TranslationToggle.swift
//  test
//
//  Figma node `271:1914` ("번역 탭") — "원문" / "AI 번역" pill toggle on the
//  "2-1 공지글" detail card. Visually close to `NoticeCategoryChip`, but it's
//  a 2-state binary switch (not an open set of filter categories), so it
//  gets its own small component rather than reusing the chip's API.
//

import SwiftUI

struct TranslationToggle: View {
    @Binding var isShowingTranslation: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            tab(titleKey: "원문", isSelected: !isShowingTranslation) {
                isShowingTranslation = false
            }
            tab(titleKey: "AI 번역", isSelected: isShowingTranslation) {
                isShowingTranslation = true
            }
        }
    }

    private func tab(titleKey: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titleKey)
                .font(.toggleTabLabel)
                .foregroundStyle(Color.textPrimary)
                .padding(Spacing.xs)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(isSelected ? Color.surface : Color.clear)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var isShowingTranslation = false
        var body: some View {
            TranslationToggle(isShowingTranslation: $isShowingTranslation)
                .padding()
        }
    }
    return PreviewHost()
}
