//
//  LockerCellView.swift
//  test
//
//  Figma node `136:4855` ("사물함") — one cell in the "전체 사물함" grid, also
//  reused by "4-1 사물함 신청" (`361:4254`, "사물함1") since both frames use
//  the identical cell art, just with two different display rules (see the
//  parameters below) — modeled as a single view driven by `LockerStatus`
//  instead of near-duplicate views, since they only differ by fill color,
//  label text, number formatting and masking.
//

import SwiftUI

struct LockerCellView: View {
    let locker: Locker

    /// Whether this cell is the signed-in student's own locker — derived
    /// from comparing `locker.currentUserId` to `GET /api/me`'s
    /// `studentId` (see `LockerViewModel`/`LockerApplicationViewModel`),
    /// since the server's `LockerStatus` has no "mine" case of its own.
    var isMine: Bool = false

    /// Whether a locker occupied by another student shows a real number or
    /// the anonymized "XXX번" placeholder. The "4 사물함" list screen masks
    /// it (privacy — never reveal another student's locker number); "4-1
    /// 사물함 신청" shows every real number instead, so this stays a
    /// parameter rather than being baked into `LockerStatus` itself.
    var maskOccupiedNumbers: Bool = true

    /// Whether to zero-pad the number ("001번" vs "1번") — "4-1 사물함 신청"
    /// zero-pads, the "4 사물함" list screen doesn't.
    var zeroPadded: Bool = false

    /// Draws a selection ring — used by "4-1 사물함 신청" while picking a
    /// locker to apply for. Unused (`false`) on the read-only list screen.
    var isSelected: Bool = false

    private var displayNumber: String {
        if maskOccupiedNumbers, locker.status == .inUse, !isMine {
            return "XXX번"
        }
        let numberText = zeroPadded ? String(format: "%03d", locker.lockerNumber) : "\(locker.lockerNumber)"
        return "\(numberText)번"
    }

    private var statusLabel: LocalizedStringKey {
        if isMine { return "내 사물함" }
        switch locker.status {
        case .inUse: return "사용중"
        case .available: return "사용 가능"
        case .broken: return "사용 불가"
        }
    }

    private var backgroundColor: Color {
        if isMine { return .brandPrimary }
        switch locker.status {
        case .inUse: return .gray400
        case .available: return .gray50
        case .broken: return .gray300
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(displayNumber)
                .font(.lockerCellNumber)
            Text(statusLabel)
                .font(.lockerCellStatus)
        }
        .foregroundStyle(Color.textPrimary)
        .padding(Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(100.0 / 75.0, contentMode: .fit)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lockerCell))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: Radius.lockerCell)
                    .strokeBorder(Color.brandPrimary, lineWidth: 2)
            }
        }
    }
}

#Preview {
    let statuses: [LockerStatus] = [.inUse, .available, .broken, .inUse]
    return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
        ForEach(Array(statuses.enumerated()), id: \.offset) { index, status in
            LockerCellView(
                locker: Locker(id: index + 1, lockerNumber: index + 1, location: nil, status: status, currentUserId: nil, assignedAt: nil, dueDate: nil, password: nil),
                isMine: index == 3
            )
        }
    }
    .padding()
}
