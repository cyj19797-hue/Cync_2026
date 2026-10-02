//
//  LockerApplicationMapView.swift
//  Cync
//
//  The "사물함 신청" entry point's screen: `LockerMapScreenView` (physical
//  map, `.fitHeight` zoom + color legend) with tapping a `.empty` cell
//  wired into the same 신청 확인 → 계좌 안내 popup flow as
//  `LockerApplicationView`'s 6×6 mock grid (`lockerApplyDialogOverlay`,
//  shared so the two entry points can't drift apart on how applying
//  actually behaves).
//
//  `LockerMapViewController` itself only reports taps as
//  (lockerNumber, zoneId, status) via its delegate — matching that back to
//  a real `Locker` (for its server `id`) is this screen's job, done against
//  `LockerApplicationViewModel.lockers` (`GET /api/lockers/available`, so
//  every entry here is guaranteed already `.available`).
//
//  Same map controls as "4 사물함" (`LockerView`): the color legend
//  (`LockerStatusLegend`) sits above the map instead of the controller's
//  bottom bar, and the nav bar's trailing slot holds the shared
//  "B201 ⌄" room button + "◎" reset (`LockerZonePicker.swift`) in place of
//  the old system "이동" `Menu`.
//

import SwiftUI

/// Adapts `LockerMapViewControllerDelegate` to plain closures, and holds a
/// weak reference to the controller so this SwiftUI screen's own room
/// button (in its `ScreenNavigationBar` trailing slot, below) can call
/// `warp(to:)` — `navigationItem` set on a bare UIKit controller pushed via
/// `NavigationLink` isn't reliably bridged into the actual nav bar, so this
/// screen doesn't rely on that.
private final class LockerMapCoordinator: LockerMapViewControllerDelegate {
    weak var controller: LockerMapViewController?
    var onSelect: ((Int, String, LockerCellStatus) -> Void)?

    func lockerMapViewController(
        _ controller: LockerMapViewController,
        didSelectLockerNumber lockerNumber: Int,
        zoneId: String,
        status: LockerCellStatus
    ) {
        onSelect?(lockerNumber, zoneId, status)
    }
}

struct LockerApplicationMapView: View {
    @StateObject private var viewModel = LockerApplicationViewModel()
    @State private var coordinator = LockerMapCoordinator()
    @State private var dialogStage: LockerApplicationDialogStage?
    @State private var dialogLocation = ""
    @State private var applyErrorMessage: String?
    @State private var isZonePickerPresented = false
    /// Room last picked in the dropdown.
    @State private var selectedZoneId: String?
    /// Room the map itself reports as focused (warp or manual scroll).
    @State private var mapFocusedZoneId: String?
    /// Whether the map has been moved off its first view — shows "◎".
    @State private var isMapDisplaced = false
    @Environment(\.dismiss) private var dismiss

    /// Called once the user finishes both popups — lets `LockerView`
    /// promote the applied `Locker` to "내 사물함" and pop back to itself,
    /// same contract as `LockerApplicationView.onApplicationComplete`.
    var onApplicationComplete: (Locker) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .lockerApply, onBack: { dismiss() }) {
                HStack(spacing: Spacing.xs) {
                    if isMapDisplaced {
                        LockerResetViewButton {
                            selectedZoneId = nil
                            coordinator.controller?.resetView()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                    LockerZoneButton(zoneId: currentZoneId, isPresented: $isZonePickerPresented)
                }
                .animation(.easeOut(duration: 0.2), value: isMapDisplaced)
            }

            LockerStatusLegend()
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.screenContentTop)
                .padding(.bottom, Spacing.xs)

            LockerMapScreenView(
                delegate: coordinator,
                initialZoomFit: .fitHeight(padding: Spacing.sm),
                onFocusedZoneChange: { zoneId in
                    mapFocusedZoneId = zoneId
                    // A manual scroll overrides the last dropdown pick.
                    if zoneId != selectedZoneId { selectedZoneId = nil }
                },
                onDisplacedChange: { isMapDisplaced = $0 },
                onControllerReady: { coordinator.controller = $0 }
            )
            .ignoresSafeArea(edges: [.horizontal, .bottom])
        }
        .lockerZoneDropdown(isPresented: $isZonePickerPresented, currentZoneId: currentZoneId) { zoneId in
            selectedZoneId = zoneId
            coordinator.controller?.warp(to: zoneId)
        }
        .toolbar(.hidden, for: .navigationBar)
        .lockerApplyDialogOverlay(
            stage: $dialogStage,
            location: dialogLocation,
            apply: viewModel.apply,
            onError: { applyErrorMessage = $0 },
            onComplete: { locker in
                onApplicationComplete(locker)
                dismiss()
            }
        )
        .task {
            await viewModel.load()
            coordinator.onSelect = handleCellTap
        }
        .alert(
            Text(.commonError),
            isPresented: Binding(
                get: { applyErrorMessage != nil },
                set: { isPresented in if !isPresented { applyErrorMessage = nil } }
            )
        ) {
            Button(.commonOk, role: .cancel) {}
        } message: {
            Text(applyErrorMessage ?? "")
        }
    }

    /// Room the map is on — the one just picked, else wherever the map
    /// reports it's focused.
    private var currentZoneId: String? {
        selectedZoneId ?? mapFocusedZoneId
    }

    private func handleCellTap(lockerNumber: Int, zoneId: String, status: LockerCellStatus) {
        guard status == .empty else { return }
        guard let locker = viewModel.lockers.first(where: { $0.lockerNumber == lockerNumber }) else {
            applyErrorMessage = String(appLocalized: .lockerNotFound(zoneId, lockerNumber))
            return
        }
        dialogLocation = locker.location ?? zoneId
        dialogStage = .confirm(locker)
    }
}

#Preview {
    NavigationStack {
        LockerApplicationMapView()
    }
}
