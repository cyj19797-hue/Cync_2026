//
//  LockerZonePicker.swift
//  Cync
//
//  The locker map's room controls, shared by "4 사물함" (`LockerView`) and
//  "사물함 신청" (`LockerApplicationMapView`) so both screens move around
//  the map the same way:
//  - `LockerZoneButton` — "B201 ⌄" capsule naming the room the map is on;
//    tapping it opens the room dropdown.
//  - `LockerResetViewButton` — "◎", back to the map's first view. Hosts
//    show it only once the map has been moved.
//  - `.lockerZoneDropdown(...)` — the dropdown itself, a small design-
//    system-styled list anchored under the zone button (not a system
//    `Menu`); tapping outside closes it. Apply it on a view that contains
//    the zone button, high enough that the list isn't clipped.
//

import SwiftUI

struct LockerZoneButton: View {
    /// Room shown on the button — `nil` falls back to the first room.
    let zoneId: String?
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: Spacing.xxs) {
                Text(verbatim: zoneId ?? LockerMapViewController.zoneIdsInOrder.first ?? "")
                    .font(.lockerZoneButton).tracking(Tracking.lockerZoneButton)
                    .foregroundStyle(Color.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.lockerZoneButton)
                    .foregroundStyle(Color.gray400)
            }
            .padding(.horizontal, Spacing.cardInset)
            .padding(.vertical, Spacing.xxs + 2)
            // Gray outline, same gray as the chevron.
            .overlay {
                Capsule().strokeBorder(Color.gray400)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(.lockerChooseZone))
        .anchorPreference(key: LockerZoneMenuAnchorKey.self, value: .bounds) { $0 }
    }
}

struct LockerResetViewButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "scope")
                .font(.lockerZoneButton)
                .foregroundStyle(Color.textPrimary)
                .frame(width: 28, height: 28)
                .overlay {
                    Circle().strokeBorder(Color.gray400)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.lockerResetView))
    }
}

extension View {
    /// Room dropdown under `LockerZoneButton`, listing rooms in name order
    /// (B201, B202, B203(1) …) rather than the map's floor-plan order.
    func lockerZoneDropdown(
        isPresented: Binding<Bool>,
        currentZoneId: String?,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        overlayPreferenceValue(LockerZoneMenuAnchorKey.self) { anchor in
            LockerZoneDropdown(
                isPresented: isPresented,
                anchor: anchor,
                currentZoneId: currentZoneId,
                onSelect: onSelect
            )
        }
        .animation(.easeOut(duration: 0.15), value: isPresented.wrappedValue)
    }
}

private struct LockerZoneDropdown: View {
    @Binding var isPresented: Bool
    let anchor: Anchor<CGRect>?
    let currentZoneId: String?
    let onSelect: (String) -> Void

    private static let sortedZoneIds = LockerMapViewController.zoneIdsInOrder.sorted {
        $0.localizedStandardCompare($1) == .orderedAscending
    }

    private static let width: CGFloat = 160
    private static let rowHeight: CGFloat = 40

    var body: some View {
        if isPresented, let anchor {
            GeometryReader { proxy in
                let rect = proxy[anchor]
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented = false }

                    // Right-aligned with the (right-aligned) room button.
                    list
                        .frame(width: Self.width)
                        .offset(x: rect.maxX - Self.width, y: rect.maxY + Spacing.xxs)
                }
            }
            .transition(.opacity)
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Self.sortedZoneIds, id: \.self) { zoneId in
                    Button {
                        isPresented = false
                        onSelect(zoneId)
                    } label: {
                        Text(verbatim: zoneId)
                            .font(.categoryFilterChipLabel).tracking(Tracking.categoryFilterChipLabel)
                            .foregroundStyle(zoneId == currentZoneId ? Color.eventAccent : Color.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: Self.rowHeight, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if zoneId != Self.sortedZoneIds.last {
                        Divider().overlay(Color.borderLight)
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: Self.rowHeight * 6.5)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: Radius.scheduleCard))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.scheduleCard)
                .strokeBorder(Color.borderLight)
        }
        .shadow(color: Color.textPrimary.opacity(0.12), radius: 12, y: 4)
    }
}

/// Bounds of `LockerZoneButton`, so the dropdown can open right beneath it
/// from a screen-level overlay.
private struct LockerZoneMenuAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}
