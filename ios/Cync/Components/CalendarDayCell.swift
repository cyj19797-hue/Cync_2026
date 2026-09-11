//
//  CalendarDayCell.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//
//  Figma node `I240:1678;44:3687;44:3492` ("date") — one 44×44 day cell.
//  The selected day (`44:3372` in the mock, "10") gets a gray300 circle
//  behind the number; any day with a registered event gets a small dot
//  underneath (`Frame 75`/`Frame 76` in Figma — plain colored dots, not
//  bespoke art, so they're drawn as `Circle()` rather than image assets).
//
//  "Today" isn't a Figma-specced state (the mock only shows a selected
//  day), so it's approximated with an `eventAccent` ring around the number
//  — reusing an existing design-system color rather than introducing a new
//  one, and kept visually distinct from both the gray300 selection fill and
//  the accentRed event dot so all three states can be told apart at once.
//

import SwiftUI

struct CalendarDayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    let isToday: Bool
    let hasEvent: Bool
    let action: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: day.date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Text("\(dayNumber)")
                    .font(.calendarDayNumber).tracking(Tracking.calendarDayNumber)
                    .foregroundStyle(day.isWithinDisplayedMonth ? Color.textPrimary : Color.gray400)
                    .frame(width: 24, height: 24)
                    .background {
                        if isSelected {
                            Circle().fill(Color.gray300)
                        }
                    }
                    .background {
                        if isToday {
                            Circle().fill(Color.eventAccentLight)
                        }
                    }

                Circle()
                    .fill(hasEvent ? Color.accentRed : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        CalendarDayCell(day: CalendarDay(date: Date(), isWithinDisplayedMonth: true), isSelected: true, isToday: false, hasEvent: true) {}
        CalendarDayCell(day: CalendarDay(date: Date(), isWithinDisplayedMonth: true), isSelected: false, isToday: true, hasEvent: true) {}
        CalendarDayCell(day: CalendarDay(date: Date(), isWithinDisplayedMonth: false), isSelected: false, isToday: false, hasEvent: false) {}
    }
}
