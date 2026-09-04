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
//  No UIKit anywhere on this screen — the location dropdown is a plain
//  SwiftUI `Menu`, which already renders as the native iOS pull-down/pop-up
//  control Figma's `ChevronDown` affordance implies; nothing here needed a
//  UIKit escape hatch.
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
                    }
                    .padding(Spacing.md)
                }
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
    /// links to "4-1 사물함 신청" (not part of the "4 사물함" Figma frame
    /// itself, but the natural entry point into it).
    private var applyPrompt: some View {
        NavigationLink {
            LockerApplicationView { locker in
                // 신청 완료: 서버가 배정한 실제 사물함(비밀번호/반납기한 포함)을
                // "나의 사물함"으로 승격.
                viewModel.myLocker = locker
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("아직 신청한 사물함이 없어요")
                        .font(.noticeTitle)
                    Text("사물함을 신청해보세요")
                        .font(.calendarCaption)
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
                    .font(.noticeTitle)
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
                    .font(.lockerLocationText)
                    .foregroundStyle(Color.textPrimary)
                }
            }

            LazyVGrid(columns: lockerGridColumns, spacing: Spacing.xxs) {
                ForEach(viewModel.lockersAtSelectedLocation) { locker in
                    LockerCellView(locker: locker, isMine: locker.id == viewModel.myLocker?.id)
                }
            }
        }
    }
}

#Preview("사물함 있음") {
    LockerView(viewModel: LockerViewModel())
}

#Preview("사물함 없음 (신청 유도)") {
    LockerView(viewModel: LockerViewModel())
}
