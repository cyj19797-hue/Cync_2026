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
//  Optional extras for a room *filter* (관리자 사물함 관리 "사용 중"), off by
//  default so the map screens are unchanged: an "전체 구역" label/row for
//  "no room picked" (`allZonesKey`), and a `.field` button look matching
//  the search field beside it.
//

import SwiftUI

struct LockerZoneButton: View {
    enum Style {
        /// Outlined capsule — the map screens.
        case capsule
        /// `surface`-filled box, as tall as `SearchBar` — a filter row.
        case field
    }

    /// Room shown on the button — `nil` falls back to `allZonesKey` if
    /// given, otherwise to the first room.
    let zoneId: String?
    @Binding var isPresented: Bool
    var allZonesKey: LocalizedStringResource? = nil
    var style: Style = .capsule
    /// `.field` only: vertical padding for when there's no `SearchBar`
    /// beside it to take the height from. 0 (default) = unchanged.
    var fieldVerticalPadding: CGFloat = 0

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            switch style {
            case .capsule: capsuleLabel
            case .field: fieldLabel
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(.lockerChooseZone))
        .anchorPreference(key: LockerZoneMenuAnchorKey.self, value: .bounds) { $0 }
    }

    @ViewBuilder
    private var title: some View {
        if let zoneId {
            Text(verbatim: zoneId)
        } else if let allZonesKey {
            Text(allZonesKey)
        } else {
            Text(verbatim: LockerMapViewController.zoneIdsInOrder.first ?? "")
        }
    }

    private var capsuleLabel: some View {
        HStack(spacing: Spacing.xxs) {
            title
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

    /// Figma `690:3811`: 12/10pt padding, 4pt gap, 10pt corners. Vertical
    /// padding matches `SearchBar` so the two line up in one row.
    private var fieldLabel: some View {
        HStack(spacing: Spacing.xxs) {
            title
                .font(.adminFilterButton).tracking(Tracking.adminFilterButton)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.adminFilterButton)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.leading, Spacing.cardInset)
        .padding(.trailing, Spacing.compactButton)
        .padding(.vertical, fieldVerticalPadding)
        .frame(maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Radius.chipSelected)
                .fill(Color.surface)
        }
        .contentShape(RoundedRectangle(cornerRadius: Radius.chipSelected))
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
        lockerZoneDropdown(
            isPresented: isPresented,
            currentZoneId: currentZoneId,
            allZonesKey: nil,
            onSelectZone: { zoneId in if let zoneId { onSelect(zoneId) } }
        )
    }

    /// Same dropdown with an "전체 구역" row on top (`allZonesKey`), which
    /// selects `nil` — for a room filter.
    func lockerZoneDropdown(
        isPresented: Binding<Bool>,
        currentZoneId: String?,
        allZonesKey: LocalizedStringResource?,
        onSelectZone: @escaping (String?) -> Void
    ) -> some View {
        overlayPreferenceValue(LockerZoneMenuAnchorKey.self) { anchor in
            LockerZoneDropdown(
                isPresented: isPresented,
                anchor: anchor,
                currentZoneId: currentZoneId,
                allZonesKey: allZonesKey,
                onSelect: onSelectZone
            )
        }
        .animation(.easeOut(duration: 0.15), value: isPresented.wrappedValue)
    }
}

private struct LockerZoneDropdown: View {
    @Binding var isPresented: Bool
    let anchor: Anchor<CGRect>?
    let currentZoneId: String?
    let allZonesKey: LocalizedStringResource?
    let onSelect: (String?) -> Void

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
                if let allZonesKey {
                    Button {
                        isPresented = false
                        onSelect(nil)
                    } label: {
                        Text(allZonesKey)
                            .font(.categoryFilterChipLabel).tracking(Tracking.categoryFilterChipLabel)
                            .foregroundStyle(currentZoneId == nil ? Color.eventAccent : Color.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: Self.rowHeight, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(Color.borderLight)
                }

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
