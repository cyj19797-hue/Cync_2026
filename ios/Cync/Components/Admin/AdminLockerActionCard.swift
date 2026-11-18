//
//  AdminLockerActionCard.swift
//  Cync
//
//  Figma component "관리자/사물함 동작 카드" (`689:3779`) — the card that
//  rises from the bottom of the admin locker map when a cell is tapped.
//  One `State` per variant, each showing only what can be done:
//
//    승인 대기  info (학번, 비밀번호) + deposit hint  →  거부 / 승인
//    사용 중   info (학번, 비밀번호, 사용 시작)      →  닫기 / 반납 처리
//    빈 칸     hint                              →  닫기 / 고장 처리
//    고장      hint                              →  닫기 / 복구하기
//    정보 없음  "서버에 이 사물함 정보가 없어요."       →  닫기
//
//  Header: "006번 사물함" + status badge (`LockerStatusBadge` for 승인 대기 /
//  사용중, a small gray pill for 빈 칸 / 고장) + X, room underneath.
//  The password is shown as-is — the admin opened this cell on purpose.
//
//  The main action is `buttonAccent`, like the app's other filled buttons.
//  Deviation from Figma (same as the list rows): both buttons share the
//  10pt corner.
//

import SwiftUI

struct AdminLockerActionCard: View {
    enum State {
        case pending(studentId: String?, password: String?)
        case inUse(studentId: String?, password: String?, startDate: String?)
        case available
        case broken
        /// The number exists on the floor plan but not on the server.
        case unknown
    }

    /// "006" — 3 digits.
    let paddedNumber: String
    let zoneId: String
    let state: State
    /// A request is in flight — buttons are disabled.
    var isProcessing = false
    let onClose: () -> Void
    /// Left button for 승인 대기 (거부).
    var onSecondary: () -> Void = {}
    /// Right button (승인 / 반납 처리 / 고장 처리 / 복구하기).
    var onPrimary: () -> Void = {}

    private static let infoLabelWidth: CGFloat = 72
    private static let buttonHeight: CGFloat = 46
    private static let closeButtonSize: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            if let rows = infoRows {
                infoBox(rows)
            }

