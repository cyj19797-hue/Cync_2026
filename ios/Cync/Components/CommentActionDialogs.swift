//
//  CommentActionDialogs.swift
//  Cync
//
//  The popups behind a comment's ⋮ menu on "5-1 게시글": delete
//  confirmation, report (confirm + reason), and the moderator's edit box.
//  The delete and report popups also serve the post's own ⋮ menu — pass
//  the post's title/message keys in place of the comment defaults.
//  Same `DialogCard` / `DialogActionButton` chrome as `ErrorDialog` and the
//  locker dialogs — custom popups, not `.alert`, per this project's UI rule
//  (CLAUDE.md). The detail screen shows them over a dimmed backdrop.
//
//  `POST /api/reports` requires a reason, so the report confirmation is
//  also where it's picked ("신고" stays disabled until one is chosen).
//

import SwiftUI

struct CommentDeleteDialog: View {
    var titleKey: LocalizedStringResource = .commentDeleteConfirmTitle
    var messageKey: LocalizedStringResource = .commentDeleteConfirmMessage
    /// An extra line under the message, only when it applies — e.g. a
    /// post's "달린 댓글 3개도 함께 삭제돼요." (left out when it has none).
    var detailKey: LocalizedStringResource? = nil
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        DialogCard {
            Text(titleKey)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(messageKey)
                if let detailKey {
                    Text(detailKey)
                }
            }
            .font(.dialogBody).tracking(Tracking.dialogBody)
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, Spacing.xs)

            HStack(spacing: Spacing.xs) {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: .commonCancel, action: onCancel)
                DialogActionButton(titleKey: .commentDelete, style: .primary, action: onConfirm)
            }
        }
    }
}

struct CommentReportDialog: View {
    var titleKey: LocalizedStringResource = .commentReportConfirmTitle
    let onCancel: () -> Void
    let onConfirm: (ReportReason) -> Void

    @State private var reason: ReportReason?

    var body: some View {
        DialogCard {
            Text(titleKey)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            Text(.commentReportConfirmMessage)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textSecondary)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(ReportReason.allCases) { option in
                    reasonRow(option)
                }
            }
            .padding(.vertical, Spacing.xs)

            HStack(spacing: Spacing.xs) {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: .commonCancel, action: onCancel)
                DialogActionButton(titleKey: .commentReport, style: .primary) {
                    if let reason { onConfirm(reason) }
                }
                .disabled(reason == nil)
            }
        }
    }

    private func reasonRow(_ option: ReportReason) -> some View {
        let isSelected = reason == option
        return Button {
            reason = option
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.eventAccent : Color.gray400)
                Text(option.label)
                    .font(.dialogBody).tracking(Tracking.dialogBody)
                    .foregroundStyle(Color.textPrimary)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Last step of a report (comment or post): after a reason is picked,
/// "정말 신고할까요?" with the reason restated, since a report can't be
/// taken back.
struct ReportConfirmDialog: View {
    let reason: ReportReason
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        DialogCard {
            Text(.reportConfirmTitle)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(.reportConfirmReason(String(appLocalized: reason.label)))
                    .foregroundStyle(Color.textPrimary)
                Text(.reportConfirmMessage)
                    .foregroundStyle(Color.textSecondary)
            }
            .font(.dialogBody).tracking(Tracking.dialogBody)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, Spacing.xs)

            HStack(spacing: Spacing.xs) {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: .commonCancel, action: onCancel)
                DialogActionButton(titleKey: .commentReport, style: .primary, action: onConfirm)
            }
        }
    }
}

struct CommentEditDialog: View {
    @State private var text: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @FocusState private var isFocused: Bool

    init(initialText: String, onCancel: @escaping () -> Void, onSave: @escaping (String) -> Void) {
        _text = State(initialValue: initialText)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        DialogCard {
            Text(.commentEditTitle)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xs)

            TextField(String(appLocalized: .commentPlaceholder), text: $text, axis: .vertical)
                .lineLimit(3...8)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textPrimary)
                .focused($isFocused)
                .padding(Spacing.cardInset)
                .background {
                    RoundedRectangle(cornerRadius: Radius.inputField)
                        .fill(Color.surface)
                }
                .padding(.bottom, Spacing.xs)

            HStack(spacing: Spacing.xs) {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: .commonCancel, action: onCancel)
                DialogActionButton(titleKey: .commonSave, style: .primary) {
                    onSave(text)
                }
                .disabled(!canSave)
            }
        }
        .onAppear { isFocused = true }
    }
}

#Preview("삭제") {
    CommentDeleteDialog(onCancel: {}, onConfirm: {}).padding()
}

#Preview("신고") {
    CommentReportDialog(onCancel: {}, onConfirm: { _ in }).padding()
}

#Preview("신고 확인") {
    ReportConfirmDialog(reason: .abuse, onCancel: {}, onConfirm: {}).padding()
}

#Preview("수정") {
    CommentEditDialog(initialText: "수정할 댓글", onCancel: {}, onSave: { _ in }).padding()
}
