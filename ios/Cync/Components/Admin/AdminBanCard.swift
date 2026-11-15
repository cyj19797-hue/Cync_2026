//
//  AdminBanCard.swift
//  Cync
//
//  "작성자 활동 정지" (Figma `731:4209`) — rises from the bottom of
//  "관리자 - 신고 관리" over a dimmed backdrop when 작성자 정지 is tapped
//  (a custom overlay, not `.sheet`).
//
//    header  작성자 활동 정지                              ⓧ
//    target  avatar 닉네임  학번 22011234
//    정지 기간 1일 3일 [7일] 30일 영구      (`AdminBanPeriodPicker`)
//    사유     "욕설 또는 혐오 표현 (신고 3건)"  (`AdminBanReasonField`, required)
//    ☑ 신고된 게시글도 함께 삭제 / 신고된 댓글도 함께 삭제
//    note    정지 기간 동안 … 처리 완료로 바뀌어요.
//    [취소] [7일 정지하기]  (red; disabled while the reason is empty)
//
//  Same card chrome as `AdminLockerActionCard` (20pt padding, 16pt corner,
//  soft shadow).
//

import SwiftUI

struct AdminBanCard: View {
    let authorName: String
    let authorColor: ProfileColor?
    let studentId: String
    let targetKind: ReportTargetKind
    @Binding var period: AdminBanPeriod
    @Binding var reason: String
    @Binding var alsoDelete: Bool
    /// The ban is in flight — buttons are disabled.
    var isProcessing = false
    let onClose: () -> Void
    let onConfirm: () -> Void

    private static let buttonHeight: CGFloat = 48
    private static let closeButtonSize: CGFloat = 28
    private static let avatarSize: CGFloat = 20

    private var canConfirm: Bool {
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            targetBox
            AdminBanPeriodPicker(selection: $period)
            AdminBanReasonField(text: $reason)
            CheckboxToggle(
                isChecked: $alsoDelete,
                titleKey: targetKind == .post ? .adminBanAlsoDeletePost : .adminBanAlsoDeleteComment,
                style: .accent,
                font: .adminFormCheckbox,
                tracking: Tracking.adminFormCheckbox,
                spacing: Spacing.xs,
                minHeight: 44
            )
            .padding(.vertical, -Spacing.cardInset / 2)
            Text(.adminBanNote)
                .font(.adminFootnote).tracking(Tracking.adminFootnote)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            actions
        }
        .padding(Spacing.md + Spacing.xxs)
        .background {
            RoundedRectangle(cornerRadius: Radius.actionCard)
                .fill(Color.appBackground)
                .shadow(color: Color.textPrimary.opacity(0.12), radius: 12, y: 8)
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Text(.adminBanTitle)
                .font(.adminCardTitle).tracking(Tracking.adminCardTitle)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.adminCardBody)
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: Self.closeButtonSize, height: Self.closeButtonSize)
                    .background(Circle().fill(Color.gray50))
                    .padding((44 - Self.closeButtonSize) / 2)
                    .contentShape(Rectangle())
                    .padding(-(44 - Self.closeButtonSize) / 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.commonClose))
        }
    }

    private var targetBox: some View {
        HStack(spacing: Spacing.xxs) {
            ProfileAvatar(nickname: authorName, color: authorColor, size: Self.avatarSize, initialFont: .adminReportTag)
            Text(verbatim: authorName)
                .font(.adminReportAuthor).tracking(Tracking.adminReportAuthor)
                .foregroundStyle(Color.textPrimary)
            Text(.adminBanStudentId(studentId))
                .font(.calendarCaption).tracking(Tracking.calendarCaption)
                .foregroundStyle(Color.textSecondary)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background {
            RoundedRectangle(cornerRadius: Radius.chipSelected)
                .fill(Color.gray50)
        }
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        HStack(spacing: Spacing.cardInset) {
            Button(action: onClose) {
                Text(.commonCancel)
                    .font(.adminLockerRowAction).tracking(Tracking.adminLockerRowAction)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: Self.buttonHeight)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.chipSelected)
                            .fill(Color.surface)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onConfirm) {
                Text(period.confirmKey)
                    .font(.adminPrimaryAction).tracking(Tracking.adminPrimaryAction)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: Self.buttonHeight)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.chipSelected)
                            .fill(Color.adminDanger)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
            .opacity(canConfirm ? 1 : 0.4)
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var period = AdminBanPeriod.default
        @State private var reason = "욕설 또는 혐오 표현 (신고 3건)"
        @State private var alsoDelete = true
        var body: some View {
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.3).ignoresSafeArea()
                AdminBanCard(
                    authorName: "익명", authorColor: nil, studentId: "22011234", targetKind: .post,
                    period: $period, reason: $reason, alsoDelete: $alsoDelete,
                    onClose: {}, onConfirm: {}
                )
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
    }
    return PreviewHost()
}
