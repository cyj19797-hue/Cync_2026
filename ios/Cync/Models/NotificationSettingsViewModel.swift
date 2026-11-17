//
//  NotificationSettingsViewModel.swift
//  test
//
//  State for NotificationSettingsView and its two sub-screens (they share
//  one instance).
//
//  - Each switch saves at once. If saving fails, the switch goes back to
//    what it was and a toast says "저장하지 못했어요. 다시 시도해 주세요.".
//  - The iOS notification permission is read on open and whenever the app
//    comes back to the foreground. Until it's allowed, every switch is
//    disabled and the screens show a banner: "알림 켜기" asks for it the
//    first time, "설정 열기" goes to the app's iOS settings once it was
//    turned down.
//  - With "전체 알림" off, everything under it is disabled.
//

import Combine
import SwiftUI
import UserNotifications

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    enum PermissionState {
        /// Not read yet — nothing is shown or disabled meanwhile.
        case unknown
        case notDetermined
        case denied
        case allowed
    }

    @Published private(set) var preferences: NotificationPreferences
    @Published private(set) var permission: PermissionState = .unknown
    @Published var toastMessage: String?

    private let store: NotificationPreferencesStore

    init(store: NotificationPreferencesStore = LocalNotificationPreferencesStore()) {
        self.store = store
        self.preferences = store.load()
    }

    // MARK: - Enabled state

    private var isPermissionMissing: Bool {
        permission == .notDetermined || permission == .denied
    }

    /// "전체 알림" itself.
    var canEditAll: Bool { !isPermissionMissing }

    /// Everything under "전체 알림".
    var canEditItems: Bool { canEditAll && preferences.allEnabled }

    // MARK: - Switches

    func binding(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { self.preferences[keyPath: keyPath] },
            set: { value in self.update { $0[keyPath: keyPath] = value } }
        )
    }

    func binding(for category: NoticeCategory) -> Binding<Bool> {
        Binding(
            get: { self.preferences.noticeCategories.contains(category) },
            set: { isOn in
                self.update {
                    if isOn {
                        $0.noticeCategories.insert(category)
                    } else {
                        $0.noticeCategories.remove(category)
                    }
                }
            }
        )
    }

    /// Applies the change right away, then saves it; on failure puts the
    /// old value back (unless something newer replaced it) and says so.
    private func update(_ change: (inout NotificationPreferences) -> Void) {
        let previous = preferences
        var updated = previous
        change(&updated)
        preferences = updated
        Task {
            do {
                try await store.save(updated)
            } catch {
                if preferences == updated { preferences = previous }
                toastMessage = String(appLocalized: .notifSaveFailed)
            }
        }
    }

    // MARK: - Row values

    /// "새 공지 알림" value: 전체 / n개 / 끔.
    var noticeSummary: String {
        Self.summary(
            on: preferences.noticeCategories.count,
            of: NotificationPreferences.noticeCategoryOptions.count
        )
    }

    /// "사물함 신청 결과 알림" value: 전체 / n개 / 끔.
    var lockerSummary: String {
        Self.summary(on: [preferences.lockerApproved, preferences.lockerRejected].filter { $0 }.count, of: 2)
    }

    private static func summary(on: Int, of total: Int) -> String {
        if on == 0 { return String(appLocalized: .notifValueOff) }
        if on == total { return String(appLocalized: .notifValueAll) }
        return String(appLocalized: .notifValueCount(on))
    }

    // MARK: - iOS permission

    func refreshPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: permission = .notDetermined
        case .denied: permission = .denied
        default: permission = .allowed
        }
    }

    /// Shows the iOS permission prompt (first time only — after that iOS
    /// answers without asking, so the banner offers 설정 열기 instead).
    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        await refreshPermission()
    }

    /// This app's page in iOS 설정 > 알림.
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
