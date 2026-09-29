//
//  LockerView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `47:645` ("4 사물함").
//  Top bar (`47:683`) + "내 사물함" summary card (`243:4522`, now
//  `MyLockerCard`) + "전체 사물함" section (`47:789`): a location picker and a
//  6-column grid of `LockerCellView`. The bottom tab bar (`47:726`) is not
//  built here — it's RootTabView's `TabView`, this is just its "사물함" tab
//  content.
//
//  The location dropdown is a plain SwiftUI `Menu`, which already renders
//  as the native iOS pull-down/pop-up control Figma's `ChevronDown`
//  affordance implies. Tapping the "전체 사물함" grid itself (not a chevron)
//  and the "사물함 신청" prompt both push `LockerApplicationMapView` (the
//  physical map + apply flow, UIKit under the hood via `LockerMapScreenView`);
//  `lockerApplicationPreview` also always embeds the bare map (no apply
//  flow, browsing only) inline below the grid — once the student has a
//  locker assigned, it warps to and highlights that locker's cell instead
//  of resting at the plain fit-to-screen view (`focusLockerNumber`).
//
//  `.scrollBounceBehavior(.basedOnSize)` on the outer `ScrollView` — when
//  the content already fits on screen (no locker grid overflow, no map
//  preview pushing it past the fold), the view shouldn't rubber-band/bounce
//  at all when touched. Scrolling itself stays on for whenever the content
//  actually is taller than the screen (a large grid, or with the map
//  preview) — `SwiftUI` has no way to kill bounce unconditionally without
//  also killing real scrolling, so `.basedOnSize` (not `.never`, which
//  doesn't exist on `ScrollBounceBehavior`) is the closest match to "don't
//  move unless it actually needs to."
//

import SwiftUI

private let lockerGridColumns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xxs), count: 6)

struct LockerView: View {
    @StateObject private var viewModel: LockerViewModel
    @State private var isPasswordAlertPresented = false

    init(viewModel: LockerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar(title: .tabLockers, trailing:  {
                    Image(systemName: "shippingbox")
                })

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        myLockerCard

                        allLockersSection

                        lockerApplicationPreview
                    }
                    .padding(Spacing.md)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(Color.appBackground)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.load()
            }
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

    /// The "내 사물함" summary card (Figma component `243:4541`). While the
    /// student has no locker, this is its `속성 1=신청` variant wrapped in a
    /// `NavigationLink` — tapping the whole card opens
    /// `LockerApplicationMapView` (physical map + legend, tap an empty cell
    /// to apply) instead of "4-1 사물함 신청"'s 6×6 mock grid
    /// (`LockerApplicationView`) — that screen's code is unchanged but is
    /// currently unreachable from the app's UI. Once assigned, the card
    /// itself picks the right variant (승인대기/베리언트4/기본) from
    /// `viewModel.myLocker`'s status and password.
    @ViewBuilder
    private var myLockerCard: some View {
        if viewModel.myLocker == nil {
            NavigationLink {
                LockerApplicationMapView { locker in
                    // 신청 완료: 서버가 배정한 실제 사물함(비밀번호 포함)을 "나의
                    // 사물함"으로 승격.
                    viewModel.myLocker = locker
                }
            } label: {
                MyLockerCard(locker: nil)
            }
            .buttonStyle(.plain)
        } else {
            MyLockerCard(locker: viewModel.myLocker) {
                isPasswordAlertPresented = true
            } onRegisterPassword: {
                isPasswordAlertPresented = true
            }
        }
    }

    private var allLockersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(.lockerAll)
                    .font(.noticeTitle).tracking(Tracking.noticeTitle)
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)

                Menu {
                    ForEach(viewModel.locations, id: \.self) { location in
                        Button {
                            viewModel.selectedLocation = location
                        } label: {
                            if location == viewModel.selectedLocation {
                                Label(location, systemImage: "checkmark")
                            } else {
                                Text(location)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Text(viewModel.selectedLocation)
                        Image(systemName: "chevron.down")
                    }
                    .font(.lockerLocationText).tracking(Tracking.lockerLocationText)
                    .foregroundStyle(Color.textPrimary)
                }
            }

            NavigationLink {
                LockerApplicationMapView { locker in
                    viewModel.myLocker = locker
                }
            } label: {
                LazyVGrid(columns: lockerGridColumns, spacing: Spacing.xxs) {
                    ForEach(viewModel.lockersAtSelectedLocation) { locker in
                        LockerCellView(locker: locker, isMine: locker.id == viewModel.myLocker?.id)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// Always shown below `allLockersSection` — an embedded preview of the
    /// physical map with the same color legend, so a locker's status is
    /// visible without a tap. While the student has an assigned locker
    /// (any status), it warps straight to and highlights that locker's
    /// cell instead of resting at the plain fit-to-screen view. Deliberately
    /// the bare `LockerMapScreenView`, not `LockerApplicationMapView` — no
    /// apply flow here; tapping a cell does nothing. Applying still works
    /// from tapping the grid above or from the "사물함 신청" prompt.
    private var lockerApplicationPreview: some View {
        LockerMapScreenView(
            initialZoomFit: .fitHeight(padding: Spacing.sm),
            showsLegend: true,
            focusLockerNumber: viewModel.myLocker?.lockerNumber
        )
        .frame(height: 520)
            .clipShape(RoundedRectangle(cornerRadius: Radius.scheduleCard))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .strokeBorder(Color.gray300)
            }
    }
}

#Preview("사물함 있음") {
    LockerView(viewModel: LockerViewModel())
}

#Preview("사물함 없음 (신청 유도)") {
    LockerView(viewModel: LockerViewModel())
}
