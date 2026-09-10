//
//  CyncNoticeRow.swift
//  Cync
//
//  Figma node `466:2711` ("공지사항") on "6-2 Cync 공지" — a title-only row,
//  unlike the school-notice `NoticeRow` (no category badge, date, bookmark,
//  or deadline on this board). The hairline divider under each row is not
//  redrawn as a custom asset — `List` already supplies a row separator (see
//  `NoticeRow`'s header comment for the same reasoning).
//

import SwiftUI

struct CyncNoticeRow: View {
    let notice: CyncNotice
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(notice.title)
                .font(.cyncNoticeRowTitle)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    List {
        ForEach(CyncNotice.mockList) { notice in
            CyncNoticeRow(notice: notice) {}
        }
    }
    .listStyle(.plain)
}
