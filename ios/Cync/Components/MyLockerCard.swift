//
//  MyLockerCard.swift
//  test
//
//  Figma component set `243:4541` ("내 사물함", the `243:4522` instance on
//  "4 사물함") — the summary card at the top of the locker screen. Its
//  `속성 1` variant property has 4 states, each mapped to a `CardState` case
//  here:
//    - `속성 1=신청`     (`243:4595`) → `.apply`             — no locker yet.
//      Beyond Figma (whose ">> 신청하러가기" read like a web link): built on
//      the same skeleton as the other states so switching between them
//      doesn't jolt — big line + right-side capsule, then one smaller line.
//      "아직 없어요" sits where "133번" goes, a filled "신청하기 ›" capsule
//      (same size and shape as the status badges) where the badge goes, and
//      a gray hint below. The whole card is the button (LockerView wraps it
//      in a NavigationLink with `MyLockerCardButtonStyle` for press
//      feedback).
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
//  states' pill fills aren't exact system-color matches: 승인 대기 uses the
//  map's 승인 대기 yellow (`Color.lockerPending`, #FFC542 — not Figma's
//  #FF8D28, so the card and the map cell match), 승인 완료
//  `lockerApprovedBadge` (#00C0E8).
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

    /// `속성 1=신청` — same rows as `lockerInfo`: "아직 없어요" + the
    /// "신청하기 ›" capsule, then a gray hint.
    private var applyContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                Text(.lockerMyLockerEmpty)
                    .font(.lockerNumberLarge).tracking(Tracking.lockerNumberLarge)
                    .lineLimit(1)

                Spacer(minLength: Spacing.xs)

                applyCapsule
            }

            Text(.lockerApplyHint)
                .font(.lockerPeriodText).tracking(Tracking.lockerPeriodText)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// Same padding, font and capsule as `LockerStatusBadge`, but filled
    /// (an action, not a status) with a chevron in place of the dot.
    private var applyCapsule: some View {
        HStack(spacing: Spacing.xxs) {
            Text(.lockerApplyCta)
                .font(.lockerStatusBadge).tracking(Tracking.lockerStatusBadge)
            Image(systemName: "chevron.right")
                .font(.navigationChevron)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, Spacing.cardInset)
        .padding(.vertical, Spacing.xs)
        .background {
            Capsule().fill(Color.buttonAccent)
        }
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

    private var statusBadge: some View {
        switch state {
        case .active: return LockerStatusBadge.inUse
        // Same yellow as a 승인 대기 cell on the map below, so the two read
        // as one state.
        case .pendingApproval: return LockerStatusBadge(dotColor: .lockerPending, labelKey: .lockerBadgePending)
        case .awaitingPassword: return LockerStatusBadge(dotColor: .lockerApprovedBadge, labelKey: .lockerBadgeApproved)
        case .apply: return LockerStatusBadge(dotColor: .clear, labelKey: "")
        }
    }
}

/// Press feedback for the 신청 card (it's one big button): a slight dim
/// and shrink, like a tapped list row.
struct MyLockerCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .fill(configuration.isPressed ? Color.surfaceSubtle : Color.appBackground)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
