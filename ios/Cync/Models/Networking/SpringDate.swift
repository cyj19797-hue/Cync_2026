//
//  SpringDate.swift
//  Cync
//
//  Parses the timestamp/date strings the Spring Boot backend (see
//  `docs/API.md`) sends as plain JSON strings rather than typed dates.
//

import Foundation

enum SpringDate {
    /// `LocalDateTime` fields (`Post`/`Comment` `createdAt`/`updatedAt`) —
    /// `"yyyy-MM-dd'T'HH:mm:ss[.fraction]"`, no timezone offset. Any
    /// fractional-second suffix is stripped before parsing since Jackson's
    /// digit count for it isn't fixed.
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    static func parse(_ string: String) -> Date {
        let withoutFraction = string.split(separator: ".", maxSplits: 1).first.map(String.init) ?? string
        return dateTimeFormatter.date(from: withoutFraction) ?? Date()
    }

    /// `LocalDate` fields (`AcademicSchedule` `startDate`/`endDate`) —
    /// `"yyyy-MM-dd"`.
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parseDay(_ string: String) -> Date? {
        dayFormatter.date(from: string)
    }

    /// `SchoolNotice.postedDate` — `"yyyy.MM.dd"` (dot-separated, from the
    /// department-notice crawler).
    private static let dottedDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    static func parseDottedDay(_ string: String) -> Date? {
        dottedDayFormatter.date(from: string)
    }
}
