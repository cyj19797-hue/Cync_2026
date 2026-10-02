//
//  PopupMenu.swift
//  Cync
//
//  A small action menu that drops down under the button that opened it —
//  the design system's own version of a pull-down menu (white card,
//  `borderLight` outline, soft shadow, same look as the locker room
//  dropdown in `LockerZonePicker.swift`), used instead of the system
//  `Menu` / `.confirmationDialog`, which force iOS's own styling.
//
//  Usage: mark the trigger with `.popupMenuAnchor()`, and put
//  `.popupMenu(isPresented:items:)` on a view that contains it (high enough
//  that the card isn't clipped). The card is right-aligned with the
//  trigger; tapping outside or picking an item closes it.
//
//  Several triggers on one screen (e.g. the post's ⋮ and every comment's
//  ⋮ on "5-1 게시글"): give each its own `.popupMenuAnchor(id:)` and use
//  `.popupMenu(presentedID:items:)`, which opens under whichever id is set.
//

import SwiftUI

struct PopupMenuItem: Identifiable {
    enum Role {
        case normal
        /// Delete-style actions — red icon.
        case destructive
    }

    let id: String
    let systemImage: String
    let titleKey: LocalizedStringResource
    var role: Role = .normal
    let action: () -> Void
}

extension View {
    /// Marks the view the menu should open beneath.
    func popupMenuAnchor(id: String = PopupMenuAnchorKey.defaultID) -> some View {
        anchorPreference(key: PopupMenuAnchorKey.self, value: .bounds) { [id: $0] }
    }

    /// One trigger on screen, marked with a plain `.popupMenuAnchor()`.
    func popupMenu(isPresented: Binding<Bool>, items: [PopupMenuItem]) -> some View {
        popupMenu(
            presentedID: Binding(
                get: { isPresented.wrappedValue ? PopupMenuAnchorKey.defaultID : nil },
                set: { isPresented.wrappedValue = $0 != nil }
            ),
            items: items
        )
    }

    /// Opens under the trigger whose `.popupMenuAnchor(id:)` matches
    /// `presentedID`; `nil` closes it.
    func popupMenu(presentedID: Binding<String?>, items: [PopupMenuItem]) -> some View {
        overlayPreferenceValue(PopupMenuAnchorKey.self) { anchors in
            PopupMenuOverlay(
                presentedID: presentedID,
                anchor: presentedID.wrappedValue.flatMap { anchors[$0] },
                items: items
            )
        }
        .animation(.easeOut(duration: 0.15), value: presentedID.wrappedValue)
    }
}

private struct PopupMenuOverlay: View {
    @Binding var presentedID: String?
    let anchor: Anchor<CGRect>?
    let items: [PopupMenuItem]

    private static let width: CGFloat = 160

    var body: some View {
        if presentedID != nil, let anchor, !items.isEmpty {
            GeometryReader { proxy in
                let rect = proxy[anchor]
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { presentedID = nil }

                    card
                        .frame(width: Self.width)
                        .offset(x: rect.maxX - Self.width, y: rect.maxY + Spacing.xxs)
                }
            }
            .transition(.opacity)
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    presentedID = nil
                    item.action()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: item.systemImage)
                            .foregroundStyle(item.role == .destructive ? Color.accentRed : Color.textSecondary)
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        Text(item.titleKey)
                            .font(.categoryFilterChipLabel).tracking(Tracking.categoryFilterChipLabel)
                            .foregroundStyle(Color.textPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if item.id != items.last?.id {
                    Divider().overlay(Color.borderLight)
                }
            }
        }
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: Radius.scheduleCard))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.borderLight)
        }
        .shadow(color: Color.textPrimary.opacity(0.12), radius: 12, y: 4)
    }
}

struct PopupMenuAnchorKey: PreferenceKey {
    static let defaultID = "default"
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { current, _ in current }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var isPresented = true
        var body: some View {
            VStack {
                HStack {
                    Spacer()
                    Button { isPresented.toggle() } label: {
                        Image(systemName: "ellipsis").rotationEffect(.degrees(90))
                    }
                    .popupMenuAnchor()
                }
                Spacer()
            }
            .padding()
            .popupMenu(isPresented: $isPresented, items: [
                PopupMenuItem(id: "report", systemImage: "exclamationmark.bubble", titleKey: "신고") {},
                PopupMenuItem(id: "delete", systemImage: "trash", titleKey: "삭제", role: .destructive) {},
            ])
        }
    }
    return PreviewHost()
}
