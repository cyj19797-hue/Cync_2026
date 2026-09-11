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
//  while the student has no locker, `lockerApplicationPreview` also embeds
//  the bare map (no apply flow, browsing only) inline below the grid.
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
                AppTopBar(title: "사물함", trailing:  {
                    Image(systemName: "shippingbox")
                })

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if let myLocker = viewModel.myLocker {
                            MyLockerCard(locker: myLocker) {
                                isPasswordAlertPresented = true
                            }
                        } else {
                            applyPrompt
                        }

                        allLockersSection

                        if viewModel.myLocker == nil {
                            lockerApplicationPreview
                        }
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
            .alert("사물함 비밀번호", isPresented: $isPasswordAlertPresented) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.myLocker?.password ?? "비밀번호 정보가 없습니다.")
            }
            .alert(
                "오류",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
                )
            ) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    /// Shown instead of `MyLockerCard` when the user has no locker yet —
    /// opens `LockerApplicationMapView` (physical map + legend, tap an
    /// empty cell to apply) instead of "4-1 사물함 신청"'s 6×6 mock grid
    /// (`LockerApplicationView`) — that screen's code is unchanged but is
    /// currently unreachable from the app's UI.
    private var applyPrompt: some View {
        NavigationLink {
            LockerApplicationMapView { locker in
                // 신청 완료: 서버가 배정한 실제 사물함(비밀번호 포함)을 "나의
                // 사물함"으로 승격.
                viewModel.myLocker = locker
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("아직 신청한 사물함이 없어요")
                        .font(.noticeTitle).tracking(Tracking.noticeTitle)
                    Text("사물함을 신청해보세요")
                        .font(.calendarCaption).tracking(Tracking.calendarCaption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer(minLength: 0)

                NavigationChevron()
            }
            .foregroundStyle(Color.textPrimary)
            .padding(Spacing.md)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .strokeBorder(Color.gray300)
            }
        }
        .buttonStyle(.plain)
    }

    private var allLockersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("전체 사물함")
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

    /// Shown below `allLockersSection` only while the student has no
    /// locker — an always-visible, embedded preview of the physical map
    /// with the same color legend, so a locker's status is visible without
    /// a tap. Deliberately the bare `LockerMapScreenView`, not
    /// `LockerApplicationMapView` — no apply flow here; tapping a cell does
    /// nothing. Applying still works from tapping the grid above or from
    /// the "사물함 신청" prompt.
    private var lockerApplicationPreview: some View {
        LockerMapScreenView(initialZoomFit: .fitHeight(padding: Spacing.sm), showsLegend: true)
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
