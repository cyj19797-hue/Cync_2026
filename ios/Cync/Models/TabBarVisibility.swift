//
//  TabBarVisibility.swift
//  Cync
//
//  Lets a screen pushed inside one of `RootTabView`'s per-tab
//  `NavigationStack`s (e.g. `NotificationSettingsView`) hide the custom
//  bottom tab bar while it's on screen. `RootTabView` doesn't use a real
//  `TabView` (see its header comment), so SwiftUI's native
//  `.toolbar(_:for: .tabBar)` has nothing to attach to — a pushed screen
//  sets `isHidden` here instead, and `RootTabView` reads it to conditionally
//  render its hand-rolled `tabBar`.
//

import Foundation

@MainActor
final class TabBarVisibility: ObservableObject {
    @Published var isHidden = false
}
