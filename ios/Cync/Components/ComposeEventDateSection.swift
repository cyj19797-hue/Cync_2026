//
//  ComposeEventDateSection.swift
//  Cync
//
//  The 행사 날짜 section on the 학생회 공지 compose screen, between the
//  title divider and the 사진 첨부 row (`PostComposeView`, when the mode has
//  `PostComposeConfiguration.eventDate`).
//
//  - No date: one 44pt row, calendar icon + "행사 날짜 추가" in gray, like
//    the 사진 첨부 row under it.
//  - With a date: 시작일 row (date on the right, blue while its calendar is
//    open), "기간으로 설정" switch, 마감일 row when the switch is on, and a
//    "날짜 지우기" text button. Tapping a date row folds its
//    `EventDatePickerCalendar` out under it — one at a time.
//  - Opening/closing animates briefly; with Reduce Motion it just switches.
//
//  State lives in `PostComposeViewModel`; this view only draws it and
//  reports taps.
//

import SwiftUI

struct ComposeEventDateSection: View {
    let selection: EventDateSelection?
    let expandedField: EventDateField?
    let onAdd: () -> Void
    let onClear: () -> Void
    let onToggleCalendar: (EventDateField) -> Void
    let onSetRange: (Bool) -> Void
    let onSelect: (Date, EventDateField) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The icon column, so labels in rows without an icon line up.
    private static let iconWidth: CGFloat = 20
    static let calendarScrollID = "composeEventDateCalendar"

    var body: some View {
        Group {
            if let selection {
                filledBody(selection)
            } else {
                addRow
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.borderLight)
        }
    }

    private func animated(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2), change)
    }

    // MARK: - No date

    private var addRow: some View {
        Button {
            animated(onAdd)
        } label: {
            HStack(spacing: Spacing.xs) {
                icon
                Text(.noticeEventDateAdd)
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
            }
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var icon: some View {
        Image(systemName: "calendar")
            .font(.categoryBadge)
            .frame(width: Self.iconWidth)
    }

    // MARK: - With a date

    private func filledBody(_ selection: EventDateSelection) -> some View {
        VStack(spacing: 0) {
            dateRow(.start, date: selection.start, showsIcon: true)
            if expandedField == .start {
                calendarCard(selection, field: .start)
            }

            Toggle(isOn: Binding(
                get: { selection.isRange },
                set: { isOn in animated { onSetRange(isOn) } }
            )) {
                Text(.noticeEventDateIsRange)
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(Color.textPrimary)
            }
            .toggleStyle(AppSwitchToggleStyle())
            .frame(minHeight: 44)
            .padding(.leading, Self.iconWidth + Spacing.xs)

            if let end = selection.end {
                dateRow(.end, date: end, showsIcon: false)
                if expandedField == .end {
                    calendarCard(selection, field: .end)
                }
            }

            clearButton
        }
    }

    private func dateRow(_ field: EventDateField, date: Date, showsIcon: Bool) -> some View {
        let isOpen = expandedField == field
        return Button {
            animated { onToggleCalendar(field) }
        } label: {
            HStack(spacing: Spacing.xs) {
                if showsIcon {
                    icon.foregroundStyle(Color.textSecondary)
                } else {
                    Color.clear.frame(width: Self.iconWidth, height: 1)
                }
                Text(field == .start ? .noticeEventDateStart : .noticeEventDateEnd)
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(Color.textPrimary)
                Spacer(minLength: Spacing.xs)
                Text(verbatim: EventDateFormat.displayString(from: date))
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(isOpen ? Color.eventAccent : Color.textPrimary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }

    private func calendarCard(_ selection: EventDateSelection, field: EventDateField) -> some View {
        EventDatePickerCalendar(selection: selection, field: field) { date in
            animated { onSelect(date, field) }
        }
        .padding(.bottom, Spacing.xs)
        .id(Self.calendarScrollID)
        .transition(.opacity)
    }

    private var clearButton: some View {
        Button {
            animated(onClear)
        } label: {
            Text(.noticeEventDateClear)
                .font(.noticeDate).tracking(Tracking.noticeDate)
                .foregroundStyle(Color.textSecondary)
                .underline()
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

#Preview("날짜 없음 / 하루 / 기간") {
    let today = Calendar.current.startOfDay(for: Date())
    let end = Calendar.current.date(byAdding: .day, value: 3, to: today)!
    return ScrollView {
        VStack(spacing: Spacing.md) {
            ComposeEventDateSection(selection: nil, expandedField: nil, onAdd: {}, onClear: {}, onToggleCalendar: { _ in }, onSetRange: { _ in }, onSelect: { _, _ in })
            ComposeEventDateSection(selection: EventDateSelection(start: today), expandedField: nil, onAdd: {}, onClear: {}, onToggleCalendar: { _ in }, onSetRange: { _ in }, onSelect: { _, _ in })
            ComposeEventDateSection(selection: EventDateSelection(start: today, end: end), expandedField: .end, onAdd: {}, onClear: {}, onToggleCalendar: { _ in }, onSetRange: { _ in }, onSelect: { _, _ in })
        }
    }
}
