//
//  TabBarVisibility.swift
//  Cync
//
//  Decides when `RootTabView`'s custom bottom tab bar is on screen.
//  `RootTabView` doesn't use a real `TabView` (see its header comment), so
//  SwiftUI's native `.toolbar(_:for: .tabBar)` has nothing to attach to.
//
//  Rule: the tab bar shows ONLY while one of the five main tab screens
//  (공지사항 / 캘린더 / 사물함 / 커뮤니티 / 설정) is itself on screen. Each of
//  those marks its root with `.showsTabBar()`; anything pushed on top of it
//  (detail, settings sub-pages, compose, apply…) makes the root disappear,
//  so the bar hides on its own — new screens need nothing.
//
//  It used to be the other way around (each pushed screen hid the bar in
//  onAppear and re-showed it in onDisappear), which was easy to forget on a
//  new screen and raced on push/pop: the outgoing screen's onDisappear
//  could land after the incoming one's onAppear and bring the bar back.
//
//  A count, not a Bool, so a tab switch (old root disappearing, new one
//  appearing) ends up shown no matter which callback runs first.
//

import SwiftUI

@MainActor
final class TabBarVisibility: ObservableObject {
    @Published private(set) var isHidden = true
    /// A popup is up on a main tab screen: the bar gets the same dim as
    /// the popup's backdrop (which can't reach it — the bar sits outside
    /// the screen's view) and stops taking taps.
    @Published private(set) var isDimmed = false

    private var dimCount = 0 {
        didSet {
            let dimmed = dimCount > 0
            if dimmed != isDimmed { isDimmed = dimmed }
        }
    }

    fileprivate func dimStarted() { dimCount += 1 }
    fileprivate func dimEnded() { dimCount = max(0, dimCount - 1) }

    private var visibleRootCount = 0 {
        didSet {
            let hidden = visibleRootCount == 0
            if hidden != isHidden { isHidden = hidden }
        }
    }

    fileprivate func rootAppeared() { visibleRootCount += 1 }
    fileprivate func rootDisappeared() { visibleRootCount = max(0, visibleRootCount - 1) }
}

private struct ShowsTabBarModifier: ViewModifier {
    let isActive: Bool
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @State private var isShowing = false

    func body(content: Content) -> some View {
        content
            .onAppear { setShowing(isActive) }
            .onChange(of: isActive) { _, active in setShowing(active) }
            .onDisappear { setShowing(false) }
    }

    private func setShowing(_ showing: Bool) {
        guard showing != isShowing else { return }
        isShowing = showing
        if showing {
            tabBarVisibility.rootAppeared()
        } else {
            tabBarVisibility.rootDisappeared()
        }
    }
}

private struct DimsTabBarModifier: ViewModifier {
    let isActive: Bool
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @State private var isDimming = false

    func body(content: Content) -> some View {
        content
            .onAppear { setDimming(isActive) }
            .onChange(of: isActive) { _, active in setDimming(active) }
            .onDisappear { setDimming(false) }
    }

    private func setDimming(_ dimming: Bool) {
        guard dimming != isDimming else { return }
        isDimming = dimming
        if dimming {
            tabBarVisibility.dimStarted()
        } else {
            tabBarVisibility.dimEnded()
        }
    }
}

extension View {
    /// Dims the bottom tab bar while `isActive` — for a main tab screen's
    /// popups, whose 0.6 black backdrop otherwise stops at the tab bar.
    func dimsTabBar(_ isActive: Bool) -> some View {
        modifier(DimsTabBarModifier(isActive: isActive))
    }

    /// Marks a main tab screen's root (inside its `NavigationStack`): the
    /// bottom tab bar shows while this view is on screen and `isActive` is
    /// true. Pass `false` while something covers the root without pushing,
    /// e.g. 공지사항's in-place detail overlay.
    func showsTabBar(_ isActive: Bool = true) -> some View {
        modifier(ShowsTabBarModifier(isActive: isActive))
    }
}
