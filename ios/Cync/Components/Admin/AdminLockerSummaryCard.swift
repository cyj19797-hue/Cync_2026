//
//  AdminLockerSummaryCard.swift
//  Cync
//
//  "관리자 - 사물함 관리" summary (Figma `690:3706`): 승인 대기 / 사용 중 /
//  빈 칸 / 고장 counts in four equal columns on a `gray50` card. Only the
//  승인 대기 number is orange (`lockerPendingBadge`) — it's the one the
//  admin acts on.
//

import SwiftUI

struct AdminLockerSummaryCard: View {
    let summary: AdminLockerSummary

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            item(summary.pending, .adminLockerStatusPending, highlighted: true)
            item(summary.inUse, .adminLockerStatusInUse)
            item(summary.available, .adminLockerStatusAvailable)
            item(summary.broken, .adminLockerStatusBroken)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.cardInset)
        .background {
            RoundedRectangle(cornerRadius: Radius.listCard)
                .fill(Color.gray50)
        }
    }

    private func item(_ value: Int, _ labelKey: LocalizedStringResource, highlighted: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number.locale(AppLanguage.currentLocale))
                .font(.adminSummaryValue).tracking(Tracking.adminSummaryValue)
                .foregroundStyle(highlighted ? Color.lockerPendingBadge : Color.textPrimary)
            Text(labelKey)
                .font(.adminSummaryLabel).tracking(Tracking.adminSummaryLabel)
                .foregroundStyle(Color.textSecondary)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AdminLockerSummaryCard(summary: AdminLockerSummary(lockers: AdminLockerManageViewModel.previewLockers))
        .padding()
}
