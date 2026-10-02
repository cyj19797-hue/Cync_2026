//
//  MyLockerCard.swift
//  test
//
//  Figma component set `243:4541` ("내 사물함", the `243:4522` instance on
//  "4 사물함") — the summary card at the top of the locker screen. Its
//  `속성 1` variant property has 4 states, each mapped to a `CardState` case
//  here:
//    - `속성 1=신청`     (`243:4595`) → `.apply`             — no locker yet.
//    - `속성 1=승인대기` (`243:4542`) → `.pendingApproval`   — `status == .pending`
//      (`docs/API.md` §4: apply moves a locker to `PENDING` until an admin
//      approves it).
//    - `속성 1=베리언트4` (`243:4765`) → `.awaitingPassword` — approved but
//      `password` hasn't come back yet; register one before using the badge.
//    - `속성 1=기본`     (`243:4521`) → `.active`            — normal in-use
//      card with the "비밀번호 찾기" link. (Figma's "기간" line was dropped:
//      the server no longer sends `dueDate`, so it only ever showed "-".)
//
//  The status pill's fill for `.active` (`rgba(52,199,89,0.3)`) is exactly
//  Apple's system green (#34C759), so it's mapped to `Color(.systemGreen)`
//  instead of a raw hex — see design-to-code guide §4. The other two
//  states' pill fills (`#FF8D28`, `#00C0E8`) aren't exact system-color
//  matches, so those are `Color.lockerPendingBadge`/`lockerApprovedBadge`.
//
//  `LockerView` renders `.apply` inside its own `NavigationLink` (tapping
//  the whole card opens the apply flow); the other three states aren't
//  tappable as a whole card, only their inner "비밀번호 찾기"/"비밀번호 등록"
//  links are.
//
//  Padding pulled straight from `243:4541` via the Figma MCP: the outer
//  card's own `p-16`/title-block `p-4` and the status pill's `px-12/py-8`
//  are `Spacing.md`/`Spacing.xxs`/`Spacing.cardInset`+`Spacing.xs` below —
//  note the pill specifically needs `Spacing.cardInset` (12px), not
//  `Spacing.sm`, despite `Spacing.sm` documenting itself as Figma's
//  `spacing-sm` (12px) token: it's actually pinned to 24px (see that
//  token's own header comment), so using it here would double the pill's
//  intended horizontal padding.
//

import SwiftUI

struct MyLockerCard: View {
    let locker: Locker?
    /// Room of `locker` ("B201") — shown small and light gray after the big
    /// "3번" so the card links to the map below. `nil` shows just "3번".
    var zoneId: String?
    var onFindPassword: () -> Void = {}
    var onRegisterPassword: () -> Void = {}

    private enum CardState {
        case apply
        case pendingApproval(Locker)
        case awaitingPassword(Locker)
        case active(Locker)
    }

    private var state: CardState {
        guard let locker else { return .apply }
        if locker.status == .pending { return .pendingApproval(locker) }
        return locker.password == nil ? .awaitingPassword(locker) : .active(locker)
    }

    var body: some View {
        // Title → locker number a bit roomier than before (`md` + `xxs`).
        VStack(spacing: Spacing.md + Spacing.xxs) {
            // No extra inset of its own — the title shares the left edge
            // with the locker number below.
            Text(.lockerMyLockerTitle)
                .font(.myLockerTitle).tracking(Tracking.myLockerTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch state {
            case .apply:
                applyContent
            case let .pendingApproval(locker), let .awaitingPassword(locker), let .active(locker):
                lockerInfo(for: locker)
            }
        }
        .foregroundStyle(Color.textPrimary)
        // Same roomier inner padding as LockerView's map card.
        .padding(Spacing.sm)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.gray300)
        }
    }

    /// `속성 1=신청` — just a big "신청하러가기" prompt, no locker number/badge.
    private var applyContent: some View {
        Text(.lockerApplyLink)
            .font(.lockerNumberLarge).tracking(Tracking.lockerNumberLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func lockerInfo(for locker: Locker) -> some View {
        // Badge row → "비밀번호 찾기" gets `Spacing.sm` so the two right-edge
        // items don't crowd each other.
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                // Big locker number first, then the room ("B201") small and
                // light gray after it — the number is what reads first.
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(.lockerNumber("\(locker.lockerNumber)"))
                        .font(.lockerNumberLarge).tracking(Tracking.lockerNumberLarge)
                    if let zoneId {
                        Text(verbatim: zoneId)
                            .font(.lockerRoomLabel).tracking(Tracking.lockerRoomLabel)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)

                statusBadge
            }

            switch state {
            case .active:
                HStack {
                    Spacer(minLength: 0)
                    Button(action: onFindPassword) {
                        Text(.lockerFindPassword)
                            .underline()
                    }
                    .font(.calendarCaption).tracking(Tracking.calendarCaption)
                    .foregroundStyle(Color.textSecondary)
                }

            case .pendingApproval:
                Text(.lockerAppliedNotice)
                    .font(.lockerPeriodText).tracking(Tracking.lockerPeriodText)

            case .awaitingPassword:
                Button(action: onRegisterPassword) {
                    Text(.lockerRegisterPassword)
                        .underline()
                }
                .font(.lockerPeriodText).tracking(Tracking.lockerPeriodText)
                .foregroundStyle(Color.textPrimary)

            case .apply:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let (dotColor, label): (Color, LocalizedStringResource) = {
            switch state {
            case .active: return (Color(.systemGreen), .lockerStatusInUse)
            case .pendingApproval: return (Color.lockerPendingBadge, .lockerBadgePending)
            case .awaitingPassword: return (Color.lockerApprovedBadge, .lockerBadgeApproved)
            case .apply: return (.clear, "")
            }
        }()

        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(label)
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

#Preview("사용중") {
    MyLockerCard(locker: Locker.mockList[26], onRegisterPassword:  {})
        .padding()
}

#Preview("승인 대기") {
    var locker = Locker.mockList[26]
    locker.status = .pending
    return MyLockerCard(locker: locker)
        .padding()
}

#Preview("승인 완료 (비밀번호 등록)") {
    var locker = Locker.mockList[26]
    locker.password = nil
    return MyLockerCard(locker: locker)
        .padding()
}

#Preview("신청하러가기") {
    MyLockerCard(locker: nil)
        .padding()
}
