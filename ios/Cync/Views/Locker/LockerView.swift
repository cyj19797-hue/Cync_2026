//
//  LockerView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `47:645` ("4 사물함"). The bottom tab bar
//  is RootTabView's; this is just the "사물함" tab content:
//
//  - Header: the shared `AppTopBar` (box icon + bold "사물함", like
//    공지사항/캘린더), with an "i" (info) button on the right opening the
//    "사물함 신청 방법" guide (`LockerApplyGuideDialog`), which — for
//    students without a locker — also links to the existing apply screen
//    (`LockerApplicationMapView`, unchanged).
//  - "나의 사물함" card (`MyLockerCard`). "사물함 비밀번호 찾기" first asks
//    for the account password (`LockerPasswordVerifyDialog`) and only then
//    reveals the locker password.
//  - "전체 사물함": title row with, on its right, a "B201 ⌄" button that
//    names the room the map is on (it follows
//    manual scrolling too — the map reports its focused room and tints
//    that room's title) and opens a small dropdown of rooms beneath it
//    (name order: B201, B202, B203(1) …; tap outside to close); picking one
//    warps the map to it
//    (`LockerMapViewController.warp`, `.fitWithNeighbors` so the room and
//    the one under it both fit side to side, pinned to the top). The
//    MyLockerCard shows the room ("B201", small gray) before the number.
//    Below it, the color legend (`LockerStatusLegend`), then the original
//    embedded floor-plan map (`LockerMapScreenView`, same layout/zoom as
//    before) — its own bottom legend bar is turned off since the legend
//    now sits above it. The map is rebuilt once "내 사물함" is known so it
//    can highlight that cell.
//
//  Spacing: header → first card is `Spacing.md`, matching the other tabs'
//  header → filter-chip gap.
//

import SwiftUI

struct LockerView: View {
    @StateObject private var viewModel: LockerViewModel
    @State private var isPasswordAlertPresented = false
    @State private var isPasswordVerifyPresented = false
    @State private var isZonePickerPresented = false
    @State private var isApplying = false
    @State private var isGuidePresented = false
    @State private var map = MapControllerHolder()
    /// Room last picked in the dropdown.
    @State private var selectedZoneId: String?
    /// Room the map itself reports as focused (warp or manual scroll).
    @State private var mapFocusedZoneId: String?
    /// Whether the map has been moved off its first view — shows "◎".
    @State private var isMapDisplaced = false

    init(viewModel: LockerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar(title: .tabLockers) {
                    Image(systemName: "shippingbox")
                } trailing: {
                    // Always there (unlike the old "신청" button, which hid
                    // once a locker existed) — explains how applying works.
                    // "i", not "!" — this opens a how-to guide, and "!"
                    // reads as a warning or error.
                    TopBarIconButton(systemImage: "info.circle", labelKey: .lockerGuideAccessibility) {
                        isGuidePresented = true
                    }
                }

                // Two left edges run straight down the page: `Spacing.md`
                // (card borders, section title) and `Spacing.sm` further in
                // (everything inside a card, incl. the map's legend, room
                // button and rooms). Major blocks are `Spacing.sm`
                // apart; items within a block `Spacing.cardInset`.
                ScrollView {
                    VStack(spacing: Spacing.sm) {
                        myLockerCard

                        allLockersSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.screenContentTop)
                    .padding(.bottom, Spacing.md)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(Color.appBackground)
            }
            .toolbar(.hidden, for: .navigationBar)
            // Main tab screen — the bottom tab bar shows only while this
            // root is on screen (see TabBarVisibility.swift).
            .showsTabBar()
            .dimsTabBar(isGuidePresented || isPasswordVerifyPresented)
            .navigationDestination(isPresented: $isApplying) {
                applicationScreen
            }
            .task {
                await viewModel.load()
            }
            .overlay { popups }
            .lockerZoneDropdown(isPresented: $isZonePickerPresented, currentZoneId: currentZoneId) { zoneId in
                selectedZoneId = zoneId
                map.controller?.warp(to: zoneId)
            }
            .alert(Text(.lockerPasswordAlertTitle), isPresented: $isPasswordAlertPresented) {
                Button(.commonOk, role: .cancel) {}
            } message: {
                Text(viewModel.myLocker?.password ?? String(appLocalized: .lockerNoPassword))
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
        }
    }

    private var applicationScreen: some View {
        LockerApplicationMapView { locker in
            // 신청 완료: 서버가 배정한 실제 사물함(비밀번호 포함)을 "나의
            // 사물함"으로 승격.
            viewModel.myLocker = locker
        }
    }

