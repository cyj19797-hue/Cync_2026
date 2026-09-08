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
//  No UIKit anywhere on this screen (search reuses the existing
//  Components/SearchBar.swift). The month grid looks like it might want
//  `UICalendarView`, but that system component enforces its own selection
//  chrome and can't reproduce this design's specific selected-day pill +
//  per-day event dot, so a plain `LazyVGrid` of `CalendarDayCell` is both
//  simpler and the more faithful choice here — not a case that needs UIKit.
//

import SwiftUI

private let dayGridColumns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)

/// Which way the month grid should slide when `displayedMonth` changes —
/// driven by both the header's arrow buttons and the drag gesture below,
/// so both paths animate identically.
private enum MonthSlideDirection {
    case forward
    case backward

    var insertionEdge: Edge { self == .forward ? .trailing : .leading }
    var removalEdge: Edge { self == .forward ? .leading : .trailing }
}

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var isSearchPresented = false
    @State private var slideDirection: MonthSlideDirection = .forward
    @GestureState private var dragTranslation: CGFloat = 0

    /// Minimum horizontal drag distance before a swipe commits to changing
    /// the month, mirroring the iOS Calendar app's forgiving swipe zone.
    private let swipeCommitThreshold: CGFloat = 60

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar(title: "캘린더") {
                    Image(systemName: "calendar")
                } trailing: {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textPrimary)
                    }
                    .accessibilityLabel("검색")
                }

                ScrollView {
                    VStack(spacing: Spacing.xs) {
                        if isSearchPresented {
                            // UIKit UISearchBar — see Components/SearchBar.swift for why.
                            SearchBar(text: $viewModel.searchText, isActive: $isSearchPresented)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            CategoryFilterRow(selectedCategory: $viewModel.selectedCategory)
                                .transition(.opacity)
                        }

                        calendarCard
                        scheduleCard
                    }
                    .padding(.horizontal, Spacing.md)
                    .animation(.default, value: isSearchPresented)
                }
                .background(Color.appBackground)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.load()
            }
            .alert(
                "오류",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
                )
            ) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var calendarCard: some View {
        VStack(spacing: Spacing.xs) {
            CalendarMonthHeader(
                month: viewModel.displayedMonth,
                onPrevious: { changeMonth(.backward) },
                onNext: { changeMonth(.forward) }
            )

            CalendarWeekdayHeaderRow()

            Divider()
                .overlay(Color.borderLight)

            dayGrid
        }
        .padding(Spacing.md)
        .background(Color.calendarSurface)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.calendarCard)
                .strokeBorder(Color.borderLight)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.calendarCard))
    }

    /// The 7×(5-6) day grid, wrapped for month-to-month swipe: `.id(...)`
    /// forces SwiftUI to treat each month as a distinct view so the
    /// `.transition` below actually fires on month change, and the
    /// `DragGesture` both previews the swipe (finger-tracking offset) and
    /// commits it past `swipeCommitThreshold`. Button taps in
    /// `CalendarMonthHeader` reuse the exact same `changeMonth` path so
    /// swipe and tap animate identically.
    private var dayGrid: some View {
        LazyVGrid(columns: dayGridColumns, spacing: Spacing.xs) {
            ForEach(viewModel.visibleDays) { day in
                CalendarDayCell(
                    day: day,
                    isSelected: viewModel.isSelected(day.date),
                    isToday: viewModel.isToday(day.date),
                    hasEvent: viewModel.hasEvent(on: day.date)
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

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text("등록된 일정")
                    .font(.noticeTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(viewModel.selectedDate.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                    .font(.calendarCaption)
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)

                NavigationLink {
                    CalendarEventListView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 2) {
                        Text("전체 보기")
                            .font(.calendarCaption)
                            .foregroundStyle(Color.gray400)
                        NavigationChevron()
                    }
                }
            }
            .padding(.vertical, Spacing.xs)

            Divider()
                .overlay(Color.cardBorder)

            if viewModel.eventsForSelectedDate.isEmpty {
                EmptyScheduleView()
            } else {
                ForEach(viewModel.eventsForSelectedDate) { event in
                    CalendarEventRow(event: event) {
                        viewModel.toggleBookmark(for: event)
                    }
                }
            }
        }
        .padding(Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.cardBorder)
        }
    }
}

#Preview {
    CalendarView()
}
