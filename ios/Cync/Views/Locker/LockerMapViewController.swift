//
//  LockerMapViewController.swift
//  Cync
//
//  UIKit screen for the full physical locker map — loads `lockers.json`
//  (layout only, via `LockerDataLoader`) then lays each zone's
//  `LockerZoneView` out in a scrollable, pinch-zoomable canvas matching the
//  building's floor plan: two rows of zones, left to right, each zone's
//  origin computed by accumulating the widths of the zones already placed
//  before it. Real cell status comes from `LockerAPIService` (`GET
//  /api/lockers`), fetched on load and matched onto cells by
//  `lockerNumber`; cells with no match show `.unknown`.
//
//  Also supports "warping" the canvas to a named zone (nav bar "이동"
//  menu, or `warp(to:)` directly) and reports cell taps through
//  `LockerMapViewControllerDelegate` — this screen never presents a detail
//  view itself, that's left to whoever sets `delegate`.
//

import SwiftUI
import UIKit

protocol LockerMapViewControllerDelegate: AnyObject {
    func lockerMapViewController(
        _ controller: LockerMapViewController,
        didSelectLockerNumber lockerNumber: Int,
        zoneId: String,
        status: LockerCellStatus
    )
}

final class LockerMapViewController: UIViewController {
    /// Zone order per row, matching the floor-plan image — also the order
    /// zones appear in the "이동" warp menu.
    private static let zoneRows: [[String]] = [
        ["B201", "B202", "B203(1)", "B203(2)", "B203(3)", "B204"],
        ["B208(2)", "B208(1)", "B207(2)", "B207(1)", "B206", "B205"]
    ]
    private static let zoneGap: CGFloat = 40
    private static let rowGap: CGFloat = 40
    private static let canvasInset: CGFloat = 16
    /// Padding added around a zone's frame when warping to it, so the zone
    /// isn't cropped flush against the screen edges.
    private static let warpPadding: CGFloat = 24

    /// Every zone, in floor-plan/warp-menu order — exposed so a SwiftUI
    /// host (e.g. `LockerApplicationMapView`'s own "이동" toolbar) can list
    /// the same zones without duplicating `zoneRows`.
    static var zoneIdsInOrder: [String] { zoneRows.flatMap { $0 } }

    /// How the initial "전체보기" zoom is chosen.
    enum InitialZoomFit {
        /// Scales both dimensions so the whole canvas fits on screen —
        /// the default, used by "전체 사물함"'s map chevron.
        case fitCanvas
        /// Scales to fit the canvas *height* only, with `padding` reserved
        /// above and below (via `contentInset`); width is left at that
        /// same scale and overflows, scrollable left/right. Used by
        /// "사물함 신청"'s entry, where cells should stay a legible fixed
        /// size and zones are browsed by scrolling sideways rather than
        /// by pinch-zooming.
        case fitHeight(padding: CGFloat)
    }

    weak var delegate: LockerMapViewControllerDelegate?

    /// Set *before* the view loads (i.e. right after `init`).
    var initialZoomFit: InitialZoomFit = .fitCanvas

    /// Shows a fixed color-legend bar (`LockerStatusLegendBar`) pinned to
    /// the bottom of the screen, below the canvas. Set *before* the view
    /// loads.
    var showsLegend = false

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let statusErrorView = LockerMapStatusErrorView()
    private let legendBar = LockerStatusLegendBar()

    /// Every zone view that was actually laid out, keyed by `zoneId` — used
    /// to push freshly fetched statuses onto their cells.
    private var zoneViews: [String: LockerZoneView] = [:]
    /// Each zone's frame in `contentView`'s own (unscaled) coordinate
    /// space — valid input for both `scrollRectToVisible` and `zoom(to:)`
    /// regardless of the scroll view's current zoom scale.
    private var zoneFrames: [String: CGRect] = [:]
    /// The canvas size computed in `loadAndLayoutZones`, kept separately
    /// from `contentView.frame.size` since zooming scales that frame.
    private var canvasSize: CGSize = .zero
    private var hasAppliedInitialZoom = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "사물함 배치도"
        view.backgroundColor = .systemBackground
        setUpScrollView()
        setUpNavigationBar()
        setUpLoadingIndicator()
        setUpStatusErrorView()

        if loadAndLayoutZones() {
            fetchAndApplyLockerStatuses()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasAppliedInitialZoom,
              canvasSize.width > 0, canvasSize.height > 0,
              scrollView.bounds.width > 0, scrollView.bounds.height > 0 else { return }
        hasAppliedInitialZoom = true
        applyFitToScreenZoom()
    }

    private func setUpScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        view.addSubview(scrollView)

