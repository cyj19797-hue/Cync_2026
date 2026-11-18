//
//  AdminLockerManageView.swift
//  Cync
//
//  Figma "관리자 - 사물함 관리 (승인 대기)" (`690:3687`). Pushed from
//  LockerView's "관리" button, which only admins see; the bottom tab bar
//  hides on its own (pushed screens aren't a tab root — TabBarVisibility).
//
//  Top to bottom: `ScreenNavigationBar` → summary card → tab chips (승인
//  대기 n / 사용 중 / 배치도) → 학번 search → "승인 대기 n건" + 여러 개 선택
//  → rows (`AdminLockerRow`) → deposit guide. In selection mode a
//  "선택 승인 (n)" button is pinned to the bottom.
//
//  Tabs: 승인 대기 (Figma `690:3687`), 사용 중 (`690:3765`), 배치도
//  (`690:3881`).
//
//  배치도 reuses the students' locker map (`LockerMapScreenView`) with its
//  admin options: `.admin` palette (사용 중 / 고장 told apart), statuses
//  fed from the view model (`statusesOverride` — the map never fetches on
//  its own), pull-to-refresh routed to the view model, and a blue outline
//  on the selected cell. It sits outside the ScrollView (the map scrolls
//  and zooms itself) under a room button + admin legend row. Tapping a cell
//  opens `AdminLockerActionCard` over a dimmed backdrop (custom overlay,
//  not `.sheet`); 승인 is immediate, 거부 / 반납 confirm first, 고장 처리 /
//  복구하기 are immediate (reversible). Any change recolors the map, the
//  summary and the other tabs at once — they all read `lockers`.
//
//  사용 중: 학번/번호 search + room filter (`LockerZoneButton` `.field` +
//  "전체 구역" row) → "사용 중 n개 / 번호순" → in-use rows (비밀번호 보기,
//  반납 after a confirm) → "학기 말 전체 반납", which isn't built yet: it's
//  drawn disabled with a "준비 중인 기능이에요" line, and tapping it only
//  shows that toast — no confirm, no request. Its label has no count, so it
//  doesn't look like it would do something.
//
//  Deviations from Figma, kept for consistency with the rest of the app:
//  the shared `ScreenNavigationBar` (dark chevron, 17pt title vs. Figma's
//  pink chevron / 15pt), the shared `SearchBar` (16pt Medium text), and
//  12pt from the bar to the first block (`Spacing.screenContentTop`, the
//  same on every screen; Figma has 8).
//
//  Results go to a toast; failures to `ErrorDialog`; 거부 asks first with
//  `AdminLockerConfirmDialog` (반납 too). No system `.alert`/`.sheet`.
//

import SwiftUI

/// Forwards the map's cell taps to SwiftUI.
private final class AdminLockerMapCoordinator: LockerMapViewControllerDelegate {
    weak var controller: LockerMapViewController?
    var onSelect: ((Int) -> Void)?

    func lockerMapViewController(
        _ controller: LockerMapViewController,
        didSelectLockerNumber lockerNumber: Int,
        zoneId: String,
        status: LockerCellStatus
    ) {
        onSelect?(lockerNumber)
    }
}

struct AdminLockerManageView: View {
    @StateObject private var viewModel: AdminLockerManageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var rejectTarget: Locker?
    @State private var returnTarget: Locker?
    @State private var isZonePickerPresented = false
    // 배치도
    @State private var mapCoordinator = AdminLockerMapCoordinator()
    @State private var isMapZonePickerPresented = false
    /// Room last picked in the dropdown.
    @State private var selectedMapZoneId: String?
    /// Room the map reports as focused (warp or manual scroll).
    @State private var mapFocusedZoneId: String?
    @State private var isMapDisplaced = false

    init() {
        _viewModel = StateObject(wrappedValue: AdminLockerManageViewModel())
    }

    /// Previews inject sample data.
    init(viewModel: AdminLockerManageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .adminLockerTitle, onBack: { dismiss() }) {
                EmptyView()
            }

