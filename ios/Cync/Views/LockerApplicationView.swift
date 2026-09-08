//
//  LockerApplicationView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `240:4063` ("4-1 사물함 신청").
//  Back-chevron + centered title nav (`ScreenNavigationBar`, same pattern
//  as CalendarEventListView) + a 6-column grid (`361:4254`) reusing
//  `LockerCellView` from the "4 사물함" screen. Pushed from LockerView's
//  "사물함 신청하기" prompt (shown when the user has no locker yet).
//
//  Tapping an available cell selects it (a brandPrimary ring) and reveals a
//  bottom "N번 사물함 신청하기" button, which now walks through the two popup
//  frames requested afterwards: `240:4403` ("4-1-1 사물함 신청 팝업", confirm)
//  then `243:4742` ("4-1-2 사물함 신청 팝업2", account info) — both presented
//  as a dimmed overlay, same non-UIKit pattern as NoticeDetailView.
//
//  No UIKit anywhere on this screen — selection state, the grid, and the
//  popup overlays are all plain SwiftUI.
//

import SwiftUI

private let lockerApplicationGridColumns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xxs), count: 6)

/// Which popup (if any) is currently shown over a locker grid — shared
/// with `LockerApplicationMapView`, the map-based apply entry.
enum LockerApplicationDialogStage {
    case confirm(Locker)
    case accountInfo(Locker)
}

extension View {
    /// The "신청" confirm → 계좌 안내 popup flow, as a dimmed overlay driven
    /// by `stage`. Shared by `LockerApplicationView` (6×6 mock grid) and
    /// `LockerApplicationMapView` (physical map) so the two entry points
    /// can't drift apart on how applying actually behaves.
    func lockerApplyDialogOverlay(
        stage: Binding<LockerApplicationDialogStage?>,
        location: String,
        apply: @escaping (Locker) async throws -> Locker,
        onError: @escaping (String) -> Void,
        onComplete: @escaping (Locker) -> Void
    ) -> some View {
        overlay {
            if let currentStage = stage.wrappedValue {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    switch currentStage {
                    case .confirm(let locker):
                        LockerApplicationConfirmDialog(
                            locker: locker,
                            location: location,
                            onCancel: { stage.wrappedValue = nil },
                            onConfirm: {
                                Task {
                                    do {
                                        // Commits the application now — the
                                        // account-info dialog that follows just
                                        // relays the password/due date the
                                        // server just assigned.
                                        let applied = try await apply(locker)
                                        stage.wrappedValue = .accountInfo(applied)
                                    } catch {
                                        stage.wrappedValue = nil
                                        onError(error.localizedDescription)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, Spacing.md)
                    case .accountInfo(let locker):
                        LockerApplicationAccountDialog {
                            stage.wrappedValue = nil
                            onComplete(locker)
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
            }
        }
    }
}

struct LockerApplicationView: View {
    @StateObject private var viewModel = LockerApplicationViewModel()
    @State private var dialogStage: LockerApplicationDialogStage?
    @State private var applyErrorMessage: String?
    @Environment(\.dismiss) private var dismiss

    /// Called once the user finishes both popups (taps "확인" on the account
    /// info dialog) — lets LockerView promote the applied `Locker` (with its
    /// server-assigned password/due date) to "내 사물함" and pop back to itself.
    var onApplicationComplete: (Locker) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: "사물함 신청", onBack: { dismiss() })

            ScrollView {
                LazyVGrid(columns: lockerApplicationGridColumns, spacing: Spacing.xxs) {
                    ForEach(viewModel.lockers) { locker in
                        let isSelectable = locker.status == .available
                        Button {
                            viewModel.selectLocker(locker)
                        } label: {
                            LockerCellView(
                                locker: locker,
                                maskOccupiedNumbers: false,
                                zeroPadded: true,
                                isSelected: viewModel.selectedLockerID == locker.id
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isSelectable)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.appBackground)
            .safeAreaInset(edge: .bottom) {
                if let selected = viewModel.selectedLocker {
                    applyButton(for: selected)
                }
            }
        }
        .background(Color.appBackground)
        .lockerApplyDialogOverlay(
            stage: $dialogStage,
            location: viewModel.location,
            apply: viewModel.apply,
            onError: { applyErrorMessage = $0 },
            onComplete: { locker in
                onApplicationComplete(locker)
                dismiss()
            }
        )
        .animation(.default, value: viewModel.selectedLockerID)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
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

    private func applyButton(for locker: Locker) -> some View {
        Button {
            dialogStage = .confirm(locker)
        } label: {
            Text("\(String(format: "%03d", locker.lockerNumber))번 사물함 신청하기")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.brandPrimary)
        .controlSize(.large)
        .padding(Spacing.md)
        .background(.bar)
    }

}

#Preview {
    NavigationStack {
        LockerApplicationView()
    }
}
