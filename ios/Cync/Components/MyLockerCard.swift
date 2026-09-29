//
//  MyLockerCard.swift
//  test
//
//  Figma node `243:4522` ("내 사물함") — the summary card at the top of the
//  locker screen showing the current user's own locker number, status pill,
//  usage period, and a "비밀번호 찾기" link. Only rendered when the user has
//  an assigned locker (LockerView hides it entirely otherwise).
//
//  The status pill's fill (`rgba(52,199,89,0.3)`) is exactly Apple's
//  system green (#34C759), so it's mapped to `Color(.systemGreen)` instead
//  of a raw hex — see design-to-code guide §4.
//

import SwiftUI

struct MyLockerCard: View {
    let locker: Locker
    let onFindPassword: () -> Void

    /// `assignedAt`/`dueDate` are `"yyyy-MM-dd"` strings straight from
    /// `GET /api/lockers` (`docs/API.md` §4), not always present.
    private var periodText: String {
        let start = locker.assignedAt.flatMap(SpringDate.parseDay)?.formatted(.dateTime.year().month(.wide).day())
        let end = locker.dueDate.flatMap(SpringDate.parseDay)?.formatted(.dateTime.year().month(.wide).day())
        switch (start, end) {
        case let (start?, end?): return "\(start) ~ \(end)"
        case let (start?, nil): return start
        default: return "-"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("나의 사물함")
                .font(.myLockerTitle).tracking(Tracking.myLockerTitle)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("\(locker.lockerNumber)번")
                        .font(.lockerNumberLarge).tracking(Tracking.lockerNumberLarge)

                    Spacer(minLength: 0)

                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color(.systemGreen))
                            .frame(width: 8, height: 8)
                        Text("사용중")
                            .font(.lockerStatusBadge).tracking(Tracking.lockerStatusBadge)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background {
                        Capsule().fill(Color(.systemGreen).opacity(0.3))
                    }
                }

                Text("기간 : \(periodText)")
                    .font(.lockerPeriodText).tracking(Tracking.lockerPeriodText)

                HStack {
                    Spacer(minLength: 0)
                    Button(action: onFindPassword) {
                        Text("사물함 비밀번호 찾기")
                            .underline()
                    }
                    .font(.calendarCaption).tracking(Tracking.calendarCaption)
                    .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .foregroundStyle(Color.textPrimary)
        .padding(Spacing.md)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.gray300)
        }
    }
}

#Preview {
    MyLockerCard(locker: Locker.mockList[26]) {}
        .padding()
}