            if viewModel.selectedTab == .map {
                // The map scrolls/zooms itself — no ScrollView around it.
                mapTab
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.cardInset) {
                        AdminLockerSummaryCard(summary: viewModel.summary)
                        tabRow
                        tabContent
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.screenContentTop)
                    .padding(.bottom, Spacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable { await viewModel.load() }
            }
        }
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.isSelecting && viewModel.selectedTab == .pending {
                selectionBar
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .lockerZoneDropdown(
            isPresented: $isZonePickerPresented,
            currentZoneId: viewModel.inUseZoneFilter,
            allZonesKey: .adminLockerAllZones
        ) { zoneId in
            viewModel.inUseZoneFilter = zoneId
        }
        .lockerZoneDropdown(isPresented: $isMapZonePickerPresented, currentZoneId: currentMapZoneId) { zoneId in
            selectedMapZoneId = zoneId
            mapCoordinator.controller?.warp(to: zoneId)
        }
        .overlay { mapCardOverlay }
        .overlay { dialogs }
        // Above the dim, so results stay visible.
        .toast(message: $viewModel.toastMessage)
        .animation(.easeOut(duration: 0.2), value: viewModel.selectedMapLockerNumber)
        .animation(.easeOut(duration: 0.2), value: rejectTarget?.id)
        .animation(.easeOut(duration: 0.2), value: returnTarget?.id)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .animation(.easeOut(duration: 0.2), value: viewModel.isSelecting)
        .task { await viewModel.load() }
        // Passwords never stay revealed once the admin leaves.
        .onDisappear { viewModel.hideAllPasswords() }
    }

    // MARK: - Tabs

    private var tabRow: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(AdminLockerTab.allCases, id: \.self) { tab in
                SelectableChip(
                    titleKey: tab.titleKey,
                    isSelected: viewModel.selectedTab == tab,
                    appearance: .tab,
                    count: tab == .pending ? viewModel.summary.pending : nil
                ) {
                    viewModel.selectedTab = tab
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .pending:
            pendingContent
        case .inUse:
            inUseContent
        case .map:
            // Drawn outside the ScrollView (see `mapTab`).
            EmptyView()
        }
    }

    // MARK: - 승인 대기

    @ViewBuilder
    private var pendingContent: some View {
        SearchBar(
            text: $viewModel.searchText,
            isActive: .constant(false),
            placeholder: .adminLockerSearchPlaceholder,
            showsCancelButton: false
        )

        listHeader

        if viewModel.hasLoaded && viewModel.filteredPending.isEmpty {
            message(viewModel.isSearching ? .adminLockerSearchEmpty : .adminLockerEmpty)
        } else {
            ForEach(viewModel.filteredPending) { locker in
                row(for: locker)
            }
        }

        Text(.adminLockerGuide)
            .font(.adminFootnote).tracking(Tracking.adminFootnote)
            .foregroundStyle(Color.textSecondary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var listHeader: some View {
        HStack {
            Text(.adminLockerPendingCount(viewModel.pendingLockers.count))
                .font(.adminListHeader).tracking(Tracking.adminListHeader)
                .foregroundStyle(Color.textPrimary)
            Spacer(minLength: Spacing.xs)
            if !viewModel.pendingLockers.isEmpty {
                Button {
                    viewModel.toggleSelecting()
                } label: {
                    Text(viewModel.isSelecting ? .commonCancel : .adminLockerSelectMultiple)
                        .font(.adminTextAction).tracking(Tracking.adminTextAction)
                        .foregroundStyle(Color.eventAccent)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isApprovingSelection)
                // Keeps the row at its text height; the tap area overhangs.
                .padding(.vertical, -Spacing.cardInset)
            }
        }
    }

    private func row(for locker: Locker) -> some View {
        AdminLockerRow(
            title: viewModel.title(for: locker),
            subtitle: viewModel.subtitle(for: locker),
            kind: .pending(
                onReject: { rejectTarget = locker },
                onApprove: { Task { await viewModel.approve(locker) } }
            ),
            isProcessing: viewModel.processingIDs.contains(locker.id),
            isSelecting: viewModel.isSelecting,
            isSelected: viewModel.selectedIDs.contains(locker.id),
            onToggleSelection: { viewModel.toggleSelection(locker) }
        )
    }

    // MARK: - 배치도

    private var mapTab: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.cardInset) {
                AdminLockerSummaryCard(summary: viewModel.summary)
                tabRow
                HStack(spacing: Spacing.cardInset) {
                    HStack(spacing: Spacing.xs) {
                        LockerZoneButton(
                            zoneId: currentMapZoneId,
                            isPresented: $isMapZonePickerPresented,
                            style: .field,
                            fieldVerticalPadding: Spacing.compactButton
                        )
                        if isMapDisplaced {
                            LockerResetViewButton {
                                selectedMapZoneId = nil
                                mapCoordinator.controller?.resetView()
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: isMapDisplaced)
                    .fixedSize()

                    LockerStatusLegend(palette: .admin)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.screenContentTop)

            LockerMapScreenView(
                delegate: mapCoordinator,
                initialZoomFit: .fitHeight(padding: Spacing.sm),
                onFocusedZoneChange: { zoneId in
                    mapFocusedZoneId = zoneId
                    // A manual scroll overrides the last dropdown pick.
                    if zoneId != selectedMapZoneId { selectedMapZoneId = nil }
                },
                onDisplacedChange: { isMapDisplaced = $0 },
                onControllerReady: { controller in
                    mapCoordinator.controller = controller
                    mapCoordinator.onSelect = { number in
                        viewModel.selectedMapLockerNumber = number
                    }
                },
                palette: .admin,
                statusesOverride: viewModel.mapStatuses,
                onPullToRefresh: { await viewModel.load() },
                selectedLockerNumber: viewModel.selectedMapLockerNumber
            )
            .padding(.top, Spacing.xs)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    /// Room the map is on — the one just picked, else the focused one.
    private var currentMapZoneId: String? {
        selectedMapZoneId ?? mapFocusedZoneId
    }

    @ViewBuilder
    private var mapCardOverlay: some View {
        if viewModel.selectedTab == .map, let number = viewModel.selectedMapLockerNumber {
            ZStack(alignment: .bottom) {
                Color.dimOverlay
                    .ignoresSafeArea()
                    .onTapGesture { viewModel.selectedMapLockerNumber = nil }

                actionCard(for: number)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .transition(.opacity)
        }
    }

    private func actionCard(for number: Int) -> some View {
        let locker = viewModel.locker(number: number)
        let close = { viewModel.selectedMapLockerNumber = nil }

        let state: AdminLockerActionCard.State
        switch locker?.status {
        case .pending: state = .pending(studentId: locker?.currentUserId, password: locker?.password)
        case .inUse:
            state = .inUse(
                studentId: locker?.currentUserId,
                password: locker?.password,
                startDate: locker.flatMap(viewModel.startDateText(for:))
            )
        case .available: state = .available
        case .broken: state = .broken
        case nil: state = .unknown
        }

        return AdminLockerActionCard(
            paddedNumber: AdminLockerManageViewModel.paddedNumber(number),
            zoneId: viewModel.zoneId(forLockerNumber: number) ?? locker?.location ?? "-",
            state: state,
            isProcessing: locker.map { viewModel.processingIDs.contains($0.id) } ?? false,
            onClose: close,
            onSecondary: {
                // 승인 대기: 거부 asks first.
                if let locker { rejectTarget = locker }
            },
            onPrimary: {
                guard let locker else { return }
                switch locker.status {
                case .pending:
                    Task { if await viewModel.approve(locker) { close() } }
                case .inUse:
                    returnTarget = locker
                case .available:
                    Task { if await viewModel.markBroken(locker) { close() } }
                case .broken:
                    Task { if await viewModel.restore(locker) { close() } }
                }
            }
        )
    }

    /// After a confirmed 거부/반납 from the card, close it.
    private func closeCard(ifShowing locker: Locker) {
        if viewModel.selectedMapLockerNumber == locker.lockerNumber {
            viewModel.selectedMapLockerNumber = nil
        }
    }

    // MARK: - 사용 중

    @ViewBuilder
    private var inUseContent: some View {
        HStack(spacing: Spacing.xs) {
            SearchBar(
                text: $viewModel.inUseSearchText,
                isActive: .constant(false),
                placeholder: .adminLockerInUseSearchPlaceholder,
                showsCancelButton: false
            )
            LockerZoneButton(
                zoneId: viewModel.inUseZoneFilter,
                isPresented: $isZonePickerPresented,
                allZonesKey: .adminLockerAllZones,
                style: .field
            )
        }
        // The room button takes the search field's height.
        .fixedSize(horizontal: false, vertical: true)

        HStack {
            Text(.adminLockerInUseHeader(viewModel.filteredInUse.count))
                .font(.adminListHeader).tracking(Tracking.adminListHeader)
                .foregroundStyle(Color.textPrimary)
            Spacer(minLength: Spacing.xs)
            Text(.adminLockerSortByNumber)
                .font(.adminTextAction).tracking(Tracking.adminTextAction)
                .foregroundStyle(Color.textSecondary)
        }

        if viewModel.hasLoaded && viewModel.filteredInUse.isEmpty {
            message(viewModel.isFilteringInUse ? .adminLockerSearchEmpty : .adminLockerInUseEmpty)
        } else {
            LazyVStack(spacing: Spacing.cardInset) {
                ForEach(viewModel.filteredInUse) { locker in
                    inUseRow(for: locker)
                }
            }
        }

        bulkReturnButton
    }

    private func inUseRow(for locker: Locker) -> some View {
        AdminLockerRow(
            title: viewModel.title(for: locker),
            subtitle: viewModel.subtitle(for: locker),
            kind: .inUse(
                password: locker.password,
                isPasswordVisible: viewModel.visiblePasswordIDs.contains(locker.id),
                sinceText: viewModel.sinceText(for: locker),
                onTogglePassword: { viewModel.togglePassword(locker) },
                onReturn: { returnTarget = locker }
            ),
            isProcessing: viewModel.processingIDs.contains(locker.id)
        )
    }

    /// "학기 말 전체 반납" — a placeholder until bulk return is built.
    /// Disabled-looking; a tap only shows the "준비 중" toast (the disabled
    /// button itself takes no taps, so a clear layer on top catches them).
    private var bulkReturnButton: some View {
        VStack(spacing: Spacing.xs) {
            PrimaryActionButton(
                titleKey: .adminLockerReturnAll,
                isEnabled: viewModel.isBulkReturnAvailable
            ) {}
            .overlay {
                if !viewModel.isBulkReturnAvailable {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.bulkReturnTapped() }
                        .accessibilityElement()
                        .accessibilityLabel(Text(.adminLockerReturnAll))
                        .accessibilityHint(Text(.adminLockerReturnAllComingSoon))
                        .accessibilityAddTraits(.isButton)
                }
            }

            if !viewModel.isBulkReturnAvailable {
                Text(.adminLockerReturnAllComingSoon)
                    .font(.adminFootnote).tracking(Tracking.adminFootnote)
                    .foregroundStyle(Color.gray400)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, Spacing.xs)
    }

    private func message(_ key: LocalizedStringResource) -> some View {
        Text(key)
            .font(.emptyStateMessage).tracking(Tracking.emptyStateMessage)
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
    }

    // MARK: - Selection

    private var selectionBar: some View {
        PrimaryActionButton(
            titleKey: .adminLockerApproveSelected(viewModel.selectedIDs.count),
            isEnabled: !viewModel.selectedIDs.isEmpty && !viewModel.isApprovingSelection
        ) {
            Task { await viewModel.approveSelected() }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.cardInset)
        .background(Color.appBackground)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Dialogs

    @ViewBuilder
    private var dialogs: some View {
        if rejectTarget != nil || returnTarget != nil || viewModel.errorMessage != nil {
            ZStack {
                Color.dimOverlay
                    .ignoresSafeArea()
                    .onTapGesture {
                        rejectTarget = nil
                        returnTarget = nil
                        viewModel.errorMessage = nil
                    }

                Group {
                    if let message = viewModel.errorMessage {
                        ErrorDialog(titleKey: .commonError, message: message) {
                            viewModel.errorMessage = nil
                        }
                    } else if let locker = rejectTarget {
                        AdminLockerConfirmDialog.reject(
                            paddedNumber: AdminLockerManageViewModel.paddedNumber(locker.lockerNumber),
                            onCancel: { rejectTarget = nil }
                        ) {
                            rejectTarget = nil
                            Task { if await viewModel.reject(locker) { closeCard(ifShowing: locker) } }
                        }
                    } else if let locker = returnTarget {
                        AdminLockerConfirmDialog.return(
                            paddedNumber: AdminLockerManageViewModel.paddedNumber(locker.lockerNumber),
                            onCancel: { returnTarget = nil }
                        ) {
                            returnTarget = nil
                            Task { if await viewModel.returnLocker(locker) { closeCard(ifShowing: locker) } }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .transition(.opacity)
        }
    }
}

#Preview("승인 대기 - 목록 있음") {
    NavigationStack {
        AdminLockerManageView(viewModel: AdminLockerManageViewModel(previewLockers: AdminLockerManageViewModel.previewLockers))
    }
}

#Preview("승인 대기 - 선택 모드") {
    NavigationStack {
        AdminLockerManageView(viewModel: AdminLockerManageViewModel(
            previewLockers: AdminLockerManageViewModel.previewLockers,
            isSelecting: true
        ))
    }
}

#Preview("사용 중 - 목록 있음") {
    NavigationStack {
        AdminLockerManageView(viewModel: AdminLockerManageViewModel(
            previewLockers: AdminLockerManageViewModel.previewLockers,
            selectedTab: .inUse
        ))
    }
}

#Preview("사용 중 - 0건") {
    NavigationStack {
        AdminLockerManageView(viewModel: AdminLockerManageViewModel(
            previewLockers: AdminLockerManageViewModel.previewEmptyLockers,
            selectedTab: .inUse
        ))
    }
}

#Preview("사용 중 - 비밀번호 보기") {
    NavigationStack {
        AdminLockerManageView(viewModel: AdminLockerManageViewModel(
            previewLockers: AdminLockerManageViewModel.previewLockers,
            selectedTab: .inUse,
            visiblePasswordIDs: [7]
        ))
    }
}

#Preview("배치도") {
    NavigationStack {
        AdminLockerManageView(viewModel: AdminLockerManageViewModel(
            previewLockers: AdminLockerManageViewModel.previewLockers,
            selectedTab: .map,
            selectedMapLockerNumber: 6
        ))
    }
}
