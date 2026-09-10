//
//  CalendarEventListView.swift
//  test
//
//  Figma: "26 2 창학" file, frames `240:1928` ("3-1 일정 전체보기") and
//  `361:2520` ("3-2 일정 전체보기(일정 없음)") — the same screen, the second
//  being its empty state. This is the destination behind CalendarView's
//  "전체 보기" link — the same "등록된 일정" content as the calendar screen's
//  bottom card (selected date title + category filter + event rows), just
//  full-screen instead of cropped inside a small card. It shares
//  `CalendarViewModel` with CalendarView (passed in, not owned) so the
//  date/category filter and any bookmark toggle stay in sync between the
//  two screens; the empty state (`EmptyScheduleView`) shows automatically
//  whenever that filter has no matching events, no separate view needed.
//
//  Figma's back chevron + centered title (`240:3487`/`361:2593`) come from
//  `ScreenNavigationBar`, not the system `NavigationStack` bar — this view
//  is pushed via `NavigationLink` from CalendarView (which already owns
//  the NavigationStack), and `dismiss()` pops it same as a system back
//  button would.
//

import SwiftUI

struct CalendarEventListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: "일정 전체보기", onBack: { dismiss() })

            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.selectedDate.formatted(.dateTime.month(.wide).day().weekday(.wide).locale(Locale(identifier: "ko_KR"))))
                    .font(.noticeTitle)
                    .foregroundStyle(Color.textPrimary)
                    .padding(Spacing.xs)

                Divider()
                    .overlay(Color.borderLight)

                CategoryFilterRow(selectedCategory: $viewModel.selectedCategory)

                if viewModel.eventsForSelectedDate.isEmpty {
                    EmptyScheduleView()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.eventsForSelectedDate) { event in
                                CalendarEventRow(event: event) {
                                    viewModel.toggleBookmark(for: event)
                                }
                                .padding(.horizontal, Spacing.xxs)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.xs)
            .frame(maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .strokeBorder(Color.borderLight)
            }
            .padding(Spacing.md)
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("3-1 일정 있음") {
    NavigationStack {
        CalendarEventListView(viewModel: CalendarViewModel())
    }
}

#Preview("3-2 일정 없음") {
    NavigationStack {
        // Any date with no mock events reproduces the empty-state frame.
        CalendarEventListView(viewModel: CalendarViewModel(events: [], referenceDate: CalendarEvent.mockReferenceDate))
    }
}
