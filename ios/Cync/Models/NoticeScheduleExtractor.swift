//
//  NoticeScheduleExtractor.swift
//  Cync
//
//  Pulls the "action dates" (신청 마감, 행사일, 기간 …) out of a notice's
//  text so the calendar can show a bookmarked notice on the day the user
//  has to act — not on the day it was posted. The server has no such field
//  yet, so this is an on-device stopgap: a regex pass for the Korean date
//  formats department notices actually use ("9/2(수) 오전 10:00",
//  "2026. 6. 5.(금)", "9월 1일 ~ 9월 5일"), with `NSDataDetector` as a
//  fallback for text the regex finds nothing in (English notices etc.).
//  The kind of date is guessed from keywords on the same line. Swap this
//  out for a server-provided field once the backend's AI extraction exists.
//

import Foundation

struct ExtractedSchedule: Hashable {
    /// Includes the time of day when `hasTime` is true, otherwise start of day.
    var startDate: Date
    /// Start of the last day (inclusive). Equal to the start day for
    /// single-day entries.
    var endDate: Date
    var hasTime: Bool
    var kind: CalendarEvent.Kind?
}

enum NoticeScheduleExtractor {
    /// Upper bound per notice — schedule-table notices can list dozens of
    /// dates, and the calendar gets noisy well before that.
    private static let maxSchedulesPerNotice = 5