        var scrollViewBottomAnchor = view.bottomAnchor
        if showsLegend {
            legendBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(legendBar)
            NSLayoutConstraint.activate([
                legendBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                legendBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                legendBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
            scrollViewBottomAnchor = legendBar.topAnchor
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: scrollViewBottomAnchor)
        ])
        scrollView.addSubview(contentView)
    }

    private func setUpNavigationBar() {
        let zoneIds = Self.zoneRows.flatMap { $0 }
        let warpActions = zoneIds.map { zoneId in
            UIAction(title: zoneId) { [weak self] _ in
                self?.warp(to: zoneId)
            }
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "이동",
            menu: UIMenu(title: "이동할 구역", children: warpActions)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(handleRefreshButtonTap)
        )
    }

    private func setUpLoadingIndicator() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setUpStatusErrorView() {
        statusErrorView.isHidden = true
        statusErrorView.onRetry = { [weak self] in self?.fetchAndApplyLockerStatuses() }
        statusErrorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusErrorView)
        NSLayoutConstraint.activate([
            statusErrorView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            statusErrorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusErrorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusErrorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Builds every zone's view from the bundled layout JSON. Returns
    /// `false` (after showing an error) if that layout data itself
    /// couldn't be loaded — a bundling problem, not a network one.
    @discardableResult
    private func loadAndLayoutZones() -> Bool {
        let cellsByZone: [String: [LockerCell]]
        do {
            cellsByZone = try LockerDataLoader.loadGroupedByZone()
        } catch {
            showLayoutError(error)
            return false
        }

        zoneViews.removeAll()
        zoneFrames.removeAll()
        var cursorY = Self.canvasInset
        var contentWidth: CGFloat = 0

        for zoneRow in Self.zoneRows {
            var cursorX = Self.canvasInset
            var rowHeight: CGFloat = 0

            for zoneId in zoneRow {
                guard let cells = cellsByZone[zoneId] else { continue }
                let zone = LockerZone(zoneId: zoneId, cells: cells)
                let zoneView = LockerZoneView(zone: zone)
                let size = LockerZoneView.contentSize(for: zone)

                let frame = CGRect(origin: CGPoint(x: cursorX, y: cursorY), size: size)
                zoneView.frame = frame
                zoneView.onCellSelected = { [weak self] cell in
                    // Reserved cells (학생회 사물함) have no `lockerNumber` and
                    // aren't a rentable locker to report a selection for.
                    guard let self, let lockerNumber = cell.lockerNumber else { return }
                    self.delegate?.lockerMapViewController(
                        self,
                        didSelectLockerNumber: lockerNumber,
                        zoneId: cell.zoneId,
                        status: cell.status
                    )
                }
                contentView.addSubview(zoneView)
                zoneViews[zoneId] = zoneView
                zoneFrames[zoneId] = frame

                cursorX += size.width + Self.zoneGap
                rowHeight = max(rowHeight, size.height)
            }

            contentWidth = max(contentWidth, cursorX - Self.zoneGap)
            cursorY += rowHeight + Self.rowGap
        }

        let contentHeight = cursorY - Self.rowGap + Self.canvasInset
        let size = CGSize(width: contentWidth + Self.canvasInset, height: contentHeight)
        canvasSize = size
        contentView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        return true
    }

    /// Sets `minimumZoomScale` per `initialZoomFit`, then zooms to it —
    /// the "전체보기" entry state.
    private func applyFitToScreenZoom() {
        let fitScale: CGFloat
        switch initialZoomFit {
        case .fitCanvas:
            scrollView.contentInset = .zero
            fitScale = min(
                scrollView.bounds.width / canvasSize.width,
                scrollView.bounds.height / canvasSize.height
            )
        case .fitHeight(let padding):
            scrollView.contentInset = UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0)
            let availableHeight = scrollView.bounds.height - padding * 2
            fitScale = availableHeight / canvasSize.height
        }
        scrollView.minimumZoomScale = fitScale
        scrollView.maximumZoomScale = max(fitScale * 4, 1)
        scrollView.zoomScale = fitScale

        if case .fitHeight(let padding) = initialZoomFit {
            // Rest at the inset's "natural" position — otherwise the top
            // padding wouldn't show until the user scrolled up to it.
            scrollView.contentOffset = CGPoint(x: 0, y: -padding)
        }
    }

    /// Animates the canvas to bring `zoneId` into view, zooming in on it.
    /// No-op if `zoneId` isn't a known zone (e.g. data failed to load).
    func warp(to zoneId: String, animated: Bool = true) {
        guard let frame = zoneFrames[zoneId] else { return }
        let target = frame.insetBy(dx: -Self.warpPadding, dy: -Self.warpPadding)
        scrollView.zoom(to: target, animated: animated)
    }

    @objc private func handlePullToRefresh() {
        fetchAndApplyLockerStatuses(isPullToRefresh: true)
    }

    @objc private func handleRefreshButtonTap() {
        fetchAndApplyLockerStatuses()
    }

    /// Fetches live locker statuses and pushes them onto the already-built
    /// cells, matched by `lockerNumber`. Drives the loading indicator,
    /// pull-to-refresh spinner and error+retry view.
    private func fetchAndApplyLockerStatuses(isPullToRefresh: Bool = false) {
        statusErrorView.isHidden = true
        if !isPullToRefresh {
            loadingIndicator.startAnimating()
        }

        Task {
            do {
                let statusByLockerNumber = try await LockerAPIService.fetchStatusByLockerNumber()
                for zoneView in zoneViews.values {
                    zoneView.applyStatuses(statusByLockerNumber)
                }
                loadingIndicator.stopAnimating()
                scrollView.refreshControl?.endRefreshing()
            } catch {
                loadingIndicator.stopAnimating()
                scrollView.refreshControl?.endRefreshing()
                statusErrorView.message = error.localizedDescription
                statusErrorView.isHidden = false
            }
        }
    }

    private func showLayoutError(_ error: Error) {
        let label = UILabel()
        label.text = error.localizedDescription
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
}

extension LockerMapViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }
}

