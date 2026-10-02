//
//  SettingsView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `47:872` ("6 - 설정"), nav-title "마이페이지".
//  Profile card (`47:1067`, now `ProfileSummaryCard`) + "설정" section (5
//  rows) + "계정" section (2 rows), all built from the shared `SettingsRow`.
//  "알림 설정" pushes "6-1 알림 설정" (`NotificationSettingsView`); "Cync 공지"
//  pushes "6-2 Cync 공지" (`CyncNoticeListView`), which in turn pushes
//  "6-2-1 공지사항 내용" (`CyncNoticeDetailView`) when a row is tapped. Those
//  pushed screens have no bottom tab bar — see TabBarVisibility.swift.
//  The bottom tab bar (`47:1086`) is not built here — it's RootTabView's
//  `TabView`, this is just its "설정" tab content.
//
//  No UIKit here — the top bar reuses Components/AppTopBar.swift (shared
//  with NoticeListView/CommunityView/LockerView) and search reuses the
//  existing Components/SearchBar.swift (pure SwiftUI); "언어 설정" opens
//  `LanguagePickerDialog`, a custom popup (기기 설정 따르기 / 한국어 / English)
//  that switches the app language in place — see AppLanguage.swift. The
//  logout/withdraw confirmations use native `.confirmationDialog`, and
//  the nickname editor uses a native `.alert` with a `TextField` (supported
//  directly by SwiftUI since iOS 16) instead of a hand-built prompt.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var isSearchPresented = false
    @State private var isEditingProfile = false
    @State private var isLogoutConfirmPresented = false
    @State private var isWithdrawConfirmPresented = false
    @State private var isNotificationSettingsPresented = false
    @State private var isCyncNoticePresented = false
    @State private var isLanguagePickerPresented = false
    @ObservedObject private var languageSettings = LanguageSettings.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar(title: .settingsTitle, trailing: {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textPrimary)
                    }
                    .accessibilityLabel(Text(.commonSearch))
                })

                if isSearchPresented {
                    // TODO: 설정 항목이 적어 실제 필터링은 아직 구현하지 않음 — 검색 UI만 제공
                    SearchBar(text: $viewModel.searchText, isActive: $isSearchPresented)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.top, Spacing.xs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                List {
                    Section {
                        ProfileSummaryCard(
                            nickname: viewModel.profile?.nickname ?? "",
                            profileColor: viewModel.profile?.profileColor
                        ) {
                            isEditingProfile = true
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, Spacing.xs)
                    }

                    Section {
                        SettingsRow(
                            systemImage: "globe",
                            titleKey: .settingsLanguage,
                            value: LanguagePickerDialog.name(of: languageSettings.language)
                        ) {
                            isLanguagePickerPresented = true
                        }
                        SettingsRow(systemImage: "bell", titleKey: .settingsNotifications) {
                            isNotificationSettingsPresented = true
                        }
                        SettingsRow(systemImage: "number", titleKey: .settingsCyncNotice) {
                            isCyncNoticePresented = true
                        }
                        SettingsRow(systemImage: "questionmark.circle", titleKey: .settingsInquiry) {
                            openInquiryChat()
                        }
                        SettingsInfoRow(systemImage: "info.circle", titleKey: .settingsAppInfo, value: appVersionText)
                    } header: {
                        Text(.tabSettings)
                            .font(.noticeTitle).tracking(Tracking.noticeTitle)
                            .foregroundStyle(Color.textPrimary)
                    }

                    Section {
                        SettingsRow(systemImage: "rectangle.portrait.and.arrow.right", titleKey: .settingsLogout) {
                            isLogoutConfirmPresented = true
                        }
                        SettingsRow(systemImage: "person.crop.circle.badge.xmark", titleKey: .settingsWithdraw) {
                            isWithdrawConfirmPresented = true
                        }
                    } header: {
                        Text(.settingsAccount)
                            .font(.noticeTitle).tracking(Tracking.noticeTitle)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .listStyle(.plain)
            }
            .navigationDestination(isPresented: $isNotificationSettingsPresented) {
                NotificationSettingsView()
            }
            .navigationDestination(isPresented: $isCyncNoticePresented) {
                CyncNoticeListView()
            }
            .background(Color.appBackground)
            .animation(.default, value: isSearchPresented)
            .toolbar(.hidden, for: .navigationBar)
            // Main tab screen — the bottom tab bar shows only while this
            // root is on screen (see TabBarVisibility.swift).
            .showsTabBar()
            .task {
                await viewModel.loadProfile()
            }
            .sheet(isPresented: $isEditingProfile) {
                ProfileEditSheet(
                    currentNickname: viewModel.profile?.nickname ?? "",
                    currentColor: viewModel.profile?.profileColor ?? .blue
                ) { nickname, color in
                    Task { await viewModel.updateProfile(nickname: nickname, color: color) }
                }
            }
            .alert(
                Text(.commonError),
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
                )
            ) {
                Button(.commonOk, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .confirmationDialog(Text(.settingsLogoutConfirm), isPresented: $isLogoutConfirmPresented, titleVisibility: .visible) {
                Button(.settingsLogout, role: .destructive) {
                    sessionStore.logOut()
                }
            }
            .confirmationDialog(Text(.settingsWithdrawConfirm), isPresented: $isWithdrawConfirmPresented, titleVisibility: .visible) {
                Button(.settingsWithdraw, role: .destructive) {
                    // TODO: 실제 회원 탈퇴 API 연동 필요
                }
            }
        }
        .overlay { languagePickerOverlay }
        .animation(.easeOut(duration: 0.2), value: isLanguagePickerPresented)
    }

    @ViewBuilder
    private var languagePickerOverlay: some View {
        if isLanguagePickerPresented {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { isLanguagePickerPresented = false }

                LanguagePickerDialog(
                    selected: languageSettings.language,
                    onSelect: { language in
                        isLanguagePickerPresented = false
                        languageSettings.select(language)
                    },
                    onCancel: { isLanguagePickerPresented = false }
                )
                .padding(.horizontal, Spacing.md)
            }
            .transition(.opacity)
        }
    }

    /// "프로그램 정보" value, e.g. "1.0.0v" — the app's version
    /// (`MARKETING_VERSION` in the Xcode project, read from the bundle).
    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return String(appLocalized: .settingsAppVersion(version))
    }

    /// "오류 및 문의" — opens the team's KakaoTalk open-chat link. A plain
    /// `UIApplication.shared.open(_:)` on the `https://open.kakao.com/...`
    /// universal link is enough for both cases the row needs: iOS routes it
    /// straight into the KakaoTalk app when installed (Kakao registers that
    /// domain as an associated/universal link), and falls back to opening it
    /// in Safari when the app isn't installed — no separate custom-scheme
    /// check needed.
    private func openInquiryChat() {
        guard let url = URL(string: "https://open.kakao.com/o/shz9nZMi") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SessionStore())
        .environmentObject(TabBarVisibility())
}
