//
//  NicknameSetupStore.swift
//  Cync
//
//  Tracks, per account, whether the user has ever gone through
//  `ProfileSetupView`'s one-time nickname setup gate on "5 커뮤니티". The
//  backend has no field for this (`GET /api/me`'s `nickname` is never empty
//  — the server auto-assigns a default when one isn't provided, see
//  `docs/API.md` §2's "nickname/color를 안 넘기면 프로필 기본값이 자동
//  적용됩니다"), so there's no way to derive "never explicitly set" from the
//  profile response alone. This is local, on-device state instead — keyed by
//  `studentId` (not a single flag) so multiple accounts on the same device
//  don't share completion status, same pattern as `LoginViewModel`'s
//  per-device "학번 기억하기".
//

import Foundation

enum NicknameSetupStore {
    private static func key(for studentId: String) -> String {
        "hasCompletedNicknameSetup_\(studentId)"
    }

    static func hasCompletedSetup(for studentId: String) -> Bool {
        UserDefaults.standard.bool(forKey: key(for: studentId))
    }

    static func markCompleted(for studentId: String) {
        UserDefaults.standard.set(true, forKey: key(for: studentId))
    }
}
