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

    var title: LocalizedStringResource {
        switch self {
        case .notices: return .tabNotices
        case .calendar: return .tabCalendar
        case .lockers: return .tabLockers
        case .community: return .tabCommunity
        case .settings: return .tabSettings
        }
    }

    var systemImage: String {
        switch self {
        case .notices: return "megaphone"
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
    @ObservedObject private var languageSettings = LanguageSettings.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            selectedContent
                // Rebuilt on a language change so strings a screen computed
                // once and kept in state (view models, loaded lists) come
                // back in the new language. The selected tab lives outside
                // this, so the user stays on the 설정 tab they changed it from.
                // Same for the system 글자 크기 setting: every font token is
                // scaled when it's read (see Typography.swift), so a rebuild
                // re-reads them all at the new size.
                .id(ContentIdentity(language: languageSettings.language, dynamicTypeSize: dynamicTypeSize))
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
                    .font(.tabItemLabel).tracking(Tracking.tabItemLabel)
            }
            // Unselected labels use `textSecondary` (~5:1 on the bar), not
            // `gray400` (~2.6:1), to clear the 4.5:1 text contrast minimum.
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// What `selectedContent` is rebuilt on — see the `.id` there.
private struct ContentIdentity: Hashable {
    let language: AppLanguage
    let dynamicTypeSize: DynamicTypeSize
}

#Preview {
    RootTabView()
        .environmentObject(SessionStore())
}
