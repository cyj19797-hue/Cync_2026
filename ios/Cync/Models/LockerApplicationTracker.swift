//
//  LockerApplicationTracker.swift
//  Cync
//
//  Remembers, per 학번, which locker the student is waiting on (`PENDING`),
//  so the next locker list can tell "it didn't go through" apart from
//  "never applied". The server has no "rejected" state: a turned-down
//  request — or one cancelled by the admin's 학기 말 전체 반납 with
//  "승인 대기 신청도 함께 취소" — just goes back to `AVAILABLE` and stops
//  being `mine`.
//
//  `LockerViewModel` reads it after every load (see `resolve`).
//  A student-side cancel isn't in the app yet; when it is, call `clear`
//  after a successful cancel so it doesn't read as a rejection.
//

import Foundation

enum LockerApplicationTracker {
    private static func key(_ studentId: String) -> String {
        "lockerPendingApplication.\(studentId)"
    }

    static func pendingLockerNumber(studentId: String) -> Int? {
        UserDefaults.standard.object(forKey: key(studentId)) as? Int
    }

    static func remember(lockerNumber: Int, studentId: String) {
        UserDefaults.standard.set(lockerNumber, forKey: key(studentId))
    }

    static func clear(studentId: String) {
        UserDefaults.standard.removeObject(forKey: key(studentId))
    }

    /// Updates the record from a fresh list and returns the locker number
    /// whose request didn't go through, if any (at most once — the record
    /// is cleared when it's reported).
    ///
    /// - My locker is `PENDING` → remember its number.
    /// - The remembered locker is now mine and `IN_USE` → approved; forget.
    /// - I have another locker → forget (nothing to report).
    /// - I have no locker at all → not approved; report and forget.
    static func resolve(myLocker: Locker?, studentId: String) -> Int? {
        if let myLocker, myLocker.status == .pending {
            remember(lockerNumber: myLocker.lockerNumber, studentId: studentId)
            return nil
        }
        guard let remembered = pendingLockerNumber(studentId: studentId) else { return nil }
        clear(studentId: studentId)
        return myLocker == nil ? remembered : nil
    }
}
