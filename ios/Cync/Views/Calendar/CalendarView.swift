//
//  CalendarView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `44:424` ("3 캘린더").
//  Top bar (`240:1675`, shared layout with NoticeListView's) + category
//  filter (`240:1677`, now `CategoryFilterRow`) + month grid (`240:1678`) +
//  "등록된 일정" card (`240:1679`). The bottom tab bar (`240:1690`) is not
//  built here — it's RootTabView's `TabView`, this is just its "캘린더" tab
//  content.
//
//  No UIKit anywhere on this screen, and no search (unlike 공지사항 /
//  커뮤니티 — events are found by month and category). The month grid looks like it might want
//  `UICalendarView`, but that system component enforces its own selection
//  chrome and can't reproduce this design's specific selected-day pill +
//  per-day event dot, so a plain `LazyVGrid` of `CalendarDayCell` is both
//  simpler and the more faithful choice here — not a case that needs UIKit.
//

import SwiftUI

private let dayGridColumns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)

/// Which way month content should slide when `displayedMonth` changes —
/// driven by the header's arrow buttons and the drag gestures, on both
/// CalendarView and CalendarEventListView, so every path animates the same.
enum MonthSlideDirection {
    case forward
    case backward

    var insertionEdge: Edge { self == .forward ? .trailing : .leading }
    var removalEdge: Edge { self == .forward ? .leading : .trailing }
}

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var slideDirection: MonthSlideDirection = .forward
    @GestureState private var dragTranslation: CGFloat = 0

    /// Minimum horizontal drag distance before a swipe commits to changing
    /// the month, mirroring the iOS Calendar app's forgiving swipe zone.
    private let swipeCommitThreshold: CGFloat = 60

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // No search here — the calendar is browsed by month and
                // category instead.
                // Labeled `leading:` — a lone trailing closure would land in
                // the `trailing` slot (the icon showed on the right).
                AppTopBar(title: .tabCalendar, leading: {
                    Image(systemName: "calendar")
                })

                // Same placement as NoticeListView's filter row — pinned
                // under the top bar (outside the ScrollView) — so the chips
                // don't jump when switching between the 공지사항 and 캘린더
                // tabs. The row pads its chips by `Spacing.xs` itself.
                CategoryFilterRow(selectedCategory: $viewModel.selectedCategory)
                    .padding(.top, Spacing.screenContentTop - Spacing.xs)

                ScrollView {
                    // Every visible gap is `Spacing.md`: filter → calendar
                    // card is the row's own `Spacing.xs` bottom padding + this
                    // stack's `Spacing.xs` top padding, card → card is the
                    // stack spacing.
                    VStack(spacing: Spacing.md) {
                        calendarCard
                        scheduleCard
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.md)
                }
            }
            .background(Color.appBackground)
            .toolbar(.hidden, for: .navigationBar)
            // Main tab screen — the bottom tab bar shows only while this
            // root is on screen (see TabBarVisibility.swift).
            .showsTabBar()
            .task {
                await viewModel.load()
            }
            .alert(
                Text(.commonError),
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
                )
            ) {
                Button(.commonOk, role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var calendarCard: some View {
        VStack(spacing: Spacing.xs) {
            CalendarMonthHeader(
                month: viewModel.displayedMonth,
                showsTodayButton: !viewModel.isShowingToday,
                onPrevious: { changeMonth(.backward) },
                onNext: { changeMonth(.forward) },
                onToday: goToToday
            )

            CalendarWeekdayHeaderRow()

            Divider()
                .overlay(Color.borderLight)

            dayGrid
        }
        .modifier(CalendarCardSurface())
    }

    /// The 7×(5-6) day grid, wrapped for month-to-month swipe: `.id(...)`
    /// forces SwiftUI to treat each month as a distinct view so the
    /// `.transition` below actually fires on month change, and the
    /// `DragGesture` both previews the swipe (finger-tracking offset) and
    /// commits it past `swipeCommitThreshold`. Button taps in
    /// `CalendarMonthHeader` reuse the exact same `changeMonth` path so
    /// swipe and tap animate identically.
    private var dayGrid: some View {
        // Row spacing `Spacing.md`: cells are only as tall as their content
        // (number + dot row, see CalendarDayCell), so this sets the week rows'
        // breathing room — 36pt cell + 16pt gap = 52pt per row.
        LazyVGrid(columns: dayGridColumns, spacing: Spacing.md) {
            ForEach(viewModel.visibleDays) { day in
                CalendarDayCell(
                    day: day,
                    isSelected: viewModel.isSelected(day.date),
                    isToday: viewModel.isToday(day.date),
                    holiday: viewModel.holiday(on: day.date),
                    eventCategories: viewModel.eventCategories(on: day.date),
                    eventCount: viewModel.eventCount(on: day.date)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectDay(day)
                    }
                }
            }
        }
        .id(viewModel.displayedMonth)
        .transition(
            .asymmetric(
                insertion: .move(edge: slideDirection.insertionEdge).combined(with: .opacity),
                removal: .move(edge: slideDirection.removalEdge).combined(with: .opacity)
            )
        )
        .offset(x: dragTranslation)
        .gesture(
            DragGesture(minimumDistance: 20)
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    if value.translation.width < -swipeCommitThreshold {
                        changeMonth(.forward)
                    } else if value.translation.width > swipeCommitThreshold {
                        changeMonth(.backward)
                    }
                }
        )
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

    /// "오늘" pill — slides the grid toward today's month (no slide when
    /// it's already showing) and selects today.
    private func goToToday() {
        slideDirection = Date() > viewModel.displayedMonth ? .forward : .backward
        withAnimation(.easeInOut(duration: 0.28)) {
            viewModel.goToToday()
        }
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(.calendarScheduled)
                    .font(.calendarSectionTitle).tracking(Tracking.calendarSectionTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(viewModel.selectedDate.formatted(.calendarDay))
                    .font(.calendarSectionSubtitle).tracking(Tracking.calendarSectionSubtitle)
                    .foregroundStyle(Color.textSecondary)

                if let holiday = viewModel.holiday(on: viewModel.selectedDate) {
                    Text(holiday.name)
                        .font(.calendarSectionSubtitle).tracking(Tracking.calendarSectionSubtitle)
                        .foregroundStyle(Color.calendarSunday)
                }

                Spacer(minLength: 0)

                NavigationLink {
                    CalendarEventListView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 2) {
                        Text(.calendarViewMonth(viewModel.displayedMonth.formatted(.dateTime.month(.wide).locale(AppLanguage.currentLocale))))
                            .font(.calendarCaption).tracking(Tracking.calendarCaption)
                            .foregroundStyle(Color.gray400)
                        NavigationChevron()
                    }
                }
            }
            .lineLimit(1)
            .padding(.bottom, Spacing.xs)

            Divider()
                .overlay(Color.borderLight)

            if viewModel.eventsForSelectedDate.isEmpty {
                EmptyScheduleView(message: viewModel.emptyDayMessage)
            } else {
                ForEach(viewModel.eventsForSelectedDate) { event in
                    CalendarEventRow(event: event, showsCategory: viewModel.selectedCategory == .all) {
                        viewModel.toggleBookmark(for: event)
                    }
                }
            }
        }
        .modifier(CalendarCardSurface())
    }
}

/// Shared card style for the month grid card, the "등록된 일정" card and the
/// full-screen month list — same `Spacing.md` inner padding, white fill,
/// `borderLight` hairline and radius — so stacked cards line up and read as
/// one system. Cards shouldn't add their own outer padding on top of this.
struct CalendarCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: Radius.scheduleCard))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .strokeBorder(Color.borderLight)
            }
    }
}

#Preview {
    CalendarView()
        .environmentObject(TabBarVisibility())
}
