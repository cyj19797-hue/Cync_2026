//
//  RelativeTime.swift
//  Cync
//
//  Shared timestamp formatting for the community feed, post detail, and
//  comments: "방금" under a minute, then "N분 전" / "N시간 전" / "N일 전"
//  ("Just now" / "N minutes ago" / …) up to a week, and past that the same
//  absolute date the notice board shows ("2026.09.04." in Korean,
//  "Sep 4, 2026" in English) — `Notice.dateText` uses `absoluteDateText`
//  below so the two boards can't drift apart.
//
//  Thresholds are elapsed time, not calendar days (a post from 23:50
//  yesterday reads "N분 전" at 00:10, not "1일 전").
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
        case ..<(7 * day):
            return String(appLocalized: .timeDaysAgo(Int(seconds / day)))
        default:
            return absoluteDateText(for: date)
        }
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
