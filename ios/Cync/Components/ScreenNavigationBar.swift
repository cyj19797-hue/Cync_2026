//
//  ScreenNavigationBar.swift
//  Cync
//
//  Custom back button + title bar (e.g. "6-1 알림 설정" frame) for pushed
//  screens, instead of the system `NavigationStack` bar — as of iOS 26 the
//  system bar (and any button placed in it via `ToolbarItem`) renders with
//  the translucent "Liquid Glass" material, which this project's UI rule
//  (CLAUDE.md) avoids in favor of the design system's own look. Callers
//  pair this with `.toolbar(.hidden, for: .navigationBar)` to suppress the
//  real bar underneath. The leading icon reuses `NavigationChevron` rather
//  than the empty icon-instance placeholder Figma's export left behind.
//

import SwiftUI

struct ScreenNavigationBar<Trailing: View>: View {
    enum Style {
        /// Title right after the back button, Medium 15 (the original look).
        case standard
        /// iOS-style: title centered, Semibold 17, and the back chevron
        /// pinned to the leading edge so it lines up with content below
        /// (e.g. filter chips) instead of sitting centered in its 44pt box.
        case centered
    }

    /// `nil` shows the back button alone (e.g. community post detail).
    let titleKey: LocalizedStringResource?
    var style: Style = .standard
    let onBack: () -> Void
    private let trailing: Trailing

    /// `trailing` defaults to nothing — most pushed screens only need the
    /// back button + title, but a few (e.g. a "완료" submit button, a "이동"
    /// zone menu) need a slot on the right that isn't a system
    /// `ToolbarItem` — putting it there is exactly what triggers iOS 26's
    /// Liquid Glass button chrome, which this component exists to avoid.
    init(
        titleKey: LocalizedStringResource?,
        style: Style = .standard,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.titleKey = titleKey
        self.style = style
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        switch style {
        case .standard: standardBody
        case .centered: centeredBody
        }
    }

    private var centeredBody: some View {
        ZStack {
            if let titleKey {
                Text(titleKey)
                    .font(.screenNavTitleCentered).tracking(Tracking.screenNavTitleCentered)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 44)
            }

            HStack(spacing: 0) {
                Button(action: onBack) {
                    NavigationChevron(direction: .left, color: .textPrimary)
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.commonBack))

                Spacer(minLength: 0)

                trailing
            }
        }
        .frame(height: 44)
        .padding(.vertical, Spacing.xxs)
        .padding(.horizontal, Spacing.md)
        .background(Color.appBackground)
    }

    private var standardBody: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                NavigationChevron(direction: .left, color: .textPrimary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .padding(Spacing.xs)
            .frame(width: 44, height: 44)
            .accessibilityLabel(Text(.commonBack))

            if let titleKey {
                Text(titleKey)
                    .font(.screenNavTitle).tracking(Tracking.screenNavTitle)
                    .foregroundStyle(Color.textPrimary)
                    .padding(Spacing.xs)
                    .frame(height: 44)
            }

            Spacer(minLength: 0)

            trailing
        }
        .padding(.vertical, Spacing.xxs)
        .padding(.horizontal, Spacing.md)
        .background(Color.appBackground)
    }
}

#Preview {
    ScreenNavigationBar(titleKey: "알림 설정", onBack: {})
}

#Preview("trailing 슬롯") {
    ScreenNavigationBar(titleKey: "글쓰기", onBack: {}) {
        Text("완료")
            .font(.categoryChip).tracking(Tracking.categoryChip)
            .foregroundStyle(Color.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: Radius.chipSelected)
                    .fill(Color.brandPrimary)
            }
    }
}
