//
//  ListSectionHeader.swift
//  Cync
//
//  Section title in the plain settings-style lists (설정, 알림 설정): Bold
//  16 with a bigger gap above (separating it from the previous group) than
//  below, so the title reads as part of the rows it heads.
//
//  Pair it with `.compactListSections()` on the `List`, which drops the
//  List's own header height, section spacing and top content margin —
//  otherwise the first title started ~16pt lower than every other screen's
//  first element. The first section passes
//  `topPadding: Spacing.screenContentTop` so it starts the same distance
//  under the top bar as any screen's content.
//

import SwiftUI

struct ListSectionHeader: View {
    let titleKey: LocalizedStringResource
    var topPadding: CGFloat = Spacing.md
    var font: Font = .noticeTitle
    var tracking: CGFloat = Tracking.noticeTitle
    var bottomPadding: CGFloat = Spacing.xxs

    var body: some View {
        Text(titleKey)
            .font(font).tracking(tracking)
            .foregroundStyle(Color.textPrimary)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenHorizontal, bottom: 0, trailing: Spacing.screenHorizontal))
            .background(Color.appBackground)
    }
}

extension View {
    /// For a plain `List` using `ListSectionHeader`s — see that file.
    /// Divider rule for a row in a sectioned `List`: it spans the row's
    /// content width (16pt in from each screen edge, the same as section
    /// titles and cards — not indented to the label after an icon), and the
    /// last row of a section gets none, so sections are separated by their
    /// titles alone.
    func listRowDivider(isLast: Bool = false) -> some View {
        alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
            .listRowSeparator(.hidden, edges: .top)
            .listRowSeparator(isLast ? .hidden : .visible, edges: .bottom)
    }

    func compactListSections() -> some View {
        environment(\.defaultMinListHeaderHeight, 0)
            .listSectionSpacing(0)
            .contentMargins(.top, 0, for: .scrollContent)
    }
}
