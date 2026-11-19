//
//  TermsAgreementCache.swift
//  Cync
//
//  The last `termsAgreed` the server reported, per 학번. Only a fallback:
//  the server's answer (login response, `GET /api/me`) always decides.
//  When auto login can't reach `/api/me` (offline, timeout), this keeps an
//  agreed student out of the terms screen. Nothing saved → the terms
//  screen shows, and its button re-checks with the server.
//

import Foundation

enum TermsAgreementCache {
    private static func key(_ studentId: String) -> String {
        "termsAgreed.\(studentId)"
    }

    static func value(studentId: String) -> Bool? {
        UserDefaults.standard.object(forKey: key(studentId)) as? Bool
    }

    static func save(_ agreed: Bool, studentId: String) {
        UserDefaults.standard.set(agreed, forKey: key(studentId))
    }
}
