//
//  RelativeTime.swift
//  Cync
//
//  Shared timestamp formatting for the community feed, post detail, and
//  comments:
//    - under a minute: "방금" / "Just now"
//    - under an hour: "N분 전" / "N minutes ago"
//    - under a day: "N시간 전" / "N hours ago"
//    - older, same year: month/day — "9/15"
//    - older, earlier year: two-digit year too — "25/9/15" in Korean,
//      "9/15/25" in English (each language's own order)
//
//  Thresholds are elapsed time, not calendar days (a post from 23:50
//  yesterday reads "N분 전" at 00:10). The notice boards keep their full
//  date (`absoluteDateText`, "2026.09.04.") — `Notice.dateText` uses it.
//

import Foundation

enum RelativeTime {
    static func text(for date: Date, now: Date = Date()) -> String {
        // Clamp so a server clock slightly ahead never reads as negative.
        let seconds = max(0, now.timeIntervalSince(date))
        let minute: TimeInterval = 60
        let hour = 60 * minute
        let day = 24 * hour

        switch seconds {
        case ..<minute:
            return String(appLocalized: .timeJustNow)
        case ..<hour:
            return String(appLocalized: .timeMinutesAgo(Int(seconds / minute)))
        case ..<day:
            return String(appLocalized: .timeHoursAgo(Int(seconds / hour)))
        default:
            return shortDateText(for: date, now: now)
        }
    }

    /// "9/15" this year, "25/9/15" (Korean) / "9/15/25" (English) for an
    /// earlier year — no leading zeros on month or day. The order per
    /// language lives in Localizable.xcstrings (`time.monthDay`,
    /// `time.yearMonthDay`), not here.
    static func shortDateText(for date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return "" }

        if year == calendar.component(.year, from: now) {
            return String(appLocalized: .timeMonthDay(month, day))
        }
        let shortYear = String(format: "%02d", year % 100)
        return String(appLocalized: .timeYearMonthDay(shortYear, month, day))
    }

    /// Absolute date in the current locale: "2026.09.01." in Korean,
    /// "Sep 1, 2026" in English.
    static func absoluteDateText(for date: Date) -> String {
        let locale = AppLanguage.currentLocale
        if locale.language.languageCode == .korean {
            return date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).locale(locale))
                .replacingOccurrences(of: " ", with: "")
        }
        return date.formatted(.dateTime.year().month(.abbreviated).day().locale(locale))
    }
}