    /// Extracts schedules from `text`, resolving year-less dates relative to
    /// `postedDate`. Dates before the posting day (references to earlier
    /// notices, "결과 발표" recaps) are dropped.
    static func extract(from text: String, postedDate: Date, calendar: Calendar = .current) -> [ExtractedSchedule] {
        var results = regexSchedules(in: text, postedDate: postedDate, calendar: calendar)
        if results.isEmpty {
            results = detectorSchedules(in: text, postedDate: postedDate, calendar: calendar)
        }

        let earliest = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: postedDate)) ?? postedDate
        let latest = calendar.date(byAdding: .year, value: 1, to: postedDate) ?? postedDate

        // The same day often shows up twice — a bare "9/2" in the title and
        // "9/2(수) 오전 10:00" in the body. Merge those into one entry that
        // keeps the time and whichever kind was recognized, instead of
        // letting the time-less (earlier-sorting) copy win.
        var merged: [String: ExtractedSchedule] = [:]
        var order: [String] = []
        for schedule in results where schedule.endDate >= earliest && schedule.startDate <= latest {
            let key = "\(calendar.startOfDay(for: schedule.startDate).timeIntervalSince1970)-\(schedule.endDate.timeIntervalSince1970)"
            guard var existing = merged[key] else {
                merged[key] = schedule
                order.append(key)
                continue
            }
            if !existing.hasTime, schedule.hasTime {
                existing.startDate = schedule.startDate
                existing.hasTime = true
            }
            if existing.kind == nil {
                existing.kind = schedule.kind
            }
            merged[key] = existing
        }

        return order
            .compactMap { merged[$0] }
            .sorted { $0.startDate < $1.startDate }
            .prefix(maxSchedulesPerNotice)
            .map { $0 }
    }

    /// Keyword-based kind for a single-day entry (also used for server
    /// schedules' titles, e.g. "수강신청 마감").
    static func kind(forLine line: String) -> CalendarEvent.Kind? {
        let lowered = line.lowercased()
        if deadlineKeywords.contains(where: lowered.contains) { return .deadline }
        if eventKeywords.contains(where: lowered.contains) { return .event }
        return nil
    }

    /// A date range keeps both ends — the calendar grid dots its first and
    /// last day. On an application/deadline line the
    /// last day is also the deadline ("마감 D-n" counts down to it).
    private static func rangeSchedule(start: Date, end: Date, line: String) -> ExtractedSchedule {
        let lowered = line.lowercased()
        let isDeadlineWindow = applicationKeywords.contains(where: lowered.contains)
            || deadlineKeywords.contains(where: lowered.contains)
        return ExtractedSchedule(startDate: start, endDate: end, hasTime: false, kind: isDeadlineWindow ? .deadline : nil)
    }

    // MARK: - Keywords

    private static let deadlineKeywords = ["마감", "까지", "기한", "deadline", "due", "until"]
    /// A date *range* on a line with one of these is an application window,
    /// so its last day is treated as the deadline (see `rangeSchedule`).
    private static let applicationKeywords = ["신청", "접수", "모집", "제출", "지원", "apply", "application", "registration"]
    private static let eventKeywords = [
        "행사", "대회", "설명회", "특강", "축제", "개최", "일시", "워크숍", "세미나",
        "오리엔테이션", "박람회", "event", "seminar", "workshop"
    ]

    // MARK: - Regex pass

    /// "2026년 9월 2일" / "9월 2일"  or  "2026. 9. 2." / "9.2." / "9/2",
    /// each optionally followed by a weekday in parentheses.
    private static let datePattern = try! NSRegularExpression(pattern: #"""
        (?:
          (?:(?<y1>\d{4})\s*년\s*)?(?<m1>\d{1,2})\s*월\s*(?<d1>\d{1,2})\s*일
          |
          (?<![\d.])(?:(?<y2>\d{4})\s*[.\-/]\s*)?(?<m2>\d{1,2})\s*(?<sep>[./])\s*(?<d2>\d{1,2})(?!\d)(?<trail>\.)?
        )
        (?<wd>\s*\(\s*[월화수목금토일]\s*\))?
        """#, options: [.allowCommentsAndWhitespace])

    /// "오전 10:00", "18:00", "오후 2시 30분" — must directly follow a date.
    private static let timePattern = try! NSRegularExpression(pattern: #"""
        ^[\s,]*(?:\(\s*[월화수목금토일]\s*\)\s*)?
        (?:(?<ampm>오전|오후|am|pm|AM|PM)\s*)?
        (?<h>\d{1,2})\s*(?::\s*(?<min>\d{2})|시(?:\s*(?<kmin>\d{1,2})\s*분)?)
        """#, options: [.allowCommentsAndWhitespace])

    /// Range connector between two dates.
    private static let rangePattern = try! NSRegularExpression(pattern: #"^\s*(?:~|∼|〜|–|-|부터)\s*"#)

    /// "~ 5일" — a range end that omits the month.
    private static let dayOnlyEndPattern = try! NSRegularExpression(pattern: #"^\s*(?<d>\d{1,2})\s*일"#)

    private struct DateMatch {
        var date: Date
        var hasTime: Bool
        var range: NSRange
    }

    private static func regexSchedules(in text: String, postedDate: Date, calendar: Calendar) -> [ExtractedSchedule] {
        var schedules: [ExtractedSchedule] = []

        for line in text.components(separatedBy: .newlines) where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let ns = line as NSString
            let matches = datePattern.matches(in: line, range: NSRange(location: 0, length: ns.length))
                .compactMap { dateMatch(from: $0, in: line, postedDate: postedDate, calendar: calendar) }

            var index = 0
            while index < matches.count {
                let start = matches[index]
                let afterStart = NSMaxRange(start.range)
                let rest = ns.substring(from: afterStart)
                let restRange = NSRange(location: 0, length: (rest as NSString).length)

                // Range: "9.1.~9.5." / "9월 1일 ~ 9월 5일" / "9월 1일 ~ 5일"
                var endDate: Date?
                if let connector = rangePattern.firstMatch(in: rest, range: restRange) {
                    let connectorEnd = afterStart + connector.range.length
                    if index + 1 < matches.count, matches[index + 1].range.location == connectorEnd {
                        endDate = matches[index + 1].date
                        index += 1
                    } else {
                        let afterConnector = ns.substring(from: connectorEnd)
                        if let dayOnly = dayOnlyEndPattern.firstMatch(in: afterConnector, range: NSRange(location: 0, length: (afterConnector as NSString).length)),
                           let day = Int((afterConnector as NSString).substring(with: dayOnly.range(withName: "d"))) {
                            var components = calendar.dateComponents([.year, .month], from: start.date)
                            components.day = day
                            endDate = calendar.date(from: components)
                        }
                    }
                }

                let startDay = calendar.startOfDay(for: start.date)
                if let endDate, calendar.startOfDay(for: endDate) > startDay {
                    schedules.append(rangeSchedule(start: startDay, end: calendar.startOfDay(for: endDate), line: line))
                } else {
                    schedules.append(ExtractedSchedule(
                        startDate: start.date,
                        endDate: startDay,
                        hasTime: start.hasTime,
                        kind: kind(forLine: line)
                    ))
                }
                index += 1
            }
        }
        return schedules
    }

    private static func dateMatch(from match: NSTextCheckingResult, in line: String, postedDate: Date, calendar: Calendar) -> DateMatch? {
        let ns = line as NSString
        func group(_ name: String) -> String? {
            let range = match.range(withName: name)
            return range.location == NSNotFound ? nil : ns.substring(with: range)
        }

        let isKoreanForm = group("m1") != nil
        guard
            let month = Int(group(isKoreanForm ? "m1" : "m2") ?? ""),
            let day = Int(group(isKoreanForm ? "d1" : "d2") ?? ""),
            (1...12).contains(month), (1...31).contains(day)
        else { return nil }

        let year = group(isKoreanForm ? "y1" : "y2").flatMap(Int.init)

        // A bare "3.5" is as likely a GPA or version as a date — only trust
        // the dotted form without a year when it has a trailing dot
        // ("9.2.") or a weekday ("9.2(수)").
        if !isKoreanForm, year == nil, group("sep") == ".", group("trail") == nil, group("wd") == nil {
            return nil
        }

        guard var date = resolve(year: year, month: month, day: day, postedDate: postedDate, calendar: calendar) else { return nil }

        var matchedRange = match.range
        let rest = ns.substring(from: NSMaxRange(match.range))
        let restNS = rest as NSString
        var hasTime = false
        if let time = timePattern.firstMatch(in: rest, range: NSRange(location: 0, length: restNS.length)) {
            func timeGroup(_ name: String) -> String? {
                let range = time.range(withName: name)
                return range.location == NSNotFound ? nil : restNS.substring(with: range)
            }
            if var hour = Int(timeGroup("h") ?? "") {
                let minute = Int(timeGroup("min") ?? timeGroup("kmin") ?? "0") ?? 0
                switch timeGroup("ampm")?.lowercased() {
                case "오후", "pm": if hour < 12 { hour += 12 }
                case "오전", "am": if hour == 12 { hour = 0 }
                default: break
                }
                if (0...23).contains(hour), (0...59).contains(minute),
                   let withTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    date = withTime
                    hasTime = true
                    matchedRange.length += time.range.length
                }
            }
        }

        return DateMatch(date: date, hasTime: hasTime, range: matchedRange)
    }

    /// Year-less dates take the posting year, rolling into the next year
    /// when that would land well before the posting day (a December notice
    /// mentioning "1월 5일").
    private static func resolve(year: Int?, month: Int, day: Int, postedDate: Date, calendar: Calendar) -> Date? {
        let postedYear = calendar.component(.year, from: postedDate)
        guard let date = calendar.date(from: DateComponents(year: year ?? postedYear, month: month, day: day)),
              calendar.component(.day, from: date) == day // rejects "2월 30일"
        else { return nil }

        if year == nil,
           let cutoff = calendar.date(byAdding: .day, value: -60, to: postedDate),
           date < cutoff {
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
        return date
    }

    // MARK: - NSDataDetector fallback

    private static func detectorSchedules(in text: String, postedDate: Date, calendar: Calendar) -> [ExtractedSchedule] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return [] }

        var schedules: [ExtractedSchedule] = []
        for line in text.components(separatedBy: .newlines) {
            let ns = line as NSString
            for match in detector.matches(in: line, range: NSRange(location: 0, length: ns.length)) {
                guard let date = match.date else { continue }
                let matched = ns.substring(with: match.range).lowercased()
                let hasTime = matched.contains(":") || ["am", "pm", "오전", "오후", "시"].contains(where: matched.contains)
                let startDay = calendar.startOfDay(for: date)

                let end = date.addingTimeInterval(match.duration)
                if calendar.startOfDay(for: end) > startDay {
                    schedules.append(rangeSchedule(start: startDay, end: calendar.startOfDay(for: end), line: line))
                } else {
                    schedules.append(ExtractedSchedule(
                        startDate: hasTime ? date : startDay,
                        endDate: startDay,
                        hasTime: hasTime,
                        kind: kind(forLine: line)
                    ))
                }
            }
        }
        return schedules
    }
}
