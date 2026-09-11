//
//  AppTopBar.swift
//  Cync
//
//  Shared top bar for NoticeListView / CommunityView / LockerView. All
//  three built a near-identical `HStack { icon; Text(title) }` inside
//  `ToolbarItem(placement: .topBarLeading)`, only differing in the icon and
//  in what (if anything) sits in the trailing slot — see each screen's own
//  comment header for what moved where.
//
//  Deliberately NOT built on `.toolbar` / `ToolbarItem(placement: .topBarLeading/.topBarTrailing)`:
//  those placements hand layout over to the system navigation bar, which is
//  exactly the per-platform inconsistency this component exists to avoid.
//  `AppTopBar` is a plain view instead — callers place it as the first
//  child above their content and hide the real navigation bar with
//  `.toolbar(.hidden, for: .navigationBar)`, so this file is the only
//  thing controlling the bar's layout, height, and colors.
//
//  Two initializers cover the two ways a screen needs its title:
//    - `title: String` — the common case (plain nav-title styling).
//    - `title: () -> TitleContent` (`@ViewBuilder`) — for a screen that
//      needs to swap the whole title area for something else entirely
//      (e.g. a search field in place of the title). None of the 3 screens
//      wired up today actually need this yet (see NoticeListView's header
//      comment), but the shape is here so a future screen can drop it in
//      without a second top-bar component.
//  `leading`/`trailing` are both optional `@ViewBuilder` slots (default to
//  nothing) — Swift's multiple-trailing-closure syntax lets a caller write
//  `AppTopBar(title: "…") { leadingContent } trailing: { trailingContent }`
//  and freely omit either one.
//

import SwiftUI

struct AppTopBar<TitleContent: View, Leading: View, Trailing: View>: View {
    private let titleContent: TitleContent
    private let leading: Leading
    private let trailing: Trailing

    init(
        @ViewBuilder title: () -> TitleContent,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.titleContent = title()
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            leading
            titleContent
            Spacer(minLength: Spacing.xs)
            trailing
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.appBackground)
    }
}

extension AppTopBar where TitleContent == Text {
    /// Convenience for the common case: a plain string title styled with
    /// the design system's standard nav-title font/color.
    init(
        title: String,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.init(
            title: {
                Text(title)
                    .font(.noticeNavTitle).tracking(Tracking.noticeNavTitle)
            },
            leading: leading,
            trailing: trailing
        )
    }
}

#Preview("타이틀만") {
    AppTopBar(title: "공지사항")
}

#Preview("leading + trailing") {
    VStack(spacing: Spacing.md) {
        AppTopBar(title: "공지사항") {
            Image(systemName: "checkmark.square")
        } trailing: {
            Image(systemName: "magnifyingglass")
        }

        AppTopBar(title: "커뮤니티") {
            Image(systemName: "face.smiling")
        } trailing: {
            Image(systemName: "square.and.pencil")
        }

        AppTopBar(title: "사물함", trailing:  {
            Image(systemName: "shippingbox")
        })
    }
}

#Preview("커스텀 타이틀 슬롯") {
    AppTopBar {
        Text("검색 중…")
            .font(.noticeNavTitle).tracking(Tracking.noticeNavTitle)
            .foregroundStyle(Color.textSecondary)
    } trailing: {
        Image(systemName: "xmark")
    }
}
