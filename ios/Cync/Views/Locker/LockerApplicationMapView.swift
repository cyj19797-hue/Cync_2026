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

import SwiftUI

/// Adapts `LockerMapViewControllerDelegate` to plain closures, and holds a
/// weak reference to the controller so this SwiftUI screen's own "이동"
/// menu (in its `ScreenNavigationBar` trailing slot, below) can call
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
    @Environment(\.dismiss) private var dismiss

    /// Called once the user finishes both popups — lets `LockerView`
    /// promote the applied `Locker` to "내 사물함" and pop back to itself,
    /// same contract as `LockerApplicationView.onApplicationComplete`.
    var onApplicationComplete: (Locker) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: "사물함 신청", onBack: { dismiss() }) {
                Menu("이동") {
                    ForEach(LockerMapViewController.zoneIdsInOrder, id: \.self) { zoneId in
                        Button(zoneId) { coordinator.controller?.warp(to: zoneId) }
                    }
                }
            }

            LockerMapScreenView(
                delegate: coordinator,
                initialZoomFit: .fitHeight(padding: Spacing.sm),
                showsLegend: true,
                onControllerReady: { coordinator.controller = $0 }
            )
            .ignoresSafeArea(edges: [.horizontal, .bottom])
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
            "오류",
            isPresented: Binding(
                get: { applyErrorMessage != nil },
                set: { isPresented in if !isPresented { applyErrorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(applyErrorMessage ?? "")
        }
    }

    private func handleCellTap(lockerNumber: Int, zoneId: String, status: LockerCellStatus) {
        guard status == .empty else { return }
        guard let locker = viewModel.lockers.first(where: { $0.lockerNumber == lockerNumber }) else {
            applyErrorMessage = "\(zoneId) \(lockerNumber)번 사물함 정보를 서버에서 찾을 수 없습니다."
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
