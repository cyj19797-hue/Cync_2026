//
//  CategoryFilterRow.swift
//  test
//
//  Figma node `42:108` ("category") — the horizontally scrolling row of
//  category chips. It appears identically (same categories, same chip
//  style) on both "2 공지사항" (`42:108`) and "3 캘린더" (`240:1677`), so it's
//  factored out here and shared by NoticeListView and CalendarView instead
//  of being duplicated per screen.
//

import SwiftUI

struct CategoryFilterRow: View {
    @Binding var selectedCategory: NoticeCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(NoticeCategory.allCases) { category in
                    FilterChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var selectedCategory: NoticeCategory = .all
        var body: some View {
            CategoryFilterRow(selectedCategory: $selectedCategory)
        }
    }
    return PreviewHost()
}
