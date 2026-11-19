//
//  AdminReturnAllDialog.swift
//  Cync
//
//  "학기 말 전체 반납" confirm (관리자 사물함 관리 > 사용 중). Opens with the
//  server's preview (`POST /api/lockers/return-all?confirm=false`) so the
//  count is what would really be returned. "승인 대기 신청도 함께 취소"
//  re-asks the preview with `includePending=true`. Nothing changes until
//  the red "n개 반납".
//
//  - 0 lockers: says so and offers only 확인 — the checkbox stays, since
//    there may be pending requests to cancel even with nothing in use.
//  - While a preview reloads: the count dims and the red button waits.
//  - While executing: every control is disabled and the backdrop doesn't
//    close it (the view handles that).
//

import SwiftUI

struct AdminReturnAllDialogState: Equatable {
    var includePending = false
    var preview: ReturnAllResult?
    var isLoadingPreview = false
    var isExecuting = false

    var count: Int { preview?.count ?? 0 }
    var isBusy: Bool { isLoadingPreview || isExecuting }
}

struct AdminReturnAllDialog: View {
    let state: AdminReturnAllDialogState
    let onToggleIncludePending: (Bool) -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        DialogCard {
            Text(.adminLockerReturnAll)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .dialogTitleGap()

            Text(message)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(state.isLoadingPreview ? 0.4 : 1)
                .overlay {
                    if state.isLoadingPreview {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.textSecondary)
                    }
                }

            CheckboxToggle(
                isChecked: Binding(
                    get: { state.includePending },
                    set: { onToggleIncludePending($0) }
                ),
                titleKey: .adminLockerReturnAllIncludePending,
                spacing: Spacing.xs,
                minHeight: 44
            )
            .disabled(state.isExecuting)
            .dialogBodyGap()

            DialogActionRow {
                if state.count == 0 && !state.isLoadingPreview {
                    DialogActionButton(titleKey: .commonOk, style: .primary, action: onCancel)
                } else {
                    DialogActionButton(titleKey: .commonCancel, action: onCancel)
                        .disabled(state.isExecuting)
                    DialogActionButton(
                        titleKey: .adminLockerReturnAllConfirm(state.count),
                        style: .primary,
                        tint: .adminDanger,
                        action: onConfirm
                    )
                    .disabled(state.isBusy)
                    .overlay {
                        if state.isExecuting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(Color.white)
                                .accessibilityLabel(Text(.adminLockerReturnAllInProgress))
                        }
                    }
                }
            }
        }
    }

    private var message: LocalizedStringResource {
        if state.count == 0 { return .adminLockerReturnAllEmpty }
        return state.includePending
            ? .adminLockerReturnAllMessageWithPending(state.count)
            : .adminLockerReturnAllMessage(state.count)
    }
}

private func returnAllPreview(_ state: AdminReturnAllDialogState) -> some View {
    ZStack {
        Color.dimOverlay.ignoresSafeArea()
        AdminReturnAllDialog(state: state, onToggleIncludePending: { _ in }, onCancel: {}, onConfirm: {})
            .padding(.horizontal, Spacing.md)
    }
}

#Preview("체크 꺼짐") {
    returnAllPreview(AdminReturnAllDialogState(
        preview: ReturnAllResult(executed: false, count: 42, lockerNumbers: [])
    ))
}

#Preview("체크 켜짐") {
    returnAllPreview(AdminReturnAllDialogState(
        includePending: true,
        preview: ReturnAllResult(executed: false, count: 51, lockerNumbers: [])
    ))
}

#Preview("0개") {
    returnAllPreview(AdminReturnAllDialogState(
        preview: ReturnAllResult(executed: false, count: 0, lockerNumbers: [])
    ))
}
