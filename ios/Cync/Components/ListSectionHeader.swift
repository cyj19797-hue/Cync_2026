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

    var body: some View {
        Text(titleKey)
            .font(.noticeTitle).tracking(Tracking.noticeTitle)
            .foregroundStyle(Color.textPrimary)
            .padding(.top, topPadding)
            .padding(.bottom, Spacing.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenHorizontal, bottom: 0, trailing: Spacing.screenHorizontal))
            .background(Color.appBackground)
    }
}

extension View {
    /// For a plain `List` using `ListSectionHeader`s — see that file.
    func compactListSections() -> some View {
        environment(\.defaultMinListHeaderHeight, 0)
            .listSectionSpacing(0)
            .contentMargins(.top, 0, for: .scrollContent)
    }
}
