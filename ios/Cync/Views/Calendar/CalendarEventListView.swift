//
//  CalendarEventListView.swift
//  test
//
//  Figma: "26 2 창학" file, frames `240:1928` ("3-1 일정 전체보기") and
//  `361:2520` ("3-2 일정 전체보기(일정 없음)") — the same screen, the second
//  being its empty state. The destination behind CalendarView's
//  "N월 전체 일정" link: every event in the displayed month, one card per
//  day (short date header + holiday name, then that day's rows). Cards are
//  sized to their content rather than stretched to the tab bar.
//
//  - Month can be changed right here (‹ › header row or horizontal swipe),
//    without going back to the grid.
//  - Days whose events have all ended are dimmed per element (header 0.7;
//    bar/title/meta 0.45; bookmark and holiday name untouched), in every
//    month — a fully past month shows dimmed throughout. On the current
//    month the list also scrolls to the first day still relevant today.
//  - Shares `CalendarViewModel` with CalendarView (passed in, not owned),
//    so the month, category filter and bookmark toggles stay in sync in
//    both directions.
//
//  The nav bar is `ScreenNavigationBar` (iOS-like centered Semibold
//  title, back chevron aligned with the filter chips),
//  not the system `NavigationStack` bar — this view is pushed via
//  `NavigationLink` from CalendarView, and `dismiss()` pops it.
//

import SwiftUI

struct CalendarEventListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var slideDirection: MonthSlideDirection = .forward

    /// Same forgiving threshold as CalendarView's grid swipe.
    private let swipeCommitThreshold: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .calendarMonthlyEvents, onBack: { dismiss() })

            CategoryFilterRow(selectedCategory: $viewModel.selectedCategory)
                .padding(.top, Spacing.xs)

            CalendarMonthHeader(
                month: viewModel.displayedMonth,
                style: .leading,
                showsTodayButton: !viewModel.isShowingCurrentMonth,
                onPrevious: { changeMonth(.backward) },
                onNext: { changeMonth(.forward) },
                onToday: goToToday
            )
            .padding(.horizontal, Spacing.md)

            monthContent
                .id(viewModel.displayedMonth)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: slideDirection.insertionEdge).combined(with: .opacity),
                        removal: .move(edge: slideDirection.removalEdge).combined(with: .opacity)
                    )
                )
                .frame(maxHeight: .infinity, alignment: .top)
                .clipped()
                .contentShape(Rectangle())
                .simultaneousGesture(monthSwipe)
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var monthContent: some View {
        let sections = viewModel.sectionsForDisplayedMonth
        if sections.isEmpty {
            EmptyScheduleView(message: viewModel.emptyMonthMessage)
                .modifier(CalendarCardSurface())
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(sections) { section in
                            dayCard(section)
                                .id(section.id)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.md)
                }
                .onAppear {
                    if let target = viewModel.firstUpcomingSectionID {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
        }
    }

    private static let dimmedHeaderOpacity = 0.7

    private func dayCard(_ section: CalendarDaySection) -> some View {
        let isDimmed = viewModel.isDimmed(section)
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(section.date.formatted(.calendarDay))
                    .font(.calendarSectionTitle).tracking(Tracking.calendarSectionTitle)
                    .foregroundStyle(Color.textPrimary)
                    .opacity(isDimmed ? Self.dimmedHeaderOpacity : 1)

                if let holiday = viewModel.holiday(on: section.date) {
                    Text(holiday.name)
                        .font(.calendarCaption).tracking(Tracking.calendarCaption)
                        .foregroundStyle(Color.calendarSunday)
                }
            }
            .padding(.bottom, Spacing.xs)

            Divider()
                .overlay(Color.borderLight)

            ForEach(section.events) { event in
                CalendarEventRow(
                    event: event,
                    showsCategory: viewModel.selectedCategory == .all,
                    isDimmed: isDimmed
                ) {
                    viewModel.toggleBookmark(for: event)
                }
            }
        }
        .modifier(CalendarCardSurface())
    }

    /// Horizontal-only swipe: ignored unless the drag is clearly sideways,
    /// so it never fights the list's vertical scroll.
    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > abs(value.translation.height) * 1.5 else { return }
                if dx < -swipeCommitThreshold {
                    changeMonth(.forward)
                } else if dx > swipeCommitThreshold {
                    changeMonth(.backward)
                }
            }
    }

    private func changeMonth(_ direction: MonthSlideDirection) {
        slideDirection = direction
        withAnimation(.easeInOut(duration: 0.28)) {
            switch direction {
            case .forward: viewModel.goToNextMonth()
            case .backward: viewModel.goToPreviousMonth()
            }
        }
    }

    private func goToToday() {
        slideDirection = Date() > viewModel.displayedMonth ? .forward : .backward
        withAnimation(.easeInOut(duration: 0.28)) {
            viewModel.goToToday()
        }
    }
}

#Preview("3-1 일정 있음") {
    NavigationStack {
        CalendarEventListView(viewModel: CalendarViewModel(events: CalendarEvent.mockList, referenceDate: CalendarEvent.mockReferenceDate))
    }
}

#Preview("3-2 일정 없음") {
    NavigationStack {
        // Any month with no mock events reproduces the empty-state frame.
        CalendarEventListView(viewModel: CalendarViewModel(events: [], referenceDate: CalendarEvent.mockReferenceDate))
    }
}
