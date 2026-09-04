//
//  NoticeCategoryBadge.swift
//  test
//
//  Figma node `I44:269;184:1577` ("button") — the small pink tag in front of
//  each notice title. Figma's instance content literally reads "카테고리"
//  (a placeholder), so the real category name from the model is rendered
//  here instead.
//

import SwiftUI

struct NoticeCategoryBadge: View {
    let category: NoticeCategory

    var body: some View {
        Text(category.localizedKey)
            .font(.categoryBadge)
            .foregroundStyle(Color.textPrimary)
            .padding(Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: Radius.chipDefault)
                    .fill(Color.categoryBadgeBackground)
            }
    }
}

#Preview {
    HStack {
        NoticeCategoryBadge(category: .academic)
        NoticeCategoryBadge(category: .exchange)
    }
    .padding()
}
