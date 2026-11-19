//
//  LockerStatusBadge.swift
//  Cync
//
//  Locker status pill — colored dot + bold label on a 30% tint of the same
//  color (Figma `243:4459`, "사용중"). Shared by "나의 사물함" (`MyLockerCard`)
//  and the admin locker list (`AdminLockerRow`).
//

import SwiftUI

struct LockerStatusBadge: View {
    let dotColor: Color
    let labelKey: LocalizedStringResource

    /// "사용중" (green).
    static let inUse = LockerStatusBadge(dotColor: .lockerInUseBadge, labelKey: .lockerStatusInUse)

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(labelKey)
                .font(.lockerStatusBadge).tracking(Tracking.lockerStatusBadge)
        }
        // Figma specs this badge's horizontal padding at its `spacing-sm`
        // token (12px) — `Spacing.cardInset`, not `Spacing.sm`, which is a
        // pre-existing 24px mismatch documented on `Spacing.sm` itself.
        .padding(.horizontal, Spacing.cardInset)
        .padding(.vertical, Spacing.xs)
        .background {
            Capsule().fill(dotColor.opacity(0.3))
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        LockerStatusBadge.inUse
        LockerStatusBadge(dotColor: .lockerPending, labelKey: .lockerBadgePending)
    }
    .padding()
}
