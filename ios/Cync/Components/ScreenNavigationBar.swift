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
//  One layout for every pushed screen: title centered (Semibold 17, like
//  iOS), back chevron pinned to the leading edge so it lines up with the
//  content below. There used to be a second, left-aligned "title next to
//  the back button" style; screens mixed the two, so it was removed.
//  The title keeps clear of the trailing slot by reserving the same width
//  on both sides (at least the 44pt back button, or the trailing view's
//  width if that's wider), so it stays truly centered without overlapping.
//

import SwiftUI

struct ScreenNavigationBar<Trailing: View>: View {
    /// `nil` shows the back button alone (e.g. community post detail).
    let titleKey: LocalizedStringResource?
    let onBack: () -> Void
    private let trailing: Trailing

    @State private var trailingWidth: CGFloat = 0

    /// `trailing` defaults to nothing — most pushed screens only need the
    /// back button + title, but a few (e.g. a "완료" submit button, a room
    /// picker) need a slot on the right that isn't a system `ToolbarItem` —
    /// putting it there is exactly what triggers iOS 26's Liquid Glass
    /// button chrome, which this component exists to avoid.
    init(
        titleKey: LocalizedStringResource?,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.titleKey = titleKey
        self.onBack = onBack
        self.trailing = trailing()
    }

    private static var backButtonWidth: CGFloat { 44 }

    var body: some View {
        ZStack {
            if let titleKey {
                Text(titleKey)
                    .font(.screenNavTitleCentered).tracking(Tracking.screenNavTitleCentered)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, max(Self.backButtonWidth, trailingWidth) + Spacing.xs)
            }

            HStack(spacing: 0) {
                Button(action: onBack) {
                    NavigationChevron(direction: .left, color: .textPrimary)
                        .frame(width: Self.backButtonWidth, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.commonBack))

                Spacer(minLength: 0)

                trailing
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { trailingWidth = $0 }
            }
        }
        .frame(minHeight: 44)
        .padding(.vertical, Spacing.xxs)
        .padding(.horizontal, Spacing.md)
        .background(Color.appBackground)
    }
}

extension ScreenNavigationBar where Trailing == EmptyView {
    /// No trailing slot — back button + title only. A constrained init
    /// instead of a `= { EmptyView() }` default on the generic parameter,
    /// which Swift warns will become an error in a future language mode.
    init(titleKey: LocalizedStringResource?, onBack: @escaping () -> Void) {
        self.init(titleKey: titleKey, onBack: onBack) { EmptyView() }
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
