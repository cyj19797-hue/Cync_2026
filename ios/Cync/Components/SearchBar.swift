//
//  SearchBar.swift
//  Cync
//
//  Search field shown in place of CategoryFilterRow on "2 공지사항" when the
//  toolbar's magnifying-glass icon is tapped.
//
//  Previously a `UIViewRepresentable` wrapping `UISearchBar` — that used
//  the system search field's default chrome (system font, system gray
//  pill), which reads as a foreign, "off brand" element next to this app's
//  Pretendard/`Color.surface`/pill-chip styling everywhere else. Rebuilt
//  here as a plain SwiftUI view using the same fill/radius/font tokens as
//  `FilterChip` (the row this replaces), so it looks like it
//  belongs to the same design system rather than a native iOS control
//  dropped in. (The deployment target is also actually iOS 17.0 already —
//  see IPHONEOS_DEPLOYMENT_TARGET — so the iOS-16-compatibility reason this
//  file used to give for reaching for UIKit no longer applies either.)
//
//  Same `text`/`isActive` binding interface as before, so NoticeListView
//  didn't need to change at all.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var isActive: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.gray400)

                TextField("검색", text: $text)
                    .font(.categoryChip).tracking(Tracking.categoryChip)
                    .foregroundStyle(Color.textPrimary)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { isFocused = false }

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.gray400)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Radius.chipSelected)
                    .fill(Color.surface)
            }

            Button("취소") {
                text = ""
                isFocused = false
                isActive = false
            }
            .font(.categoryChip).tracking(Tracking.categoryChip)
            .foregroundStyle(Color.textPrimary)
            .buttonStyle(.plain)
        }
        .onAppear {
            isFocused = isActive
        }
        .onChange(of: isActive) { _, newValue in
            isFocused = newValue
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var text = ""
        @State private var isActive = true

        var body: some View {
            SearchBar(text: $text, isActive: $isActive)
                .padding(.horizontal)
        }
    }
    return PreviewHost()
}
