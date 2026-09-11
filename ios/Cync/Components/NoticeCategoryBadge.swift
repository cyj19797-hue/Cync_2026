//
//  NoticeCategoryBadge.swift
//  test
//
//  Figma node `I44:269;184:1577` ("button") — the small pink tag in front of
//  each notice title. Figma's instance content literally reads "카테고리"
//  (a placeholder), so the real category name from the model is rendered
//  here instead.
//
//  Own component, own padding constants — distinct from `FilterChip`'s
//  (`badgeHorizontalPadding`/`badgeVerticalPadding` here vs
//  `chipHorizontalPadding`/`chipVerticalPadding` there) even though both
//  currently resolve to the same `Spacing.xs` value, so the two can diverge
//  independently later without one accidentally dragging the other along.
//

import SwiftUI

struct NoticeCategoryBadge: View {
    private static let badgeHorizontalPadding: CGFloat = Spacing.xs
    private static let badgeVerticalPadding: CGFloat = Spacing.xs

    let category: NoticeCategory

    var body: some View {
        Text(category.localizedKey)
            .font(.categoryBadge).tracking(Tracking.categoryBadge)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Self.badgeHorizontalPadding)
            .padding(.vertical, Self.badgeVerticalPadding)
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