/// Full-screen "fetch failed" message + retry button, shown over the
/// canvas while `LockerAPIService.fetchStatusByLockerNumber()` is failing.
private final class LockerMapStatusErrorView: UIView {
    var onRetry: (() -> Void)?
    var message: String = "" {
        didSet { messageLabel.text = message }
    }

    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground

        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .secondaryLabel
        messageLabel.font = .systemFont(ofSize: 14)

        let retryButton = UIButton(type: .system)
        retryButton.setTitle("다시 시도", for: .normal)
        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleRetryTap() {
        onRetry?()
    }
}

/// Fixed horizontal-scrolling bar of color swatch + label pairs, one per
/// `LockerCellStatus` that can actually appear on a rentable cell — lets
/// "사물함 신청" explain what each color means before the student starts
/// tapping cells. Colors/labels come straight from `LockerCellStatus`
/// (`uiColor`/`legendLabel`) so this can never drift from the cells
/// themselves.
private final class LockerStatusLegendBar: UIView {
    // `.pending`/`.occupied` (승인 대기중/사용중) and `.reserved` (학생회 사물함,
    // which renders as `.broken`'s color with no legend entry of its own)
    // are deliberately excluded — only 신청 가능/사용 불가 need explaining here.
    private static let statuses: [LockerCellStatus] = [.empty, .broken]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        let stack = UIStackView(arrangedSubviews: Self.statuses.map(Self.makeItem))
        stack.axis = .horizontal
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeItem(for status: LockerCellStatus) -> UIView {
        let swatch = UIView()
        swatch.backgroundColor = status.uiColor
        swatch.layer.cornerRadius = 5
        swatch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            swatch.widthAnchor.constraint(equalToConstant: 10),
            swatch.heightAnchor.constraint(equalToConstant: 10)
        ])

        let label = UILabel()
        label.text = status.legendLabel
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel

        let item = UIStackView(arrangedSubviews: [swatch, label])
        item.axis = .horizontal
        item.spacing = 6
        item.alignment = .center
        return item
    }
}

/// SwiftUI wrapper around `LockerMapViewController` — no
/// `UINavigationController` of its own, since this is meant as a
/// `NavigationLink` destination inside a screen that already has one (e.g.
/// `LockerView`'s "전체 사물함" chevron and "사물함 신청" prompt, both via
/// `LockerApplicationMapView`).
struct LockerMapScreenView: UIViewControllerRepresentable {
    var delegate: LockerMapViewControllerDelegate?
    var initialZoomFit: LockerMapViewController.InitialZoomFit = .fitCanvas
    var showsLegend: Bool = false
    /// Fired once with the created controller — lets a SwiftUI host (e.g.
    /// `LockerApplicationMapView`) drive `warp(to:)` from its own toolbar,
    /// since `navigationItem` set on a bare UIKit controller pushed via
    /// `NavigationLink` isn't reliably bridged into the actual nav bar.
    var onControllerReady: ((LockerMapViewController) -> Void)?

    func makeUIViewController(context: Context) -> LockerMapViewController {
        let controller = LockerMapViewController()
        controller.delegate = delegate
        controller.initialZoomFit = initialZoomFit
        controller.showsLegend = showsLegend
        onControllerReady?(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: LockerMapViewController, context: Context) {
        uiViewController.delegate = delegate
    }
}

#Preview {
    NavigationStack {
        LockerMapScreenView()
    }
}
