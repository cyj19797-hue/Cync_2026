//
//  AdminLockerRow.swift
//  Cync
//
//  Figma component "관리자/사물함 행" (`689:3696`) — one line of the admin
//  locker list: a white card with a hairline border, title ("B201 · 012번")
//  and 학번 on the left, actions on the right.
//
//  `Kind` is the component's 상태 property — one enum, two variants:
//    - 승인 대기: title + 학번, 거부 / 승인.
//    - 사용 중: title + "사용중" badge, 학번, "비밀번호 •••• 보기 · 9월
//      10일부터 사용", and 반납. The password stays masked as a fixed
//      "••••" (never hinting at its length) until 보기 is tapped.
//
//  In selection mode (`isSelecting`) the actions give way to a leading
//  `CheckboxSquare` and the whole card toggles the selection.
//
//  Deviation from Figma: 승인 uses `accentStrong` instead of #36AFFF so the
//  white label clears 4.5:1 (same reason as the compose screen's 등록), and
//  both buttons share the 10pt corner (Figma has 10 / 7.5).
//

import SwiftUI

struct AdminLockerRow: View {
    enum Kind {
        case pending(onReject: () -> Void, onApprove: () -> Void)
        /// `sinceText` ("9월 10일부터 사용") is hidden along with its "·"
        /// when nil.
        case inUse(
            password: String?,
            isPasswordVisible: Bool,
            sinceText: String?,
            onTogglePassword: () -> Void,
            onReturn: () -> Void
        )
    }

    /// Masked password — fixed width whatever the real length.
    private static let passwordMask = "••••"

    let title: String
    let subtitle: String
    let kind: Kind
    /// A request is in flight — actions are disabled.
    var isProcessing = false
    var isSelecting = false
    var isSelected = false
    var onToggleSelection: () -> Void = {}

    var body: some View {
        if isSelecting {
            Button(action: onToggleSelection) {
                card
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            card
        }
    }

    private var card: some View {
        HStack(spacing: Spacing.cardInset) {
            if isSelecting {
                CheckboxSquare(isChecked: isSelected, style: .accent)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(.adminLockerRowTitle).tracking(Tracking.adminLockerRowTitle)
                        .foregroundStyle(Color.textPrimary)
                    if case .inUse = kind {
                        LockerStatusBadge.inUse
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                Text(subtitle)
                    .font(.adminLockerRowSubtitle).tracking(Tracking.adminLockerRowSubtitle)
                    .foregroundStyle(Color.textSecondary)
                if case let .inUse(password, isVisible, sinceText, onToggle, _) = kind {
                    passwordLine(password: password, isVisible: isVisible, sinceText: sinceText, onToggle: onToggle)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isSelecting {
                actions
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.listCardVertical)
        .background {
            RoundedRectangle(cornerRadius: Radius.listCard)
                .fill(Color.appBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.listCard)
                .strokeBorder(isSelected ? Color.eventAccent : Color.borderLight, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: Radius.listCard))
        .opacity(isProcessing ? 0.6 : 1)
        .animation(.easeOut(duration: 0.15), value: isProcessing)
    }

    @ViewBuilder
    private var actions: some View {
        switch kind {
        case let .pending(onReject, onApprove):
            HStack(spacing: Spacing.xs) {
                actionButton(.adminLockerReject, fill: .surface, label: .textPrimary, action: onReject)
                actionButton(.adminLockerApprove, fill: .accentStrong, label: .white, action: onApprove)
            }
            .disabled(isProcessing)
        case let .inUse(_, _, _, _, onReturn):
            actionButton(.adminLockerReturn, fill: .surface, label: .textPrimary, action: onReturn)
                .disabled(isProcessing)
        }
    }

    /// "비밀번호 •••• 보기 · 9월 10일부터 사용" (Figma `689:3689`, 6pt gaps).
    private func passwordLine(password: String?, isVisible: Bool, sinceText: String?, onToggle: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(.adminLockerPassword(isVisible ? (password ?? "-") : Self.passwordMask))
                .foregroundStyle(Color.textSecondary)
            Button(action: onToggle) {
                Text(isVisible ? .adminLockerPasswordHide : .adminLockerPasswordShow)
                    .font(.adminTextAction).tracking(Tracking.adminTextAction)
                    .foregroundStyle(Color.eventAccent)
                    // 44pt tall to tap without growing the line.
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -Spacing.cardInset)
            .accessibilityLabel(Text(isVisible ? .adminLockerPasswordHideAccessibility : .adminLockerPasswordShowAccessibility))
            if let sinceText {
                Text(verbatim: "·")
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityHidden(true)
                Text(sinceText)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .font(.adminLockerRowSubtitle).tracking(Tracking.adminLockerRowSubtitle)
    }

    private func actionButton(
        _ titleKey: LocalizedStringResource,
        fill: Color,
        label: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(titleKey)
                .font(.adminLockerRowAction).tracking(Tracking.adminLockerRowAction)
                .foregroundStyle(label)
                .padding(Spacing.compactButton)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(fill)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Spacing.cardInset) {
        AdminLockerRow(title: "B201 · 012번", subtitle: "학번 22011234", kind: .pending(onReject: {}, onApprove: {}))
        AdminLockerRow(title: "B202 · 061번", subtitle: "학번 24010021", kind: .pending(onReject: {}, onApprove: {}), isProcessing: true)
        AdminLockerRow(title: "B204 · 260번", subtitle: "학번 23015678", kind: .pending(onReject: {}, onApprove: {}), isSelecting: true, isSelected: true)
        AdminLockerRow(title: "B202 · 045번", subtitle: "학번 21019876", kind: .inUse(password: "4821", isPasswordVisible: false, sinceText: "9월 10일부터 사용", onTogglePassword: {}, onReturn: {}))
        AdminLockerRow(title: "B201 · 007번", subtitle: "학번 22014567", kind: .inUse(password: "4821", isPasswordVisible: true, sinceText: nil, onTogglePassword: {}, onReturn: {}))
    }
    .padding()
}
