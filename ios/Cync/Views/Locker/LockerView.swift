//
//  LockerView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `47:645` ("4 사물함"). The bottom tab bar
//  is RootTabView's; this is just the "사물함" tab content:
//
//  - Header: the shared `AppTopBar` (box icon + bold "사물함", like
//    공지사항/캘린더), with a "!" button on the right opening the
//    "사물함 신청 방법" guide (`LockerApplyGuideDialog`), which — for
//    students without a locker — also links to the existing apply screen
//    (`LockerApplicationMapView`, unchanged).
//  - "나의 사물함" card (`MyLockerCard`). "사물함 비밀번호 찾기" first asks
//    for the account password (`LockerPasswordVerifyDialog`) and only then
//    reveals the locker password.
//  - "전체 사물함": title, then the map card — legend on top, then (right-
//    aligned) a "B201 ⌄" button names the room the map is on (it follows
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
                    Button {
                        isGuidePresented = true
                    } label: {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(Color.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(.lockerGuideAccessibility))
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
                    .padding(Spacing.md)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(Color.appBackground)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isApplying) {
                applicationScreen
            }
            .task {
                await viewModel.load()
            }
            .overlay { popups }
            .overlayPreferenceValue(ZoneMenuAnchorKey.self) { anchor in
                zoneDropdown(anchor: anchor)
            }
            .animation(.easeOut(duration: 0.15), value: isZonePickerPresented)
            .alert(Text(.lockerPasswordAlertTitle), isPresented: $isPasswordAlertPresented) {
                Button(.commonOk, role: .cancel) {}
            } message: {
                Text(viewModel.myLocker?.password ?? String(localized: .lockerNoPassword))
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
            Text(.lockerAll)
                .font(.lockerSectionTitle).tracking(Tracking.lockerSectionTitle)
                .foregroundStyle(Color.textPrimary)

            // Map card: legend pinned to the very top, then the room
            // button, then the map — all on the card's `Spacing.sm` inner
            // edge (the map's rooms too, via `fitMargin`).
            // Legend → room button gets more air (`md`); the button sits
            // right-aligned just above the map it controls (`xxs`).
            VStack(alignment: .leading, spacing: 0) {
                LockerStatusLegend()
                    .padding(.bottom, Spacing.md)
                HStack {
                    Spacer(minLength: 0)
                    zoneButton
                }
                .padding(.bottom, Spacing.xxs)
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

    /// "B201 ⌄" at the top-right inside the map card — names the room the
    /// map is on (updates as the student scrolls it) and opens the room
    /// dropdown, so the control visibly belongs to the map.
    private var zoneButton: some View {
        Button {
            isZonePickerPresented.toggle()
        } label: {
            HStack(spacing: Spacing.xxs) {
                Text(verbatim: currentZoneId ?? LockerMapViewController.zoneIdsInOrder.first ?? "")
                    .font(.lockerZoneButton).tracking(Tracking.lockerZoneButton)
                    .foregroundStyle(Color.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.lockerZoneButton)
                    .foregroundStyle(Color.gray400)
            }
            .padding(.horizontal, Spacing.cardInset)
            .padding(.vertical, Spacing.xxs + 2)
            // Gray outline, same gray as the chevron.
            .overlay {
                Capsule().strokeBorder(Color.gray400)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(.lockerChooseZone))
        .anchorPreference(key: ZoneMenuAnchorKey.self, value: .bounds) { $0 }
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
            onControllerReady: { map.controller = $0 }
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

    /// Rooms in name order (B201, B202, B203(1), B203(2) …) for the
    /// dropdown — not the floor-plan order the map lays them out in.
    private static let sortedZoneIds = LockerMapViewController.zoneIdsInOrder.sorted {
        $0.localizedStandardCompare($1) == .orderedAscending
    }

    /// Small dropdown anchored under "전체 사물함 ⌄" (like a pull-down
    /// menu, but in the design system's style) — tapping outside closes
    /// it, tapping a room moves the map there.
    @ViewBuilder
    private func zoneDropdown(anchor: Anchor<CGRect>?) -> some View {
        if isZonePickerPresented, let anchor {
            GeometryReader { proxy in
                let rect = proxy[anchor]
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isZonePickerPresented = false }

                    // Right-aligned with the (right-aligned) room button.
                    zoneList
                        .frame(width: 160)
                        .offset(x: rect.maxX - 160, y: rect.maxY + Spacing.xxs)
                }
            }
            .transition(.opacity)
        }
    }

    private var zoneList: some View {
        let current = currentZoneId
        return ScrollView {
            VStack(spacing: 0) {
                ForEach(Self.sortedZoneIds, id: \.self) { zoneId in
                    Button {
                        isZonePickerPresented = false
                        selectedZoneId = zoneId
                        map.controller?.warp(to: zoneId)
                    } label: {
                        Text(verbatim: zoneId)
                            .font(.categoryFilterChipLabel).tracking(Tracking.categoryFilterChipLabel)
                            .foregroundStyle(zoneId == current ? Color.eventAccent : Color.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if zoneId != Self.sortedZoneIds.last {
                        Divider().overlay(Color.borderLight)
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: 40 * 6.5)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: Radius.scheduleCard))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.borderLight)
        }
        .shadow(color: Color.textPrimary.opacity(0.12), radius: 12, y: 4)
    }
}

/// Bounds of the "전체 사물함 ⌄" button, so the room dropdown can open
/// right beneath it from the screen-level overlay.
private struct ZoneMenuAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Weak handle on the embedded map's controller so the room picker can
/// call `warp(to:)` — same pattern as LockerApplicationMapView's coordinator.
private final class MapControllerHolder {
    weak var controller: LockerMapViewController?
}

#Preview {
    LockerView(viewModel: LockerViewModel())
}
