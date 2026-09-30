//
//  EmptyScheduleView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `361:2520` ("3-2 일정 전체보기(일정 없음)"),
//  node `361:2533`/`361:2591` — the empty state shown inside "등록된 일정"
//  when the selected day/category combination has no events. Used both by
//  CalendarView's embedded schedule card and by the full-screen
//  CalendarEventListView, since both render the same "등록된 일정" content
//  at different sizes.
//

import SwiftUI

struct EmptyScheduleView: View {
    /// `.calendarEmpty` for a single day, `.calendarEmptyMonth` for the
    /// month-wide list.
    var message: LocalizedStringResource = .calendarEmpty

    var body: some View {
        Text(message)
            .font(.emptyStateMessage).tracking(Tracking.emptyStateMessage)
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Vertical only — the card (`CalendarCardSurface`) already sets
            // the horizontal inset, so the message lines up with its header.
            .padding(.vertical, Spacing.md)
    }
}

#Preview {
    EmptyScheduleView()
}
