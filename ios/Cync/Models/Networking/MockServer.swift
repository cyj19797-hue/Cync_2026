//
//  MockServer.swift
//  Cync
//
//  TEMP: stand-in for the backend while cync-backend.azurewebsites.net is
//  stopped. While `DevBypass.isEnabled` is on, every `CyncAPI` request is
//  answered here instead of going over the network — same paths, same JSON
//  shapes as the Spring backend, so the decoding / view-model code runs
//  exactly as it would against the real server.
//
//  State (new posts, comments, likes, profile edits, locker applies) lives
//  in memory only and resets on every launch. Signed in as a regular
//  USER, or as the admin (운영진) when `DevBypass.mockRole` is "ADMIN".
//
//  To go back to the real server: set `DevBypass.isEnabled` to `false`.
//  This whole file can then be deleted along with the `DevBypass` checks
//  in `CyncAPI.perform(_:)`, `SessionStore` and `LoginViewModel`.
//

import Foundation

enum DevBypass {
    /// `true` = skip login and answer every API call from `MockServer`.
    static let isEnabled = false
    /// Who the mock signs in as: "USER" (regular student) or "ADMIN"
    /// (운영진 — shows admin-only controls). Server roles are only these two.
    static let mockRole = "USER"
}

final class MockServer: @unchecked Sendable {
    static let shared = MockServer()

    private typealias JSON = [String: Any]

    private let lock = NSLock()
    private let me: JSON = DevBypass.mockRole == "ADMIN"
        ? [
            "studentId": "admin",
            "name": "운영진",
            "role": "ADMIN",
            "nickname": "운영진",
            "profileColor": "BLUE",
            "banned": false,
            "banExpiresAt": NSNull(),
            "banReason": NSNull(),
            "currentlyBanned": false
        ]
        : [
            "studentId": "20231234",
            "name": "홍길동",
            "role": "USER",
            "nickname": "코딩하는펭귄",
            "profileColor": "BLUE",
            "banned": false,
            "banExpiresAt": NSNull(),
            "banReason": NSNull(),
            "currentlyBanned": false
        ]

    private var profile: JSON
    private var posts: [JSON]
    private var comments: [JSON]
    private var likedPostIds: Set<Int> = []
    private var lockers: [JSON]
    private var councilNotices: [JSON]
    private var nextCouncilNoticeId = 100
    private var nextPostId = 100
    private var nextCommentId = 1000

    private init() {
        profile = me
        posts = Self.seedPosts()
        comments = Self.seedComments()
        lockers = Self.seedLockers(myId: me["studentId"] as! String)
        councilNotices = Self.seedCouncilNotices()
    }

    // MARK: - Entry point

    func handle(_ request: URLRequest) async -> (Data, URLResponse) {
        // A short delay so loading states still show like they would online.
        try? await Task.sleep(for: .milliseconds(250))

        let url = request.url!
        let method = request.httpMethod ?? "GET"
        let parts = url.path.split(separator: "/").map(String.init)  // ["api", ...]
        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        let multipart = contentType.hasPrefix("multipart/form-data")
            ? Self.parseMultipart(request.httpBody, contentType: contentType)
            : nil
        let form = multipart?.fields ?? Self.parseForm(request.httpBody)
        let upload = multipart?.file
        let query = Self.parseQuery(url)

        let (status, body) = lock.withLock {
            route(method: method, parts: parts, form: form, query: query, upload: upload)
        }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        return (body, response)
    }

