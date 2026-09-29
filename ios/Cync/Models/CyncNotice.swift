//
//  CyncNotice.swift
//  Cync
//
//  A single "Cync 공지" entry — in-app announcements posted by the Cync
//  team itself (e.g. version-update notes), shown on "6-2 Cync 공지" /
//  "6-2-1 공지사항 내용". Distinct from the school/student-council board
//  backing `Notice`/`NoticeListView`. No backend endpoint exists for this
//  board yet, so this is mock data only, wired from SettingsView's
//  "Cync 공지" row.
//

import Foundation

struct CyncNotice: Identifiable, Hashable {
    let id: Int
    var title: String
    var date: Date
    var content: String

    var dateText: String {
        date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).locale(Locale(identifier: "ko_KR")))
            .replacingOccurrences(of: " ", with: "")
    }
}

extension CyncNotice {
    /// Mock data for previews and the not-yet-backed list — Figma's own
    /// "6-2 Cync 공지" mock repeats the same placeholder title/content for
    /// every row, so this mirrors that rather than inventing real copy.
    static let mockList: [CyncNotice] = {
        let day = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 5))!

        return (1...6).map { index in
            CyncNotice(
                id: index,
                title: "[버전] 업데이트 안내",
                date: day,
                content: "내용을 자유롭게 입력하세요."
            )
        }
    }()
}
