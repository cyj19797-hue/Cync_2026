//
//  NotificationSettingsViewModel.swift
//  test
//
//  Mock-data-backed state for NotificationSettingsView. `preferences`
//  stands in for future `GET`/`PATCH /api/me/notification-preferences`
//  calls to the Spring Boot backend.
//

import Combine
import Foundation

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    @Published var preferences: NotificationPreferences

    init(preferences: NotificationPreferences = .mock) {
        self.preferences = preferences
    }
}
