//
//  AdminBanManageView.swift
//  Cync
//
//  Figma "관리자 - 활동 정지 관리 (학번 입력)" (`731:4257`). Pushed from the
//  "활동 정지 관리" button on 신고 관리's navigation bar.
//
//  Top to bottom: `ScreenNavigationBar` → tab chips (정지 / 정지 해제) →
//  학번 (number pad, no spaces) → 정지 tab only: 정지 기간 + 사유 (the same
//  `AdminBanPeriodPicker` / `AdminBanReasonField` as the report screen's
//  ban card) → guide line → "이 기기에서 처리한 내역" (last 20) → red button
//  pinned to the bottom ("22011234 7일 정지하기" / "22011234 정지 해제하기").
//
//  The button always asks first (`AdminLockerConfirmDialog`): a ban can be
//  lifted, but a mistyped 학번 hits someone else. Results go to a toast,
//  failures to `ErrorDialog`. No system `.alert`/`.sheet`.
//
//  Deviations from Figma: the shared `ScreenNavigationBar` (dark chevron,
//  17pt title), 12pt from the bar to the first block, and the app's
//  bordered `LabeledInputField` for 학번 / 사유 instead of gray filled boxes.
//  The button's red is `adminDanger` (4.5:1 white label) — see Colors.swift.
//

import SwiftUI

struct AdminBanManageView: View {
    @StateObject private var viewModel: AdminBanManageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmPresented = false

    init() {
        _viewModel = StateObject(wrappedValue: AdminBanManageViewModel())
    }

    /// Previews inject sample data.
    init(viewModel: AdminBanManageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .adminBanManageTitle, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    tabRow
                    AdminStudentIdField(text: $viewModel.studentId)
                    if viewModel.selectedTab == .ban {
                        AdminBanPeriodPicker(selection: $viewModel.period)
                        AdminBanReasonField(text: $viewModel.reason)
                    }
                    Text(.adminBanManageGuide)
                        .font(.adminFootnote).tracking(Tracking.adminFootnote)
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                    logSection
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.screenContentTop)
                .padding(.bottom, Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) { submitBar }
        .toolbar(.hidden, for: .navigationBar)
        .overlay { dialogs }
        .toast(message: $viewModel.toastMessage)
        .animation(.easeOut(duration: 0.2), value: viewModel.selectedTab)
        .animation(.easeOut(duration: 0.2), value: isConfirmPresented)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
    }

    private var tabRow: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(AdminBanTab.allCases, id: \.self) { tab in
                SelectableChip(titleKey: tab.titleKey, isSelected: viewModel.selectedTab == tab, appearance: .tab) {
                    viewModel.selectedTab = tab
                }
            }
        }
    }

    // MARK: - 이 기기에서 처리한 내역

    private var logSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            AdminFormLabel(key: .adminBanManageLogTitle)
            if viewModel.log.isEmpty {
                Text(.adminBanManageLogEmpty)
                    .font(.adminCardBody).tracking(Tracking.adminCardBody)
                    .foregroundStyle(Color.textSecondary)
            } else {
                ForEach(viewModel.log) { entry in
                    HStack(spacing: Spacing.xs) {
                        Text(verbatim: entry.studentId)
                            .font(.adminFormCheckbox).tracking(Tracking.adminFormCheckbox)
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(entry.detailText)
                            .font(.adminCardBody).tracking(Tracking.adminCardBody)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.compactButton + Spacing.xxs)
                    .padding(.vertical, Spacing.cardInset)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.chipSelected)
                            .fill(Color.gray50)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Bottom button

    private var submitBar: some View {
        PrimaryActionButton(
            titleKey: viewModel.submitKey,
            isEnabled: viewModel.canSubmit,
            tint: .adminDanger,
            font: .adminPrimaryAction,
            tracking: Tracking.adminPrimaryAction
        ) {
            if viewModel.validateBeforeConfirm() {
                hideKeyboard()
                isConfirmPresented = true
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.cardInset)
        .background(Color.appBackground)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Dialogs

    @ViewBuilder
    private var dialogs: some View {
        if isConfirmPresented || viewModel.errorMessage != nil {
            ZStack {
                Color.dimOverlay
                    .ignoresSafeArea()
                    .onTapGesture {
                        isConfirmPresented = false
                        viewModel.errorMessage = nil
                    }

                Group {
                    if let message = viewModel.errorMessage {
                        ErrorDialog(titleKey: .commonError, message: message) {
                            viewModel.errorMessage = nil
                        }
                    } else {
                        AdminLockerConfirmDialog(
                            titleKey: viewModel.confirmTitleKey,
                            messageKey: viewModel.selectedTab == .ban
                                ? .adminBanManageConfirmBanMessage : .adminBanManageConfirmUnbanMessage,
                            confirmKey: viewModel.selectedTab == .ban
                                ? .adminBanManageConfirmBanAction : .adminBanManageConfirmUnbanAction,
                            onCancel: { isConfirmPresented = false },
                            onConfirm: {
                                isConfirmPresented = false
                                Task { await viewModel.submit() }
                            },
                            confirmTint: viewModel.selectedTab == .ban ? .adminDanger : .buttonAccent
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .transition(.opacity)
        }
    }
}

#Preview("정지 탭") {
    NavigationStack {
        AdminBanManageView(viewModel: AdminBanManageViewModel(
            previewTab: .ban,
            studentId: "22011234",
            log: AdminBanManageViewModel.previewLog
        ))
    }
}

#Preview("정지 해제 탭") {
    NavigationStack {
        AdminBanManageView(viewModel: AdminBanManageViewModel(
            previewTab: .unban,
            studentId: "21019876",
            log: AdminBanManageViewModel.previewLog
        ))
    }
}