            if let hintKey {
                Text(hintKey)
                    .font(.adminCardBody).tracking(Tracking.adminCardBody)
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            actions
        }
        .padding(Spacing.md + Spacing.xxs)
        .background {
            RoundedRectangle(cornerRadius: Radius.actionCard)
                .fill(Color.appBackground)
                .shadow(color: Color.textPrimary.opacity(0.12), radius: 12, y: 8)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(.adminLockerCardTitle(paddedNumber))
                        .font(.adminCardTitle).tracking(Tracking.adminCardTitle)
                        .foregroundStyle(Color.textPrimary)
                    badge
                }
                Text(verbatim: zoneId)
                    .font(.adminCardBody).tracking(Tracking.adminCardBody)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.adminCardBody)
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: Self.closeButtonSize, height: Self.closeButtonSize)
                    .background(Circle().fill(Color.gray50))
                    // 44pt to tap without growing the header.
                    .padding((44 - Self.closeButtonSize) / 2)
                    .contentShape(Rectangle())
                    .padding(-(44 - Self.closeButtonSize) / 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.commonClose))
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch state {
        case .pending:
            LockerStatusBadge(dotColor: .lockerPendingBadge, labelKey: .adminLockerStatusPending)
                .foregroundStyle(Color.textPrimary)
        case .inUse:
            LockerStatusBadge.inUse
                .foregroundStyle(Color.textPrimary)
        case .available:
            pill(.adminLockerStatusAvailable)
        case .broken:
            pill(.adminLockerStatusBroken)
        case .unknown:
            EmptyView()
        }
    }

    /// Figma "상태 pill": `surface` capsule, 10×6pt, Medium 13 gray.
    private func pill(_ key: LocalizedStringResource) -> some View {
        Text(key)
            .font(.adminStatusPill).tracking(Tracking.adminStatusPill)
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, Spacing.compactButton)
            .padding(.vertical, Spacing.xxs + 2)
            .background(Capsule().fill(Color.surface))
    }

    // MARK: - Info

    private var infoRows: [(LocalizedStringResource, String)]? {
        switch state {
        case let .pending(studentId, password):
            return [
                (.adminLockerCardStudentId, studentId ?? "-"),
                (.adminLockerCardPassword, password ?? "-")
            ]
        case let .inUse(studentId, password, startDate):
            var rows: [(LocalizedStringResource, String)] = [
                (.adminLockerCardStudentId, studentId ?? "-"),
                (.adminLockerCardPassword, password ?? "-")
            ]
            if let startDate { rows.append((.adminLockerCardStartDate, startDate)) }
            return rows
        case .available, .broken, .unknown:
            return nil
        }
    }

    private func infoBox(_ rows: [(LocalizedStringResource, String)]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(rows[index].0)
                        .font(.adminCardBody).tracking(Tracking.adminCardBody)
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: Self.infoLabelWidth, alignment: .leading)
                    Text(verbatim: rows[index].1)
                        .font(.adminCardInfoValue).tracking(Tracking.adminCardInfoValue)
                        .foregroundStyle(Color.textPrimary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background {
            RoundedRectangle(cornerRadius: Radius.listCard)
                .fill(Color.gray50)
        }
    }

    private var hintKey: LocalizedStringResource? {
        switch state {
        case .pending: return .adminLockerCardPendingHint
        case .inUse: return nil
        case .available: return .adminLockerCardAvailableHint
        case .broken: return .adminLockerCardBrokenHint
        case .unknown: return .adminLockerCardUnknownHint
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: Spacing.cardInset) {
            switch state {
            case .pending:
                button(.adminLockerReject, isPrimary: false, action: onSecondary)
                button(.adminLockerApprove, isPrimary: true, action: onPrimary)
            case .inUse:
                button(.commonClose, isPrimary: false, isClose: true, action: onClose)
                button(.adminLockerReturnAction, isPrimary: true, action: onPrimary)
            case .available:
                button(.commonClose, isPrimary: false, isClose: true, action: onClose)
                button(.adminLockerMarkBroken, isPrimary: true, action: onPrimary)
            case .broken:
                button(.commonClose, isPrimary: false, isClose: true, action: onClose)
                button(.adminLockerRestore, isPrimary: true, action: onPrimary)
            case .unknown:
                button(.commonClose, isPrimary: false, isClose: true, action: onClose)
            }
        }
    }

    private func button(
        _ titleKey: LocalizedStringResource,
        isPrimary: Bool,
        isClose: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(titleKey)
                .font(.adminLockerRowAction).tracking(Tracking.adminLockerRowAction)
                .foregroundStyle(isPrimary ? Color.white : Color.textPrimary)
                .frame(maxWidth: .infinity, minHeight: Self.buttonHeight)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(isPrimary ? Color.buttonAccent : Color.surface)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // 닫기 always works; the rest wait for the request in flight.
        .disabled(isProcessing && !isClose)
        .opacity(isProcessing && isPrimary ? 0.6 : 1)
    }
}

#Preview("승인 대기") {
    AdminLockerActionCard(paddedNumber: "006", zoneId: "B201",
                          state: .pending(studentId: "22011234", password: "4821"), onClose: {})
        .padding()
}

#Preview("사용 중") {
    AdminLockerActionCard(paddedNumber: "045", zoneId: "B202",
                          state: .inUse(studentId: "21019876", password: "4821", startDate: "9월 10일"), onClose: {})
        .padding()
}

#Preview("빈 칸") {
    AdminLockerActionCard(paddedNumber: "002", zoneId: "B201", state: .available, onClose: {})
        .padding()
}

#Preview("고장") {
    AdminLockerActionCard(paddedNumber: "004", zoneId: "B201", state: .broken, onClose: {})
        .padding()
}

#Preview("정보 없음") {
    AdminLockerActionCard(paddedNumber: "451", zoneId: "B207(1)", state: .unknown, onClose: {})
        .padding()
}