    /// The "내 사물함" summary card (Figma component `243:4541`). While the
    /// student has no locker, the whole card also opens the apply screen
    /// (same as the header's "신청"). Once assigned, the card picks its
    /// variant (승인대기/베리언트4/기본) from `viewModel.myLocker`.
    @ViewBuilder
    private var myLockerCard: some View {
        if viewModel.myLocker == nil {
            NavigationLink {
                applicationScreen
            } label: {
                MyLockerCard(locker: nil)
            }
            .buttonStyle(.plain)
        } else {
            MyLockerCard(
                locker: viewModel.myLocker,
                zoneId: viewModel.myLocker.flatMap { viewModel.zoneId(forLockerNumber: $0.lockerNumber) }
            ) {
                isPasswordVerifyPresented = true
            } onRegisterPassword: {
                isPasswordAlertPresented = true
            }
        }
    }

    private var allLockersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.cardInset) {
            // Title row doubles as the map's control row: the room button
            // (and "◎" once the map has moved) sit right of the title, so
            // the card doesn't spend a whole line on them.
            HStack(spacing: Spacing.xs) {
                // Same style as MyLockerCard's "나의 사물함" title.
                Text(.lockerAll)
                    .font(.myLockerTitle).tracking(Tracking.myLockerTitle)
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)

                if isMapDisplaced {
                    LockerResetViewButton {
                        selectedZoneId = nil
                        map.controller?.resetView()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                LockerZoneButton(zoneId: currentZoneId, isPresented: $isZonePickerPresented)
            }
            .animation(.easeOut(duration: 0.2), value: isMapDisplaced)

            // Map card: legend pinned to the very top, then the map — both
            // on the card's `Spacing.sm` inner edge (the map's rooms too,
            // via `fitMargin`).
            VStack(alignment: .leading, spacing: 0) {
                LockerStatusLegend()
                    .padding(.bottom, Spacing.xs)
                lockerMap
                    .padding(.horizontal, -Spacing.sm)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.sm)
            .clipShape(RoundedRectangle(cornerRadius: Radius.scheduleCard))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .strokeBorder(Color.gray300)
            }
        }
    }

    /// Room the map is on — the one just picked, else wherever the map
    /// reports it's focused (starts on "내 사물함"'s room).
    private var currentZoneId: String? {
        selectedZoneId ?? mapFocusedZoneId
    }

    /// The original embedded floor-plan map — browse only (tapping a cell
    /// does nothing here; applying happens on the apply screen). `.id` on
    /// "내 사물함"'s number recreates it once that's loaded, since the
    /// controller only reads `focusLockerNumber` when it's created.
    private var lockerMap: some View {
        LockerMapScreenView(
            // No top/bottom inset: the canvas already has its own margin,
            // and the extra inset showed up as a blank band above B201.
            initialZoomFit: .fitHeight(padding: 0),
            showsLegend: false,
            focusLockerNumber: viewModel.myLocker?.lockerNumber,
            warpStyle: .fitWithNeighbors,
            onFocusedZoneChange: { zoneId in
                mapFocusedZoneId = zoneId
                // A manual scroll overrides the last dropdown pick.
                if zoneId != selectedZoneId { selectedZoneId = nil }
            },
            onDisplacedChange: { isMapDisplaced = $0 },
            onControllerReady: { controller in
                map.controller = controller
                // A rebuilt map starts on its first view again (deferred:
                // this runs while SwiftUI is building the view).
                DispatchQueue.main.async { isMapDisplaced = false }
            }
        )
        .id(viewModel.myLocker?.lockerNumber)
        // Two rows of rooms at the "내 사물함" warp's scale (~440pt) —
        // shorter than the original 520 so there's no empty band below.
        .frame(height: 460)
    }

    @ViewBuilder
    private var popups: some View {
        if isGuidePresented {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { isGuidePresented = false }
                LockerApplyGuideDialog(
                    onApply: viewModel.hasLoaded && viewModel.myLocker == nil
                        ? { isGuidePresented = false; isApplying = true }
                        : nil,
                    onClose: { isGuidePresented = false }
                )
                .padding(.horizontal, Spacing.md)
            }
        } else if isPasswordVerifyPresented {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                LockerPasswordVerifyDialog(
                    lockerPassword: viewModel.myLocker?.password,
                    verify: viewModel.verifyAccountPassword,
                    onClose: { isPasswordVerifyPresented = false }
                )
                .padding(.horizontal, Spacing.md)
            }
        }
    }
}

/// Weak handle on the embedded map's controller so the room picker can
/// call `warp(to:)` — same pattern as LockerApplicationMapView's coordinator.
private final class MapControllerHolder {
    weak var controller: LockerMapViewController?
}

#Preview {
    LockerView(viewModel: LockerViewModel())
        .environmentObject(TabBarVisibility())
}
