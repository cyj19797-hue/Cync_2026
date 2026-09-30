//
//  CalendarDayCell.swift
//  Cync
//
//  Created by 도하윤 on 8/31/26.
//
//  Figma node `I240:1678;44:3687;44:3492` ("date") — one day cell, 44pt
//  wide and exactly as tall as its content (28pt number + dot row),
//  so the grid's last row doesn't leave extra slack above the card's bottom
//  padding.
//
//  State styling follows the usual calendar convention so the most
//  prominent mark reads as "selected":
//  - selected day: filled `eventAccent` circle, white number
//  - today: `eventAccent` ring only (no fill), so it never competes with
//    the selection
//  - Sunday / public holiday red, Saturday blue; adjacent-month days gray
//  - one dot per category with events that day (category color, max 3);
//    a multi-day period is dotted only on its first and last day
//

import SwiftUI

struct CalendarDayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    let isToday: Bool
    var holiday: KoreanHoliday?
    /// Categories with an event this day, in display order.
    var eventCategories: [NoticeCategory] = []
    var eventCount = 0
    let action: () -> Void

    private static let maxDots = 3

    private var dayNumber: Int {
        Calendar.current.component(.day, from: day.date)
    }

    private var numberColor: Color {
        if isSelected { return .white }
        guard day.isWithinDisplayedMonth else { return .gray400 }
        if holiday != nil { return .calendarSunday }
        switch Calendar.current.component(.weekday, from: day.date) {
        case 1: return .calendarSunday
        case 7: return .calendarSaturday
        default: return .textPrimary
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Text(dayNumber, format: .number.grouping(.never))
                    .font(.calendarDayNumber).tracking(Tracking.calendarDayNumber)
                    .foregroundStyle(numberColor)
                    .frame(width: 28, height: 28)
                    .background {
                        if isSelected {
                            Circle().fill(Color.eventAccent)
                        } else if isToday {
                            Circle().strokeBorder(Color.eventAccent, lineWidth: 1.5)
                        }
                    }

                HStack(spacing: 2) {
                    ForEach(eventCategories.prefix(Self.maxDots), id: \.self) { category in
                        Circle()
                            .fill(category.accentColor)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(width: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityText))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityText: String {
        var parts = [day.date.formatted(.dateTime.month(.wide).day().weekday(.wide))]
        if isToday { parts.append(String(localized: .calendarToday)) }
        if let holiday { parts.append(String(localized: holiday.name)) }
        if eventCount > 0 { parts.append(String(localized: .calendarEventCount(eventCount))) }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    HStack {
        CalendarDayCell(day: CalendarDay(date: Date(), isWithinDisplayedMonth: true), isSelected: true, isToday: false, eventCategories: [.academic, .scholarship]) {}
        CalendarDayCell(day: CalendarDay(date: Date(), isWithinDisplayedMonth: true), isSelected: false, isToday: true, eventCategories: [.studentCouncil]) {}
        CalendarDayCell(day: CalendarDay(date: Date(), isWithinDisplayedMonth: false), isSelected: false, isToday: false) {}
    }
}
