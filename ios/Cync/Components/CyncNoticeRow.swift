//
//  CyncNoticeRow.swift
//  Cync
//
//  Figma node `466:2711` ("공지사항") on "6-2 Cync 공지" — title row,
//  extended beyond Figma's title-only design with a date line under the
//  title, an unread dot to its left (read rows drop the dot and go from
//  SemiBold to Regular), and a pin icon on pinned notices. The hairline
//  divider under each row is not redrawn as a custom asset — `List` already
//  supplies a row separator (see `NoticeRow`'s header comment for the same
//  reasoning).
//
//  The dot column is always reserved (empty when read) so read and unread
//  titles stay aligned with each other.
//

import SwiftUI

struct CyncNoticeRow: View {
    let notice: CyncNotice
    var isRead: Bool = false
    let onSelect: () -> Void

    /// Unread dot's diameter, and the column it sits in.
    private static let dotSize: CGFloat = 8

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Circle()
                    .fill(isRead ? Color.clear : Color.eventAccent)
                    .frame(width: Self.dotSize, height: Self.dotSize)
                    // Centers the dot on the title's first line.
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + Self.dotSize / 2 }
                    .accessibilityLabel(Text(.cyncNoticeUnread))
                    .accessibilityHidden(isRead)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                        if notice.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.noticeDate)
                                .foregroundStyle(Color.eventAccentDark)
                                .accessibilityLabel(Text(.cyncNoticePinned))
                        }

                        Text(notice.title)
                            .font(isRead ? .cyncNoticeRowTitleRead : .cyncNoticeRowTitle)
                            .tracking(isRead ? Tracking.cyncNoticeRowTitleRead : Tracking.cyncNoticeRowTitle)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.leading)
                    }

                    Text(notice.dateText)
                        .font(.noticeDate).tracking(Tracking.noticeDate)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.xs)
        // Reads as "읽지 않음, 고정 공지, 제목, 날짜" — the dot and pin are
        // shapes/icons, so each carries its own label above.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        CyncNoticeRow(notice: .placeholder, isRead: false) {}
        CyncNoticeRow(notice: .placeholder, isRead: true) {}
    }
    .listStyle(.plain)
}
