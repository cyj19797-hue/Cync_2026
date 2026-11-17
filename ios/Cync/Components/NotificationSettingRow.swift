//
//  NotificationSettingRow.swift
//  test
//
//  Figma node `361:2308` etc. ("설정명") — a row on "6-1 알림 설정" and its
//  sub-screens: a 17pt label with an optional 14pt description under it
//  (`textSecondary`), ending in either a switch (`isOn`) or a current
//  value + chevron that opens a sub-screen (`value` + `onNavigate`).
//  `isProminent` gives the label the 18pt Bold of a section title (전체
//  알림); `indent` pushes a row under a section title in by one step, like
//  a paragraph indent (its divider starts there too).
//
//  Both kinds share one layout: at least 56pt tall, 14pt top/bottom
//  padding, 4pt between label and description, 16pt from the right screen edge — so the switch's and the
//  chevron's right edges line up with the divider's. The whole row is the
//  tap target. Disabled rows fade to 40%.
//

import SwiftUI

struct NotificationSettingRow: View {
    let titleKey: LocalizedStringResource
    var subtitleKey: LocalizedStringResource?
    var isOn: Binding<Bool>?
    var value: String?
    var onNavigate: (() -> Void)?
    var isProminent = false
    var indent: CGFloat = 0

    static let minHeight: CGFloat = 56
    /// Space above and below the labels.
    static let verticalPadding: CGFloat = 14
    /// One step in, for rows under a section title.
    static let sectionIndent: CGFloat = Spacing.md

    @Environment(\.isEnabled) private var isEnabled

    /// Switch row.
    init(
        titleKey: LocalizedStringResource,
        subtitleKey: LocalizedStringResource? = nil,
        isOn: Binding<Bool>,
        isProminent: Bool = false,
        indent: CGFloat = 0
    ) {
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.isOn = isOn
        self.isProminent = isProminent
        self.indent = indent
    }

    /// Row that opens a sub-screen, showing its current `value`.
    init(
        titleKey: LocalizedStringResource,
        subtitleKey: LocalizedStringResource? = nil,
        value: String?,
        indent: CGFloat = 0,
        onNavigate: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.value = value
        self.indent = indent
        self.onNavigate = onNavigate
    }

    var body: some View {
        Group {
            if let isOn {
                Toggle(isOn: isOn) { labels }
                    .toggleStyle(AppSwitchToggleStyle())
            } else if let onNavigate {
                Button(action: onNavigate) {
                    HStack(spacing: Spacing.xs) {
                        labels
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let value {
                            Text(value)
                                .font(.settingRowSubtitle).tracking(Tracking.settingRowSubtitle)
                                .foregroundStyle(Color.textSecondary)
                        }
                        NavigationChevron()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isEnabled ? 1 : 0.4)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, Self.verticalPadding)
        .frame(minHeight: Self.minHeight)
        .listRowInsets(EdgeInsets(top: 0, leading: Spacing.screenHorizontal + indent, bottom: 0, trailing: Spacing.screenHorizontal))
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(titleKey)
                .font(isProminent ? .settingSectionTitle : .settingRowTitle)
                .tracking(isProminent ? Tracking.settingSectionTitle : Tracking.settingRowTitle)
                .foregroundStyle(Color.textPrimary)
            if let subtitleKey {
                Text(subtitleKey)
                    .font(.settingRowSubtitle).tracking(Tracking.settingRowSubtitle)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var isOn = true
        var body: some View {
            List {
                NotificationSettingRow(titleKey: "마감 임박 알림", subtitleKey: "마감 하루 전에 알려줘요", isOn: $isOn)
                NotificationSettingRow(titleKey: "새 공지 알림", subtitleKey: "새 공지가 올라오면 알려줘요", value: "전체", onNavigate: {})
            }
            .listStyle(.plain)
        }
    }
    return PreviewHost()
}
