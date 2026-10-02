//
//  LockerZoneView.swift
//  Cync
//
//  UIKit view for one zone of the physical locker map (e.g. "B201") — a
//  title label over a column-first grid of `LockerCell`s (see
//  `LockerModels.swift`), sized from the zone's own data so
//  `LockerMapViewController` can read `contentSize(for:)` to lay zones out
//  without a layout pass.
//

import SwiftUI
import UIKit

final class LockerZoneView: UIView {
    static let cellSize = CGSize(width: 40, height: 32)
    static let cellSpacing: CGFloat = 4
    static let titleHeight: CGFloat = 20
    static let titleSpacing: CGFloat = 6

    let zone: LockerZone

    /// Fired when a cell is tapped, with that cell's full data. The map
    /// screen forwards this to its own delegate — no detail UI is opened
    /// here.
    var onCellSelected: ((LockerCell) -> Void)?

    private let titleLabel = UILabel()
    private var cellViews: [(cell: LockerCell, view: LockerCellLabel)] = []

    init(zone: LockerZone) {
        self.zone = zone
        super.init(frame: .zero)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The size this zone needs — title + its column-first grid, with no
    /// dependency on Auto Layout — so a caller can position multiple zones
    /// purely from their computed sizes (see `LockerMapViewController`).
    static func contentSize(for zone: LockerZone) -> CGSize {
        let cols = (zone.cells.map(\.col).max() ?? -1) + 1
        let rows = (zone.cells.map(\.row).max() ?? -1) + 1
        let width = CGFloat(cols) * cellSize.width + CGFloat(max(cols - 1, 0)) * cellSpacing
        let gridHeight = CGFloat(rows) * cellSize.height + CGFloat(max(rows - 1, 0)) * cellSpacing
        let height = titleHeight + titleSpacing + gridHeight
        return CGSize(width: width, height: height)
    }

    override var intrinsicContentSize: CGSize {
        Self.contentSize(for: zone)
    }

    private func setUp() {
        titleLabel.text = zone.zoneId
        // Larger than the 12pt cell numbers so room names stand out; the
        // room the map is currently on is tinted (`setTitleHighlighted`).
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(Color.textPrimary)
        titleLabel.textAlignment = .left
        addSubview(titleLabel)

        for cell in zone.cells {
            let cellView = LockerCellLabel(cell: cell)
            cellView.isUserInteractionEnabled = true
            cellView.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(handleCellTap(_:)))
            )
            addSubview(cellView)
            cellViews.append((cell, cellView))
        }

        frame.size = Self.contentSize(for: zone)
    }

    @objc private func handleCellTap(_ recognizer: UITapGestureRecognizer) {
        guard let cellView = recognizer.view as? LockerCellLabel else { return }
        onCellSelected?(cellView.cell)
    }

    /// Applies server-fetched statuses onto this zone's cells, matched by
    /// `lockerNumber`. A numbered cell with no entry in
    /// `statusByLockerNumber` falls back to `.unknown`; a reserved cell
    /// (`lockerNumber == nil`) has nothing to match and is left as
    /// `.reserved`.
    func applyStatuses(_ statusByLockerNumber: [Int: LockerCellStatus]) {
        for (_, cellView) in cellViews {
            guard let lockerNumber = cellView.cell.lockerNumber else { continue }
            cellView.updateStatus(statusByLockerNumber[lockerNumber] ?? .unknown)
        }
    }

    /// Overrides `lockerNumber`'s cell to `.selected`, regardless of its
    /// server status — used by `LockerMapViewController.focusLockerNumber`
    /// to highlight "내 사물함" on the map. No-op if this zone has no cell
    /// with that number.
    func highlight(lockerNumber: Int) {
        for (_, cellView) in cellViews where cellView.cell.lockerNumber == lockerNumber {
            cellView.updateStatus(.selected)
        }
    }

    /// Tints the room name in the accent color while the map is focused on
    /// this room (see `LockerMapViewController.focusedZoneId`).
    func setTitleHighlighted(_ isHighlighted: Bool) {
        titleLabel.textColor = UIColor(isHighlighted ? Color.eventAccent : Color.textPrimary)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: Self.titleHeight)

        for (cell, cellView) in cellViews {
            let x = CGFloat(cell.col) * (Self.cellSize.width + Self.cellSpacing)
            let y = Self.titleHeight + Self.titleSpacing
                + CGFloat(cell.row) * (Self.cellSize.height + Self.cellSpacing)
            cellView.frame = CGRect(origin: CGPoint(x: x, y: y), size: Self.cellSize)
        }
    }
}

/// One grid cell — the locker number over a status-colored background.
final class LockerCellLabel: UILabel {
    private(set) var cell: LockerCell

    init(cell: LockerCell) {
        self.cell = cell
        super.init(frame: .zero)
        text = cell.lockerNumber.map(String.init) ?? "-"
        textAlignment = .center
        font = .systemFont(ofSize: 12, weight: .medium)
        textColor = cell.status.uiTextColor
        layer.cornerRadius = 6
        clipsToBounds = true
        backgroundColor = cell.status.uiColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates this cell's status in place (e.g. once the server response
    /// comes back) and recolors it to match.
    func updateStatus(_ status: LockerCellStatus) {
        cell.status = status
        backgroundColor = status.uiColor
        textColor = status.uiTextColor
    }
}

/// Shared with `LockerStatusLegendBar` so the legend's swatches and labels
/// never drift from what a cell actually renders.
extension LockerCellStatus {
    /// Tile fill — the SwiftUI `color` below, bridged for UIKit, so the
    /// apply-screen map and the main-screen grid always match.
    var uiColor: UIColor { UIColor(color) }

    /// Number color on top of `uiColor`.
    var uiTextColor: UIColor { UIColor(textColor) }

    /// 사용중 · 고장 · 학생회 사물함 · 정보 없음 all render as one quiet
    /// "사용 불가" tile — none can be applied for, and telling them apart
    /// didn't help the student pick a locker.
    var color: Color {
        switch self {
        case .empty: return .lockerAvailable
        case .pending: return .lockerPending
        case .occupied, .broken, .unknown: return .lockerUnavailable
        case .reserved: return .lockerRestricted
        case .selected: return .lockerMine
        }
    }

    /// The light-gray "사용 불가" swatch nearly matches a white background,
    /// so legends outline it.
    var needsLegendBorder: Bool {
        color == .lockerUnavailable
    }

    var textColor: Color {
        switch self {
        case .empty, .pending: return .textPrimary
        case .occupied, .broken, .unknown: return .lockerUnavailableText
        case .reserved, .selected: return .white
        }
    }

    /// Label shown next to this status's swatch in `LockerStatusLegendBar`.
    var legendLabel: String {
        switch self {
        // Legend-only keys: English needs short words here ("Open /
        // Pending / Taken / Mine") so all four fit on one line; the longer
        // `locker.status.*` wording stays for everywhere else.
        case .empty: return String(appLocalized: .lockerLegendOpen)
        case .pending: return String(appLocalized: .lockerLegendPending)
        case .occupied, .broken, .reserved, .unknown: return String(appLocalized: .lockerLegendTaken)
        case .selected: return String(appLocalized: .lockerLegendMine)
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255
        let b = CGFloat(hex & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