    private func route(method: String, parts: [String], form: [String: String], query: [String: String], upload: Data?) -> (Int, Data) {
        guard parts.first == "api" else { return (404, Data()) }
        // "/api/posts/12/comments" → key "posts/{id}/comments", id "12"
        let rest = parts.dropFirst()
        let id = rest.first(where: { Int($0) != nil }) ?? ""
        let key = method + " " + rest.map { Int($0) != nil ? "{id}" : $0 }.joined(separator: "/")

        switch key {
        // 0. 로그인 — any id/password works.
        case "POST auth/login":
            return ok([
                "accessToken": "mock-token",
                "tokenType": "Bearer",
                "memberInfo": [
                    "major": "컴퓨터공학과",
                    "studentId": profile["studentId"]!,
                    "name": profile["name"]!,
                    "grade": "3",
                    "status": "재학",
                    "completedSemester": "4"
                ]
            ])

        // 1. 프로필
        case "GET me":
            return ok(profile)
        case "PUT me/profile":
            if let nickname = query["nickname"] { profile["nickname"] = nickname }
            if let color = query["profileColor"] { profile["profileColor"] = color }
            // Keep my existing posts/comments in sync, like the server does.
            for i in posts.indices where posts[i]["authorId"] as? String == myId {
                posts[i]["authorNickname"] = profile["nickname"]
                posts[i]["authorColor"] = profile["profileColor"]
            }
            for i in comments.indices where comments[i]["authorId"] as? String == myId {
                comments[i]["authorNickname"] = profile["nickname"]
                comments[i]["authorColor"] = profile["profileColor"]
            }
            return ok(profile)

        // 2. 게시글
        case "GET posts":
            return ok(posts.sorted { ($0["id"] as! Int) > ($1["id"] as! Int) }.map(withLike))
        case "GET posts/{id}":
            guard let i = postIndex(id) else { return (404, Data()) }
            posts[i]["viewCount"] = (posts[i]["viewCount"] as! Int) + 1
            return ok(withLike(posts[i]))
        case "POST posts":
            let now = Self.timestamp(Date())
            let post: JSON = [
                "id": nextPostId,
                "title": form["title"] ?? "",
                "content": form["content"] ?? "",
                "authorId": myId,
                "authorName": profile["name"]!,
                "authorNickname": profile["nickname"]!,
                "authorColor": profile["profileColor"]!,
                "anonymous": form["isAnonymous"] == "true",
                "viewCount": 0, "likeCount": 0, "commentCount": 0,
                "createdAt": now, "updatedAt": now
            ]
            nextPostId += 1
            posts.append(post)
            return ok(withLike(post))
        case "DELETE posts/{id}":
            guard let i = postIndex(id) else { return (404, Data()) }
            let postId = posts[i]["id"] as! Int
            posts.remove(at: i)
            comments.removeAll { $0["postId"] as? Int == postId }
            likedPostIds.remove(postId)
            return text("게시글 삭제 완료")
        case "POST posts/{id}/like":
            guard let i = postIndex(id) else { return (404, Data()) }
            let postId = posts[i]["id"] as! Int
            let count = posts[i]["likeCount"] as! Int
            if likedPostIds.contains(postId) {
                likedPostIds.remove(postId)
                posts[i]["likeCount"] = max(0, count - 1)
                return text("좋아요 취소")
            } else {
                likedPostIds.insert(postId)
                posts[i]["likeCount"] = count + 1
                return text("좋아요 완료")
            }

        // 2b. 댓글
        case "GET posts/{id}/comments":
            guard let postId = Int(id) else { return (404, Data()) }
            return ok(comments.filter { $0["postId"] as? Int == postId })
        case "POST posts/{id}/comments":
            guard let i = postIndex(id) else { return (404, Data()) }
            let comment: JSON = [
                "id": nextCommentId,
                "postId": posts[i]["id"]!,
                "parentCommentId": form["parentCommentId"].flatMap(Int.init) as Any? ?? NSNull(),
                "content": form["content"] ?? "",
                "authorId": myId,
                "authorName": profile["name"]!,
                "authorNickname": profile["nickname"]!,
                "authorColor": profile["profileColor"]!,
                "anonymous": form["isAnonymous"] == "true",
                "deleted": false,
                "createdAt": Self.timestamp(Date())
            ]
            nextCommentId += 1
            comments.append(comment)
            posts[i]["commentCount"] = (posts[i]["commentCount"] as! Int) + 1
            return ok(comment)
        case "DELETE comments/{id}":
            guard let i = commentIndex(id) else { return (404, Data()) }
            comments[i]["deleted"] = true
            if let p = posts.firstIndex(where: { $0["id"] as? Int == comments[i]["postId"] as? Int }) {
                posts[p]["commentCount"] = max(0, (posts[p]["commentCount"] as! Int) - 1)
            }
            return text("댓글 삭제 완료")
        case "PUT comments/{id}":
            guard let i = commentIndex(id) else { return (404, Data()) }
            if let content = form["content"] { comments[i]["content"] = content }
            return ok(comments[i])

        // 9. 신고
        case "POST reports":
            return text("신고 완료")

        // 3. 공지
        case "GET notices/council":
            return ok(councilNotices)
        case "POST notices/council":
            guard isAdmin else { return (403, Data()) }
            // Spring's default 1MB per-file limit, like the real server.
            if let upload, upload.count > Self.maxUploadBytes { return (500, Data()) }
            let now = Self.timestamp(Date())
            let notice: JSON = [
                "id": nextCouncilNoticeId,
                "title": form["title"] ?? "",
                "content": form["content"] ?? "",
                "imageUrl": upload.flatMap(Self.storeUpload) ?? NSNull(),
                "authorId": form["authorId"] ?? myId,
                "authorName": form["authorName"] ?? (profile["name"] as! String),
                "createdAt": now, "updatedAt": now
            ]
            nextCouncilNoticeId += 1
            councilNotices.insert(notice, at: 0)
            return ok(notice)
        case "PUT notices/council/{id}":
            guard isAdmin else { return (403, Data()) }
            guard let i = councilNotices.firstIndex(where: { "\($0["id"]!)" == id }) else { return (500, Data()) }
            if let upload, upload.count > Self.maxUploadBytes { return (500, Data()) }
            if let title = form["title"] { councilNotices[i]["title"] = title }
            if let content = form["content"] { councilNotices[i]["content"] = content }
            // A new image replaces the old one; none sent keeps it.
            if let url = upload.flatMap(Self.storeUpload) { councilNotices[i]["imageUrl"] = url }
            councilNotices[i]["updatedAt"] = Self.timestamp(Date())
            return ok(councilNotices[i])
        case "DELETE notices/council/{id}":
            guard isAdmin else { return (403, Data()) }
            guard let i = councilNotices.firstIndex(where: { "\($0["id"]!)" == id }) else { return (500, Data()) }
            councilNotices.remove(at: i)
            return text("삭제 완료")
        case "GET notices/school":
            return ok(Self.schoolNotices())

        // 4. 사물함
        case "GET lockers":
            return ok(lockers)
        case "GET lockers/available":
            return ok(lockers.filter { $0["status"] as? String == "AVAILABLE" })
        case "POST lockers/{id}/apply":
            guard let i = lockers.firstIndex(where: { "\($0["id"]!)" == id }),
                  lockers[i]["status"] as? String == "AVAILABLE" else { return (400, Data()) }
            lockers[i]["status"] = "PENDING"
            lockers[i]["currentUserId"] = myId
            return ok(lockers[i])

        // 6. 학사일정
        case "GET academic-schedule":
            return ok(Self.schedules())

        default:
            return (404, Data())
        }
    }

