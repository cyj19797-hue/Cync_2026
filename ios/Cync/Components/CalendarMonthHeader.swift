//
//  CalendarMonthHeader.swift
//  test
//
//  Figma node `I240:1678;44:3686` ("month") — "< 2026년 8월 >" month
//  navigation row at the top of the calendar card.
//

import SwiftUI

struct CalendarMonthHeader: View {
    let month: Date
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                NavigationChevron(direction: .left, color: .textPrimary)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)

            Spacer(minLength: 0)

            Text(month.formatted(.dateTime.year().month(.wide)))
                .font(.calendarMonthLabel)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)

            Button(action: onNext) {
                NavigationChevron(direction: .right, color: .textPrimary)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    CalendarMonthHeader(month: Date(), onPrevious: {}, onNext: {})
        .padding()
}
