//
//  RootTabView.swift
//  test
//
//  Figma node `30:577` ("tab bar") — 5 destinations: 공지사항 / 캘린더 / 사물함 /
//  커뮤니티 / 설정.
//
//  All 5 tabs are now fully built.
//
//  Hand-rolled bottom bar, not `TabView`/`.tabItem`: as of iOS 26, the
//  system tab bar renders with the new translucent "Liquid Glass" material
//  and there is no supported way — SwiftUI or UIKit — to opt a specific
//  bar out of it. Both were tried and verified against a contrasting-color
//  test screen (a solid-red tab placed behind the bar, which showed
//  through as pink in both cases):
//    - SwiftUI: `.toolbarBackground(Color, for: .tabBar)` +
//      `.toolbarBackground(.visible, for: .tabBar)` only tints the glass,
//      it doesn't replace it.
//    - UIKit: `UITabBarAppearance().configureWithOpaqueBackground()` +
//      `UITabBar.appearance().standardAppearance/scrollEdgeAppearance` has
//      the exact same result on this floating bar.
//  Apple's own DTS engineers have also confirmed, separately, that
//  customizing an *unselected* tab item's color is intentionally disabled
//  on iOS 26 (https://developer.apple.com/forums/thread/818449,
//  https://developer.apple.com/forums/thread/793700). With neither the
//  background nor the unselected color reachable through the system bar,
//  a plain SwiftUI bar of buttons is the only way left to get an opaque,
//  single-color background with distinct selected/unselected colors.
//

import SwiftUI

private enum RootTab: CaseIterable, Hashable {
    case notices, calendar, lockers, community, settings

    var title: String {
        switch self {
        case .notices: return "공지사항"
        case .calendar: return "캘린더"
        case .lockers: return "사물함"
        case .community: return "커뮤니티"
        case .settings: return "설정"
        }
    }

    var systemImage: String {
        switch self {
        case .notices: return "checkmark.square"
        case .calendar: return "calendar"
        case .lockers: return "shippingbox"
        case .community: return "face.smiling"
        case .settings: return "gearshape"
        }
    }
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .notices
    @StateObject private var tabBarVisibility = TabBarVisibility()

    var body: some View {
        VStack(spacing: 0) {
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(tabBarVisibility)

            if !tabBarVisibility.isHidden {
                tabBar
            }
        }
        .animation(.default, value: tabBarVisibility.isHidden)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .notices:
            NoticeListView()
        case .calendar:
            CalendarView()
        case .lockers:
            LockerView(viewModel: LockerViewModel())
        case .community:
            CommunityView()
        case .settings:
            SettingsView()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        // Left/right breathing room from the screen's curved corners — a
        // plain SwiftUI view already insets from any actual safe area
        // (notch/Dynamic Island cutouts, home-indicator bezel), but the
        // rounded corner radius itself isn't part of that safe area, so the
        // outermost tab icons (공지사항/설정) would otherwise sit flush
        // against it. A fixed design-token value (not measured against one
        // specific device) keeps every tab readable on any iPhone size.
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xxs)
        .overlay(alignment: .top) {
            Divider().overlay(Color.borderLight)
        }
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(_ tab: RootTab) -> some View {
        let isSelected = tab == selectedTab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 22))
                Text(tab.title)
                    .font(.tabItemLabel)
            }
            .foregroundStyle(isSelected ? Color.textPrimary : Color.gray400)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .environmentObject(SessionStore())
}