    // MARK: - Helpers

    private var myId: String { profile["studentId"] as! String }
    private var isAdmin: Bool { profile["role"] as? String == "ADMIN" }

    private func withLike(_ post: JSON) -> JSON {
        var post = post
        post["likedByMe"] = likedPostIds.contains(post["id"] as! Int)
        return post
    }

    private func postIndex(_ id: String) -> Int? {
        posts.firstIndex { "\($0["id"]!)" == id }
    }

    private func commentIndex(_ id: String) -> Int? {
        comments.firstIndex { "\($0["id"]!)" == id }
    }

    private func ok(_ object: Any) -> (Int, Data) {
        (200, (try? JSONSerialization.data(withJSONObject: object)) ?? Data())
    }

    private func text(_ string: String) -> (Int, Data) {
        (200, Data(string.utf8))
    }

    private static func parseForm(_ body: Data?) -> [String: String] {
        guard let body, let string = String(data: body, encoding: .utf8) else { return [:] }
        var result: [String: String] = [:]
        for pair in string.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard let key = kv.first else { continue }
            result[key] = kv.count > 1 ? (kv[1].removingPercentEncoding ?? kv[1]) : ""
        }
        return result
    }

    private static let maxUploadBytes = 1_048_576

    /// Text fields of a `multipart/form-data` body, plus the (single) file
    /// part's bytes if there is one.
    private static func parseMultipart(_ body: Data?, contentType: String) -> (fields: [String: String], file: Data?) {
        guard let body, let boundary = contentType.components(separatedBy: "boundary=").last else { return ([:], nil) }
        let delimiter = Data("--\(boundary)".utf8)
        let headerEnd = Data("\r\n\r\n".utf8)
        var fields: [String: String] = [:]
        var file: Data?

        var searchStart = body.startIndex
        var partStarts: [Data.Index] = []
        while let range = body.range(of: delimiter, in: searchStart..<body.endIndex) {
            partStarts.append(range.upperBound)
            searchStart = range.upperBound
        }
        for (n, start) in partStarts.enumerated() where n + 1 < partStarts.count {
            // Part runs to just before the next "\r\n--boundary".
            let end = partStarts[n + 1] - delimiter.count - 2
            guard end > start, let split = body.range(of: headerEnd, in: start..<end) else { continue }
            let header = String(decoding: body[start..<split.lowerBound], as: UTF8.self)
            let content = body[split.upperBound..<end]
            guard let nameRange = header.range(of: "name=\"") else { continue }
            let name = String(header[nameRange.upperBound...].prefix { $0 != "\"" })
            if header.contains("filename=") {
                file = Data(content)
            } else {
                fields[name] = String(decoding: content, as: UTF8.self)
            }
        }
        return (fields, file)
    }

    /// Writes an uploaded image to a temp file and returns its URL — the
    /// stand-in for the server's public blob URL (AsyncImage loads it fine).
    private static func storeUpload(_ data: Data) -> String? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mock-notice-\(UUID().uuidString).jpg")
        do {
            try data.write(to: url)
            return url.absoluteString
        } catch {
            return nil
        }
    }

    private static func parseQuery(_ url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dottedDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    private static func timestamp(_ date: Date) -> String { timestampFormatter.string(from: date) }
    private static func ago(hours: Double) -> String { timestamp(Date().addingTimeInterval(-hours * 3600)) }
    private static func day(_ offset: Int) -> String {
        dayFormatter.string(from: Calendar.current.date(byAdding: .day, value: offset, to: Date())!)
    }
    private static func dottedDay(_ offset: Int) -> String {
        dottedDayFormatter.string(from: Calendar.current.date(byAdding: .day, value: offset, to: Date())!)
    }

    // MARK: - Seed data

    private static func post(_ id: Int, _ title: String, _ content: String, author: String, name: String,
                             nickname: String?, color: String?, anonymous: Bool,
                             views: Int, likes: Int, comments: Int, hoursAgo: Double) -> JSON {
        let at = ago(hours: hoursAgo)
        return [
            "id": id, "title": title, "content": content,
            "authorId": author, "authorName": name,
            "authorNickname": nickname as Any? ?? NSNull(),
            "authorColor": color as Any? ?? NSNull(),
            "anonymous": anonymous,
            "viewCount": views, "likeCount": likes, "commentCount": comments,
            "createdAt": at, "updatedAt": at
        ]
    }

    private static func seedPosts() -> [JSON] {
        [
            post(1, "이번 학기 팀플 같이 하실 분", "알고리즘 수업 팀플 인원 구합니다. 관심 있으신 분 댓글 부탁드려요!",
                 author: "20231001", name: "김철수", nickname: "알고리즘장인", color: "GREEN", anonymous: false,
                 views: 42, likes: 3, comments: 2, hoursAgo: 50),
            post(2, "중고 전공서적 나눔합니다", "자료구조, 운영체제 교재 나눔해요. 필요하신 분 댓글 남겨주세요.",
                 author: "20231005", name: "최지훈", nickname: nil, color: nil, anonymous: true,
                 views: 20, likes: 5, comments: 1, hoursAgo: 26),
            post(3, "동아리방 에어컨 고장난 것 같아요", "확인해보니 리모컨은 되는데 실외기가 안 도는 것 같습니다.",
                 author: "20231003", name: "박민수", nickname: "민수", color: "ORANGE", anonymous: false,
                 views: 30, likes: 2, comments: 0, hoursAgo: 8),
            post(4, "도서관 3층 자리 많네요", "시험기간인데 의외로 자리 많아요. 콘센트 있는 자리도 남아있습니다.",
                 author: "20231234", name: "홍길동", nickname: "코딩하는펭귄", color: "BLUE", anonymous: false,
                 views: 15, likes: 1, comments: 1, hoursAgo: 3),
            post(5, "학식 오늘 메뉴 뭐예요?", "점심 뭐 나오는지 아시는 분 ㅠㅠ",
                 author: "20231007", name: "윤서아", nickname: nil, color: nil, anonymous: true,
                 views: 9, likes: 0, comments: 0, hoursAgo: 0.5)
        ]
    }

    private static func comment(_ id: Int, post: Int, parent: Int?, _ content: String, author: String,
                                name: String, nickname: String?, color: String?, anonymous: Bool,
                                hoursAgo: Double) -> JSON {
        [
            "id": id, "postId": post, "parentCommentId": parent as Any? ?? NSNull(),
            "content": content, "authorId": author, "authorName": name,
            "authorNickname": nickname as Any? ?? NSNull(),
            "authorColor": color as Any? ?? NSNull(),
            "anonymous": anonymous, "deleted": false,
            "createdAt": ago(hours: hoursAgo)
        ]
    }

    private static func seedComments() -> [JSON] {
        [
            comment(1, post: 1, parent: nil, "저 관심 있어요! 몇 명 구하시나요?", author: "20231010", name: "김민준",
                    nickname: "민준", color: "PURPLE", anonymous: false, hoursAgo: 48),
            comment(2, post: 1, parent: 1, "2명 더 구해요. 쪽지 드릴게요!", author: "20231001", name: "김철수",
                    nickname: "알고리즘장인", color: "GREEN", anonymous: false, hoursAgo: 47),
            comment(3, post: 2, parent: nil, "운영체제 책 아직 있나요?", author: "20231234", name: "홍길동",
                    nickname: "코딩하는펭귄", color: "BLUE", anonymous: false, hoursAgo: 20),
            comment(4, post: 4, parent: nil, "정보 감사합니다 ㅎㅎ", author: "20231012", name: "박도윤",
                    nickname: nil, color: nil, anonymous: true, hoursAgo: 2)
        ]
    }

    private static func seedLockers(myId: String) -> [JSON] {
        let cycle = ["IN_USE", "AVAILABLE", "AVAILABLE", "BROKEN", "IN_USE", "AVAILABLE"]
        return (1...48).map { number in
            let mine = number == 27
            let status = mine ? "IN_USE" : cycle[number % cycle.count]
            return [
                "id": number,
                "lockerNumber": number,
                "location": "센B202 앞",
                "status": status,
                "currentUserId": mine ? myId : (status == "IN_USE" ? "other-student" : NSNull()),
                "assignedAt": mine ? day(-60) : NSNull(),
                "dueDate": mine ? day(45) : NSNull(),
                "password": mine ? "3847" : NSNull()
            ] as JSON
        }
    }

    private static func seedCouncilNotices() -> [JSON] {
        func notice(_ id: Int, _ title: String, _ content: String, hoursAgo: Double) -> JSON {
            let at = ago(hours: hoursAgo)
            return ["id": id, "title": title, "content": content, "imageUrl": NSNull(),
                    "authorId": "council", "authorName": "학생회", "createdAt": at, "updatedAt": at]
        }
        return [
            notice(1, "기말고사 간식 행사 안내",
                   "기말고사를 맞아 학생회에서 간식을 나눠드립니다.\n\n일시: \(day(7)) 12:00~14:00\n장소: 학생회관 1층 로비\n\n학생증을 꼭 지참해주세요!",
                   hoursAgo: 5),
            notice(2, "사물함 연장 신청 안내",
                   "2학기 사물함 사용 기간 연장 신청을 받습니다.\n\n신청 마감: \(day(10))\n앱 > 사물함 탭에서 신청 가능합니다.",
                   hoursAgo: 30),
            notice(3, "학과 체육대회 참가자 모집",
                   "학과 체육대회 참가자를 모집합니다. 종목은 축구, 농구, 피구입니다.\n\n모집 마감: \(day(3))",
                   hoursAgo: 72)
        ]
    }

    private static func schoolNotices() -> [JSON] {
        func notice(_ id: Int, _ title: String, _ content: String?, category: String, daysAgo: Int, views: Int) -> JSON {
            ["id": id, "articleNo": 9000 + id, "title": title, "content": content as Any? ?? NSNull(),
             "category": category, "notice": false, "postedDate": dottedDay(-daysAgo), "viewCount": views,
             "sourceUrl": "https://www.sejong.ac.kr", "crawledAt": ago(hours: Double(daysAgo * 24))]
        }
        return [
            notice(1, "2026학년도 동계 계절학기 수강신청 안내",
                   "동계 계절학기 수강신청 일정을 안내합니다.\n\n수강신청: \(day(5)) ~ \(day(7))\n등록금 납부: \(day(12))까지",
                   category: "학사", daysAgo: 1, views: 512),
            notice(2, "2학기 기말고사 시간표 공지",
                   "2학기 기말고사 시간표를 공지합니다. 시험 시간 및 강의실을 반드시 확인하세요.",
                   category: "학사", daysAgo: 2, views: 1340),
            notice(3, "졸업논문 제출 안내",
                   "졸업 예정자는 졸업논문을 기한 내 제출해주시기 바랍니다.\n\n제출 마감: \(day(14))",
                   category: "학사", daysAgo: 4, views: 288),
            notice(4, "2027학년도 1학기 휴·복학 신청 안내", nil,
                   category: "학사", daysAgo: 6, views: 401)
        ]
    }

    private static func schedules() -> [JSON] {
        func s(_ id: Int, _ title: String, _ start: Int, _ end: Int, _ source: String) -> JSON {
            ["id": id, "title": title, "startDate": day(start), "endDate": day(end),
             "source": source, "authorId": NSNull()]
        }
        return [
            s(1, "동계 계절학기 수강신청", 5, 7, "SCHOOL"),
            s(2, "기말고사", 25, 31, "SCHOOL"),
            s(3, "기말고사 간식 행사", 7, 7, "STUDENT_COUNCIL"),
            s(4, "사물함 연장 신청 마감", 10, 10, "STUDENT_COUNCIL"),
            s(5, "졸업논문 제출 마감", 14, 14, "SCHOOL"),
            s(6, "학과 체육대회", 3, 3, "STUDENT_COUNCIL")
        ]
    }
}
