//
//  LoginCredentials.swift
//  Cync
//
//  Unused — `CyncAPI.login(studentId:password:)` takes the two fields
//  directly rather than this struct. Kept in case a caller wants to pass
//  credentials around as one value.
//

import Foundation

struct LoginCredentials {
    var studentId: String
    var password: String
}
