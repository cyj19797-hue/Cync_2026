//
//  SettingsInfoRow.swift
//  Cync
//
//  A settings row that only shows a value — same icon/title/value layout
//  as `SettingsRow` (via `SettingsRowContent`) but not a button and with
//  no chevron, so it doesn't look tappable. Used for "프로그램 정보", which
//  shows the app version ("v1.0.0") right in the row.
//

import SwiftUI

struct SettingsInfoRow: View {
    let systemImage: String
    let titleKey: LocalizedStringResource
    let value: String

    var body: some View {
        SettingsRowContent(systemImage: systemImage, titleKey: titleKey, value: value, showsChevron: false)
            // Read as one element: "프로그램 정보, 1.0.0v".
            .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        SettingsInfoRow(systemImage: "info.circle", titleKey: "프로그램 정보", value: "v1.0.0")
    }
}
