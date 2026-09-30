//
//  CalendarMonthHeader.swift
//  test
//
//  Figma node `I240:1678;44:3686` ("month") — month navigation row, in
//  two layouts:
//  - `.centered` (CalendarView's month card, Figma's original): centered
//    "‹ 2026년 8월 ›" with the "오늘" pill as a trailing overlay, so showing
//    or hiding it never shifts the label.
//  - `.leading` (CalendarEventListView, iOS Calendar-style): month label on
//    the leading edge, and "‹ ›" — or "‹ 오늘 ›" when not on today —
//    grouped on the trailing edge.
//

import SwiftUI

struct CalendarMonthHeader: View {
    enum Style {
        case centered
        case leading
    }

    let month: Date
    var style: Style = .centered
    var showsTodayButton = false
    let onPrevious: () -> Void
    let onNext: () -> Void
    var onToday: () -> Void = {}

    var body: some View {
        Group {
            switch style {
            case .centered: centeredBody
            case .leading: leadingBody
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsTodayButton)
    }

    private var monthLabel: some View {
        Text(month.formatted(.dateTime.year().month(.wide)))
            .font(.calendarMonthLabel).tracking(Tracking.calendarMonthLabel)
            .foregroundStyle(Color.textPrimary)
    }

    private var todayButton: some View {
        Button(action: onToday) {
            Text(.calendarToday)
                .font(.calendarCaption).tracking(Tracking.calendarCaption)
                .foregroundStyle(Color.eventAccent)
                .padding(.horizontal, Spacing.xs + Spacing.xxs)
                .padding(.vertical, Spacing.xxs + 2)
                .overlay {
                    Capsule().strokeBorder(Color.eventAccent)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var centeredBody: some View {
        HStack(spacing: 0) {
            Button(action: onPrevious) {
                NavigationChevron(direction: .left, color: .textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.calendarPreviousMonth))

            monthLabel

            Button(action: onNext) {
                NavigationChevron(direction: .right, color: .textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.calendarNextMonth))
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if showsTodayButton {
                todayButton
                    .transition(.opacity)
            }
        }
    }

    private var leadingBody: some View {
        HStack(spacing: 0) {
            monthLabel

            Spacer(minLength: Spacing.xs)

            HStack(spacing: 0) {
                chevronButton(.left, label: .calendarPreviousMonth, action: onPrevious)

                if showsTodayButton {
                    todayButton
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                chevronButton(.right, label: .calendarNextMonth, action: onNext)
            }
            // The chevron glyph sits centered in its tap box; pull the group
            // out by that inset so the "›" glyph itself lines up with the
            // trailing edge of the content below.
            .padding(.trailing, -Self.chevronGlyphInset)
        }
    }

    /// Tap box width per chevron — narrow enough that "‹ ›" read as a pair
    /// when adjacent (44pt tall keeps the tap target comfortable).
    private static let chevronBoxWidth: CGFloat = 28
    /// Space between the box edge and the ~8pt-wide chevron glyph.
    private static let chevronGlyphInset: CGFloat = 10

    private func chevronButton(
        _ direction: NavigationChevron.Direction,
        label: LocalizedStringResource,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            NavigationChevron(direction: direction, color: .textPrimary)
                .frame(width: Self.chevronBoxWidth, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

#Preview {
    VStack {
        CalendarMonthHeader(month: Date(), showsTodayButton: true, onPrevious: {}, onNext: {})
        CalendarMonthHeader(month: Date(), style: .leading, showsTodayButton: true, onPrevious: {}, onNext: {})
        CalendarMonthHeader(month: Date(), style: .leading, onPrevious: {}, onNext: {})
    }
    .padding()
}
