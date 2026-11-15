//
//  Report.swift
//  Cync
//
//  `Report` from `GET /api/reports` · `GET /api/reports/pending` ·
//  `POST /api/reports/{id}/resolve` (`docs/API.md` §9) — one row per
//  report. The server never groups them and never records what the admin
//  did about one: `RESOLVED` only means "an admin looked at it".
//
//  `ReportGroup` is the app-side grouping the admin screen shows: every
//  report on the same target (post or comment) with the same status
//  becomes one card ("신고 3건"). Status is part of the key so a target
//  that was handled and then reported again shows up as a fresh 미처리
//  card instead of hiding inside the old 처리 완료 one.
//

import Foundation

enum ReportStatus: String, Decodable, Hashable {
    case pending = "PENDING"
    case resolved = "RESOLVED"
}

/// What a report points at — the grouping key (with the status).
struct ReportTarget: Hashable {
    let kind: ReportTargetKind
    let id: Int
}

struct Report: Decodable, Identifiable, Hashable {
    let id: Int
    let target: ReportTarget
    let reporterId: String
    let reason: ReportReason
    let detail: String?
    var status: ReportStatus
    private let createdAtRaw: String

    var createdAt: Date { SpringDate.parse(createdAtRaw) }

    enum CodingKeys: String, CodingKey {
        case id, targetType, targetId, reporterId, reason, detail, status
        case createdAtRaw = "createdAt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        let type = try container.decode(String.self, forKey: .targetType)
        target = ReportTarget(
            kind: type == "COMMENT" ? .comment : .post,
            id: try container.decode(Int.self, forKey: .targetId)
        )
        reporterId = try container.decode(String.self, forKey: .reporterId)
        // A reason added on the server later reads as 기타, not a failure.
        let rawReason = try container.decode(String.self, forKey: .reason)
        reason = ReportReason(rawValue: rawReason) ?? .other
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
        status = try container.decode(ReportStatus.self, forKey: .status)
        createdAtRaw = try container.decodeIfPresent(String.self, forKey: .createdAtRaw) ?? ""
    }

    /// Previews only.
    init(id: Int, target: ReportTarget, reporterId: String, reason: ReportReason,
         detail: String?, status: ReportStatus, createdAtRaw: String) {
        self.id = id
        self.target = target
        self.reporterId = reporterId
        self.reason = reason
        self.detail = detail
        self.status = status
        self.createdAtRaw = createdAtRaw
    }
}

/// Every report on one target with one status — one card on the admin
/// screen.
struct ReportGroup: Identifiable, Hashable {
    let target: ReportTarget
    let status: ReportStatus
    /// Newest first.
    let reports: [Report]

    var id: String {
        "\(target.kind == .post ? "P" : "C")\(target.id)-\(status.rawValue)"
    }

    var count: Int { reports.count }

    var latestDate: Date { reports.first?.createdAt ?? .distantPast }

    var reportIDs: [Int] { reports.map(\.id) }

    /// The most common reason; on a tie, the newest report's.
    var reason: ReportReason {
        let counts = Dictionary(reports.map { ($0.reason, 1) }, uniquingKeysWith: +)
        let top = counts.values.max() ?? 0
        // `reports` is newest first, so the first one at the top count wins.
        return reports.first { counts[$0.reason] == top }?.reason ?? .other
    }

    /// The newest non-empty `detail`, or nil (the card hides the line).
    var detail: String? {
        reports.lazy
            .compactMap { $0.detail?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    /// Groups by target + status. Each group's reports are newest first;
    /// the groups themselves come back in no particular order.
    static func make(from reports: [Report]) -> [ReportGroup] {
        let grouped = Dictionary(grouping: reports) { GroupKey(target: $0.target, status: $0.status) }
        return grouped.map { key, members in
            ReportGroup(
                target: key.target,
                status: key.status,
                reports: members.sorted { ($0.createdAt, $0.id) > ($1.createdAt, $1.id) }
            )
        }
    }

    private struct GroupKey: Hashable {
        let target: ReportTarget
        let status: ReportStatus
    }
}

extension Report {
    /// Preview data — three reports on one post, one comment report, one report on a deleted post, two
    /// resolved.
    static let previewList: [Report] = {
        func at(_ hoursAgo: Double) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter.string(from: Date().addingTimeInterval(-hoursAgo * 3600))
        }
        let post6 = ReportTarget(kind: .post, id: 6)
        return [
            Report(id: 1, target: post6, reporterId: "20231010", reason: .abuse, detail: nil, status: .pending, createdAtRaw: at(6)),
            Report(id: 2, target: post6, reporterId: "20231011", reason: .spam, detail: "광고 같아요", status: .pending, createdAtRaw: at(4)),
            Report(id: 3, target: post6, reporterId: "20231012", reason: .abuse, detail: "단톡방 캡처에 욕설이 그대로 있어요", status: .pending, createdAtRaw: at(2)),
            Report(id: 4, target: ReportTarget(kind: .comment, id: 5), reporterId: "20231001", reason: .spam, detail: nil, status: .pending, createdAtRaw: at(5)),
            Report(id: 5, target: ReportTarget(kind: .post, id: 999), reporterId: "20231003", reason: .privacy, detail: "다른 학생 전화번호가 그대로 올라와 있어요", status: .pending, createdAtRaw: at(26)),
            Report(id: 6, target: ReportTarget(kind: .post, id: 2), reporterId: "20231010", reason: .falseInfo, detail: "공지랑 다른 내용이에요", status: .resolved, createdAtRaw: at(72)),
            Report(id: 7, target: ReportTarget(kind: .comment, id: 1), reporterId: "20231005", reason: .other, detail: nil, status: .resolved, createdAtRaw: at(96))
        ]
    }()
}
