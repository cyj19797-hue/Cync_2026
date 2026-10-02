//
//  AppTopBar.swift
//  Cync
//
//  Shared top bar for the five main tabs (공지사항 / 캘린더 / 사물함 /
//  커뮤니티 / 설정): tab icon + bold title on the left, icon buttons on the
//  right.
//
//  The bar fixes the geometry so every tab lines up exactly, whatever
//  symbols it uses: the leading icon is drawn at the title's size in a
//  fixed square (so the title always starts at the same x — SF Symbols
//  differ in width), the bar is at least 44pt tall, and trailing actions
//  are `TopBarIconButton`s (44×44pt each, icons at the same size as the
//  leading one), with the bar's trailing padding trimmed so the last
//  icon's edge lines up with the screen's 16pt margin.
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
//    - `title: LocalizedStringResource` — the common case (plain nav-title styling).
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

    /// Square the leading tab icon is fitted into.
    @ScaledMetric(relativeTo: .headline) private var leadingIconBox: CGFloat = 28

    var body: some View {
        HStack(spacing: Spacing.xs) {
            leading
                .font(.noticeNavTitle)
                .fontWeight(.regular)
                .frame(width: leadingIconBox, height: leadingIconBox)
            titleContent
            Spacer(minLength: Spacing.xs)
            HStack(spacing: 0) {
                trailing
            }
        }
        .foregroundStyle(Color.textPrimary)
        .frame(minHeight: TopBarIconButton.size)
        .padding(.leading, Spacing.md)
        // A 44pt button centers its ~20pt icon, leaving ~12pt on its right;
        // trimming that much keeps the icon itself 16pt from the edge.
        .padding(.trailing, Spacing.md - 12)
        // Exactly 44pt tall, the same as `ScreenNavigationBar`, so a tab
        // screen and the screens pushed from it start their content at the
        // same height.
        .background(Color.appBackground)
    }
}

/// An icon action in `AppTopBar`'s trailing slot — 44×44pt to tap, with
/// the icon at the bar's title size (Regular), so every tab's actions look
/// and sit the same.
struct TopBarIconButton: View {
    static let size: CGFloat = 44

    let systemImage: String
    let labelKey: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.noticeNavTitle)
                .fontWeight(.regular)
                .foregroundStyle(Color.textPrimary)
                .frame(width: Self.size, height: Self.size)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(labelKey))
    }
}

extension AppTopBar where TitleContent == Text {
    /// Convenience for the common case: a plain string title styled with
    /// the design system's standard nav-title font/color.
    init(
        title: LocalizedStringResource,
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
            Image(systemName: "megaphone")
        } trailing: {
            TopBarIconButton(systemImage: "magnifyingglass", labelKey: "검색") {}
        }

        AppTopBar(title: "설정") {
            Image(systemName: "gearshape")
        }
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
