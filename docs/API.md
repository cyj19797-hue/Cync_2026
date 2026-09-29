# Cync API 명세 업데이트 (2026-08-22, 2026-09-03·09-04 갱신) — iOS 연동 가이드

> 기존 `sjc-app-인계문서-v2.md`의 8장(API 명세) 이후 새로 추가/변경된 API만 정리했습니다. Swift(URLSession, async/await) 기준 실제 호출 코드를 넣었으니, 프로젝트에서 Alamofire를 쓰신다면 요청 구성 방식만 맞춰 옮기시면 됩니다.

## 서버 주소

> ⚠️ **2026-09-03 변경**: 배포 서버 문제로 App Service를 재생성하면서 주소가 바뀌었습니다. 아래 새 주소로 반드시 업데이트해주세요.

```swift
let baseURL = URL(string: "https://cync-backend.azurewebsites.net")!
```

~~이전 주소(더 이상 사용 안 함): `https://cync-backend-evena5hbhjevdsc8.koreacentral-01.azurewebsites.net`~~

---

## 0. 공통 준비물 — 인증 헬퍼

토큰이 필요한 모든 요청에서 재사용할 기본 함수입니다. 로그인 성공 후 `accessToken`을 Keychain 등에 저장해두고, 아래처럼 매 요청 헤더에 실어 보내면 됩니다.

```swift
enum APIClient {
    static let baseURL = URL(string: "https://cync-backend.azurewebsites.net")!

    // 로그인 후 Keychain 등에서 꺼내오는 토큰
    static var accessToken: String? = KeychainHelper.load("accessToken")

    static func authorizedRequest(path: String, method: String, query: [String: String] = [:]) -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // application/x-www-form-urlencoded 바디를 만드는 헬퍼
    // (title, content 같은 @RequestParam 파라미터를 보낼 때 공통으로 사용)
    static func formBody(_ params: [String: String]) -> Data {
        params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)!
    }
}
```

---

## 1. 닉네임 / 프로필 색상

### 모델

```swift
struct MyProfile: Decodable {
    let studentId: String
    let name: String
    let role: String
    let nickname: String
    let profileColor: String
    let banned: Bool
    let banExpiresAt: String?
    let banReason: String?
    let currentlyBanned: Bool
}

enum ProfileColor: String, CaseIterable {
    case red = "RED", orange = "ORANGE", yellow = "YELLOW", green = "GREEN"
    case mint = "MINT", blue = "BLUE", purple = "PURPLE", pink = "PINK", gray = "GRAY"
}
```

### `GET /api/me` — 내 프로필 조회

```swift
func fetchMyProfile() async throws -> MyProfile {
    let request = APIClient.authorizedRequest(path: "/api/me", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(MyProfile.self, from: data)
}
```
앱 진입 시 또는 마이페이지 화면에서 호출해서 `nickname`, `profileColor`를 화면에 반영하면 됩니다. `currentlyBanned`는 6번 섹션에서 활용법을 설명합니다.

### `PUT /api/me/profile` — 닉네임 / 프로필 색상 변경

```swift
func updateMyProfile(nickname: String, color: ProfileColor) async throws -> MyProfile {
    var request = APIClient.authorizedRequest(
        path: "/api/me/profile",
        method: "PUT",
        query: ["nickname": nickname, "profileColor": color.rawValue]
    )
    request.httpBody = nil // 이 API는 쿼리 파라미터로 처리 (POST/PUT 바디 없이 query로 보내도 스프링이 @RequestParam으로 잘 받음)
    let (data, response) = try await URLSession.shared.data(for: request)

    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
        throw NSError(domain: "닉네임 중복 또는 오류", code: httpResponse.statusCode)
    }
    return try JSONDecoder().decode(MyProfile.self, from: data)
}
```
설정 화면에서 닉네임 입력창 + 9가지 색상 팔레트(`ProfileColor.allCases`로 순회하며 그리기)를 만들고, "저장" 버튼에 연결하면 됩니다. 실패 시(중복 닉네임 등) alert로 안내하세요.

---

## 2. 게시글 / 댓글

### 모델

```swift
struct Post: Decodable {
    let id: Int
    let title: String
    let content: String
    let authorId: String
    let authorName: String
    let authorNickname: String?
    let authorColor: String?
    let anonymous: Bool
    let viewCount: Int
    let likeCount: Int
    let commentCount: Int
    let createdAt: String
    let updatedAt: String
}

struct Comment: Decodable {
    let id: Int
    let postId: Int
    let parentCommentId: Int?     // 신규: null이면 최상위 댓글
    let content: String
    let authorId: String
    let authorName: String
    let authorNickname: String?
    let authorColor: String?
    let anonymous: Bool
    let deleted: Bool             // 신규: true면 "삭제된 댓글입니다"
    let createdAt: String
}
```

### 게시글 작성 — `authorName` 파라미터가 사라짐에 유의

```swift
func createPost(title: String, content: String,
                 nickname: String? = nil, color: ProfileColor? = nil,
                 isAnonymous: Bool = false) async throws -> Post {
    var params = ["title": title, "content": content, "isAnonymous": String(isAnonymous)]
    if let nickname { params["nickname"] = nickname }
    if let color { params["color"] = color.rawValue }

    var request = APIClient.authorizedRequest(path: "/api/posts", method: "POST")
    request.httpBody = APIClient.formBody(params)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Post.self, from: data)
}
```
- `nickname`/`color`를 안 넘기면 프로필 기본값이 자동 적용됩니다. 대부분의 경우 이 두 파라미터는 생략하고 호출하면 됩니다.
- 화면에는 `post.authorNickname`을 이름 대신 표시하세요 (`authorName`은 실명이라 익명 글에서도 서버 응답엔 포함되지만, UI에 실명을 노출하면 안 됩니다 — `anonymous == true`일 때는 `authorNickname`만 쓰고 `authorName`은 화면에 절대 그리지 마세요).

### 댓글 작성 — 대댓글(답글) 지원

```swift
func createComment(postId: Int, content: String,
                    parentCommentId: Int? = nil,
                    isAnonymous: Bool = false) async throws -> Comment {
    var params = ["content": content, "isAnonymous": String(isAnonymous)]
    if let parentCommentId { params["parentCommentId"] = String(parentCommentId) }

    var request = APIClient.authorizedRequest(path: "/api/posts/\(postId)/comments", method: "POST")
    request.httpBody = APIClient.formBody(params)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Comment.self, from: data)
}
```

### 댓글 목록을 트리 구조로 그리기

서버는 `parentCommentId`로만 관계를 표시할 뿐, 목록은 flat하게 내려줍니다. 화면에서는 이렇게 그룹핑해서 그리면 됩니다.

```swift
func fetchComments(postId: Int) async throws -> [Comment] {
    let request = APIClient.authorizedRequest(path: "/api/posts/\(postId)/comments", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([Comment].self, from: data)
}

// 화면에서 쓸 트리 구조로 변환
struct CommentNode {
    let comment: Comment
    let replies: [Comment]
}

func buildCommentTree(_ comments: [Comment]) -> [CommentNode] {
    let topLevel = comments.filter { $0.parentCommentId == nil }
    return topLevel.map { top in
        let replies = comments.filter { $0.parentCommentId == top.id }
        return CommentNode(comment: top, replies: replies)
    }
}
```
`comment.deleted == true`인 항목은 리스트 셀에서 회색 텍스트로 "삭제된 댓글입니다" 처리하고, 그 셀의 "답글 달기" 버튼은 숨기세요. 답글(`replies` 배열에 담긴 것)에는 애초에 "답글 달기" 버튼 자체를 안 보이게 하세요 (서버가 1단계까지만 허용).

### 게시글/댓글 삭제 — 호출 방식은 기존과 동일

```swift
func deletePost(id: Int) async throws {
    let request = APIClient.authorizedRequest(path: "/api/posts/\(id)", method: "DELETE")
    _ = try await URLSession.shared.data(for: request)
}

func deleteComment(id: Int) async throws {
    let request = APIClient.authorizedRequest(path: "/api/comments/\(id)", method: "DELETE")
    _ = try await URLSession.shared.data(for: request)
}
```
`deletePost`를 호출하면 서버가 댓글·좋아요까지 알아서 지워주므로, 클라이언트는 그냥 목록에서 해당 셀만 제거하면 됩니다. `deleteComment`는 실제로는 소프트 삭제라서, 삭제 후 댓글 목록을 다시 불러오면 그 댓글이 "삭제된 댓글입니다"로 바뀐 채 그대로 남아있는 걸 확인할 수 있습니다.

---

## 3. 학생회공지 사진 첨부 — multipart 업로드

### 모델

```swift
struct StudentCouncilNotice: Decodable {
    let id: Int
    let title: String
    let content: String
    let imageUrl: String?   // 신규
    let authorId: String
    let authorName: String
    let createdAt: String
    let updatedAt: String
}
```

### 사진 포함 작성 — `multipart/form-data`로 직접 구성

이 API만 요청 형식이 `application/x-www-form-urlencoded`가 아니라 `multipart/form-data`입니다. `UIImage`를 JPEG로 변환해서 파트로 추가합니다.

```swift
func createCouncilNotice(title: String, content: String,
                          authorId: String, authorName: String,
                          image: UIImage?) async throws -> StudentCouncilNotice {
    var request = APIClient.authorizedRequest(path: "/api/notices/council", method: "POST")

    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()

    func appendField(_ name: String, _ value: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }

    appendField("title", title)
    appendField("content", content)
    appendField("authorId", authorId)
    appendField("authorName", authorName)

    if let image, let imageData = image.jpegData(compressionQuality: 0.8) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
    }

    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = body

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(StudentCouncilNotice.self, from: data)
}
```
사진을 안 첨부하고 싶으면 `image: nil`을 넘기면 됩니다 (그 경우 image 파트 자체가 빠지고, 서버는 `imageUrl: null`로 저장합니다).

### 화면에 이미지 표시하기

```swift
if let urlString = notice.imageUrl, let url = URL(string: urlString) {
    AsyncImage(url: url) { image in
        image.resizable().aspectRatio(contentMode: .fit)
    } placeholder: {
        ProgressView()
    }
}
```
`imageUrl`은 인증 없이 바로 열리는 공개 URL이라 `AsyncImage`에 그대로 넣으면 됩니다.

---

## 4. 사물함

> ⚠️ **2026-09-03 변경**: 신청 즉시 대여되던 방식에서 **관리자 승인 방식**으로 전면 변경됐습니다. 대여료(10,000원)를 계좌이체 등으로 받는 걸 확인한 뒤 관리자가 승인하는 구조입니다. `dueDate`(2주 자동 만료) 필드는 완전히 삭제됐고, 반납도 자동이 아니라 관리자가 학기 종료 시점에 수동으로 처리합니다.

### 상태 흐름

```
AVAILABLE ──학생 신청(apply)──> PENDING ──ADMIN 승인(approve)──> IN_USE ──본인/ADMIN 반납(return)──> AVAILABLE
                                    │
                              본인 취소(cancel) 또는 ADMIN 거부(reject)
                                    │
                                    └──────────────────> AVAILABLE

AVAILABLE ←── ADMIN 상태변경(status=AVAILABLE) ── BROKEN ←── ADMIN 상태변경(status=BROKEN) ── AVAILABLE
```

### 모델

```swift
enum LockerStatus: String, Decodable {
    case available = "AVAILABLE"
    case pending = "PENDING"     // 신규: 신청 후 관리자 승인 대기 중
    case inUse = "IN_USE"
    case broken = "BROKEN"
}

struct Locker: Decodable {
    let id: Int
    let lockerNumber: Int
    let location: String?
    let status: LockerStatus
    let currentUserId: String?
    let assignedAt: String?      // 승인된(대여 시작된) 시각. dueDate는 더 이상 없음
    let password: String?        // 본인 사용중/신청중이거나 ADMIN일 때만 값 있음
}
```

### 목록 조회

```swift
func fetchAllLockers() async throws -> [Locker] {
    let request = APIClient.authorizedRequest(path: "/api/lockers", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([Locker].self, from: data)
}

func fetchAvailableLockers() async throws -> [Locker] {
    let request = APIClient.authorizedRequest(path: "/api/lockers/available", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([Locker].self, from: data)
}
```
목록 화면에서 `status`에 따라 색상을 다르게(`.available` → 초록, `.pending` → 노랑/주황, `.inUse` → 회색, `.broken` → 빨강) 표시하면 됩니다.

### 신청 — 이제 즉시 사용이 아니라 승인 대기 상태로 전환됨

```swift
func applyLocker(id: Int) async throws -> Locker {
    let request = APIClient.authorizedRequest(path: "/api/lockers/\(id)/apply", method: "POST")
    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        throw NSError(domain: "이미 신청되었거나 사용 중이거나 신청할 수 없는 사물함입니다.", code: http.statusCode)
    }
    return try JSONDecoder().decode(Locker.self, from: data)
}
```
신청 성공 시 `status`가 `PENDING`으로 바뀝니다. 이때는 **아직 비밀번호가 응답에 안 보입니다** (`password: null`) — 관리자 승인이 나기 전까지는 실제로 쓸 수 없는 상태니까요. 화면에는 "관리자 승인 대기 중, 대여료 10,000원을 계좌이체 후 확인해주세요" 같은 안내를 함께 보여주는 걸 권장합니다.

### 신청 취소 (본인)

```swift
func cancelApplication(id: Int) async throws -> Locker {
    let request = APIClient.authorizedRequest(path: "/api/lockers/\(id)/cancel", method: "POST")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Locker.self, from: data)
}
```
`PENDING` 상태에서만 가능합니다. 마음이 바뀌었거나 결제를 취소하고 싶을 때, 학생이 직접 신청을 취소하는 기능입니다.

### 반납

```swift
func returnLocker(id: Int) async throws {
    let request = APIClient.authorizedRequest(path: "/api/lockers/\(id)/return", method: "POST")
    _ = try await URLSession.shared.data(for: request)
}
```
`IN_USE` 상태에서, 본인 또는 ADMIN만 호출 가능합니다. 자동 만료가 없어졌으므로, 학기가 끝나도 이 API를 누군가(본인 또는 관리자) 직접 호출하기 전까지는 계속 `IN_USE` 상태로 남아있습니다.

### 관리자 — 승인 대기 목록 조회

```swift
func fetchPendingLockers() async throws -> [Locker] {
    let request = APIClient.authorizedRequest(path: "/api/lockers/pending", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([Locker].self, from: data)
}
```
관리자 화면에서 이 목록을 불러와, 각 항목마다 "승인" / "거부" 버튼을 나란히 두면 됩니다. 이 API는 신청자의 `currentUserId`(학번)와 `password`도 함께 내려주니, 관리자가 입금 확인 시 누가 신청했는지 바로 알 수 있습니다.

### 관리자 — 승인 / 거부

```swift
func approveLocker(id: Int) async throws -> Locker {
    let request = APIClient.authorizedRequest(path: "/api/lockers/\(id)/approve", method: "POST")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Locker.self, from: data)
}

func rejectLocker(id: Int) async throws -> Locker {
    let request = APIClient.authorizedRequest(path: "/api/lockers/\(id)/reject", method: "POST")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Locker.self, from: data)
}
```
`approveLocker`를 호출하면 `status`가 `IN_USE`로 바뀌고 `assignedAt`(대여 시작 시각)이 그 순간으로 기록됩니다. 이때부터 학생이 비밀번호를 조회할 수 있게 됩니다. `rejectLocker`는 신청을 반려하고 사물함을 다시 `AVAILABLE`로 되돌립니다.

### 관리자 — 상태 강제 변경 (고장 처리 등)

```swift
func setLockerStatus(id: Int, status: LockerStatus) async throws {
    let request = APIClient.authorizedRequest(
        path: "/api/lockers/\(id)/status",
        method: "PATCH",
        query: ["status": status.rawValue]
    )
    _ = try await URLSession.shared.data(for: request)
}

// 사용 예: 고장 처리
try await setLockerStatus(id: 2, status: .broken)
// 사용 예: 고장 복구
try await setLockerStatus(id: 2, status: .available)
```
`IN_USE`와 `PENDING`으로는 이 API로 직접 바꿀 수 없습니다 (500 에러) — 그 상태들은 각각 `approve`, `apply`를 통해서만 자연스럽게 만들어지도록 서버가 막아둔 것입니다. 관리자 전용 화면에서만 이 함수 호출 버튼을 노출하세요.

---

## 5. 커뮤니티 활동 정지 (관리자 화면용)

```swift
func banUser(studentId: String, days: Int?, reason: String) async throws {
    var query = ["reason": reason]
    if let days { query["days"] = String(days) }   // 안 넘기면 영구 정지
    let request = APIClient.authorizedRequest(
        path: "/api/admin/users/\(studentId)/ban",
        method: "POST",
        query: query
    )
    _ = try await URLSession.shared.data(for: request)
}

func unbanUser(studentId: String) async throws {
    let request = APIClient.authorizedRequest(path: "/api/admin/users/\(studentId)/unban", method: "POST")
    _ = try await URLSession.shared.data(for: request)
}
```
관리자 신고 관리 화면에서, 일수 입력 필드를 비워두면 `days: nil`로 넘겨서 영구 정지가 되도록 UI를 짜면 됩니다.

### 일반 사용자 화면에서 정지 여부에 따라 UI 비활성화하기

```swift
// 앱 진입 시 또는 커뮤니티 탭 진입 시
let profile = try await fetchMyProfile()

if profile.currentlyBanned {
    // 글쓰기/댓글/좋아요 버튼 비활성화, 안내 배너 표시
    showBannedBanner(reason: profile.banReason, until: profile.banExpiresAt)
} else {
    // 평소대로 활성화
}
```
이렇게 미리 확인해두면, 정지된 사용자가 글쓰기를 시도했다가 서버 에러(500)를 받고 나서야 아는 대신, 애초에 버튼이 비활성화되어 있는 자연스러운 UX를 만들 수 있습니다.

---

## 6. 학사일정

### 모델

```swift
struct AcademicSchedule: Decodable {
    let id: Int
    let title: String
    let startDate: String   // "2026-03-03" 형식
    let endDate: String
    let source: String      // "SCHOOL" 또는 "STUDENT_COUNCIL"
    let authorId: String?
}
```

### 전체 조회

```swift
func fetchAcademicSchedules() async throws -> [AcademicSchedule] {
    let request = APIClient.authorizedRequest(path: "/api/academic-schedule", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([AcademicSchedule].self, from: data)
}
```
캘린더 화면에서 `source == "SCHOOL"`이면 파란색, `"STUDENT_COUNCIL"`이면 초록색 같은 식으로 구분해서 표시하면 좋습니다. `startDate`/`endDate`는 `"yyyy-MM-dd"` 문자열이라, `DateFormatter`로 `Date`로 변환해서 캘린더 라이브러리(FSCalendar 등)에 넘기면 됩니다.

```swift
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd"
let date = formatter.date(from: schedule.startDate)
```

### 학생회 일정 추가/수정/삭제 (관리자 화면)

```swift
func createSchedule(title: String, startDate: String, endDate: String) async throws -> AcademicSchedule {
    var request = APIClient.authorizedRequest(path: "/api/academic-schedule", method: "POST")
    request.httpBody = APIClient.formBody(["title": title, "startDate": startDate, "endDate": endDate])
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(AcademicSchedule.self, from: data)
}

func deleteSchedule(id: Int) async throws {
    let request = APIClient.authorizedRequest(path: "/api/academic-schedule/\(id)", method: "DELETE")
    _ = try await URLSession.shared.data(for: request)
}
```
`startDate`/`endDate`는 `"yyyy-MM-dd"` 형식 문자열로 만들어서 넘기면 됩니다 (`DateFormatter`로 `Date` → `String` 변환).

**주의**: `source: "SCHOOL"`인 일정에 `deleteSchedule`이나 수정 함수를 호출하면 서버가 거부합니다(500). 관리자 화면에서 학교 공식 일정 셀에는 수정/삭제 버튼 자체를 안 보이게 하고, `source == "STUDENT_COUNCIL"`인 것에만 버튼을 노출하세요.

---

## 7. 학과공지 — 본문 내용 추가

> ⚠️ **2026-09-04 변경**: 학과공지 크롤러가 이제 목록뿐 아니라 각 게시글의 **본문 내용까지** 함께 긁어옵니다. 기존에는 `sourceUrl`(원문 링크)만 주고 본문은 없었는데, 이제 `content` 필드가 응답에 추가됐습니다.

### 모델

```swift
struct SchoolNotice: Decodable {
    let id: Int
    let articleNo: Int
    let title: String
    let content: String?      // 신규: 게시글 본문 (없을 수도 있어 옵셔널)
    let category: String
    let isNotice: Bool
    let postedDate: String
    let viewCount: Int
    let sourceUrl: String
    let crawledAt: String
}
```

### 조회 — 기존과 동일한 방식, 이제 content도 함께 옴

```swift
func fetchSchoolNotices() async throws -> [SchoolNotice] {
    let url = APIClient.baseURL.appendingPathComponent("/api/notices/school")
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([SchoolNotice].self, from: data)
}
```
로그인 없이 조회 가능합니다 (기존과 동일). 상세 화면에서 `notice.content`를 그대로 본문으로 보여주면 되고, `content`가 `nil`이거나 빈 문자열인 경우(크롤링이 아직 안 됐거나 실패한 극히 일부 케이스)에는 `sourceUrl`로 원문 링크를 대신 보여주는 걸 권장합니다.

**참고**: `content`는 순수 텍스트만 담겨 있고 (원본 HTML의 서식, 이미지는 빠집니다) 줄바꿈은 유지되지 않을 수 있습니다. 표나 이미지가 포함된 공지는 `sourceUrl`(학교 홈페이지 원문)로 안내하는 게 안전합니다.

---

## 8. 앱 자체 공지사항 (버전 업데이트, 서버 점검 등)

새로 추가된 기능입니다. 커뮤니티 게시판이나 학교 공지와는 별개로, **앱 운영진(관리자)이 앱 사용자에게 직접 전달하는 공지**입니다 (예: "v1.2 업데이트 안내", "9/5 새벽 서버 점검").

### 모델

```swift
struct AppNotice: Decodable {
    let id: Int
    let title: String
    let content: String
    let isPopup: Bool     // true면 앱 실행 시 강제로 팝업 표시 대상
    let authorId: String
    let createdAt: String
    let updatedAt: String
}
```

### 전체 목록 조회 — 설정 메뉴의 "공지사항" 화면용

```swift
func fetchAppNotices() async throws -> [AppNotice] {
    let url = APIClient.baseURL.appendingPathComponent("/api/app-notices")
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([AppNotice].self, from: data)
}
```
로그인 없이도 조회 가능합니다. 최신순으로 정렬되어 옵니다. 설정 탭 안의 "공지사항" 메뉴를 누르면 이 목록을 리스트로 보여주면 됩니다. `createdAt`을 날짜로 포맷해서 각 항목에 표시하세요.

### 팝업 대상 조회 — 앱 실행 시 자동 호출

```swift
func fetchPopupNotices() async throws -> [AppNotice] {
    let url = APIClient.baseURL.appendingPathComponent("/api/app-notices/popup")
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([AppNotice].self, from: data)
}
```
**앱이 처음 켜질 때(로그인 화면이든 메인 화면이든) 이 API를 호출**해서, 배열이 비어있지 않으면 그 내용을 팝업(Alert 또는 커스텀 모달)로 강제 표시하세요. 로그인 여부와 무관하게 호출 가능하므로, 로그인 화면 뜨기 직전이나 앱 진입 시점에 걸어두면 됩니다.

```swift
// 사용 예 — 앱 진입 시점
Task {
    let popups = try? await fetchPopupNotices()
    if let first = popups?.first {
        showPopup(title: first.title, message: first.content)
    }
}
```
여러 개가 동시에 `isPopup: true`일 수 있으니, 전부 순서대로 보여줄지 최신 것 하나만 보여줄지는 화면 설계에 맞게 정하시면 됩니다 (배열 순서는 최신순은 아니라서, 필요하면 `createdAt` 기준으로 정렬해서 쓰세요).

### 관리자 — 작성/수정/삭제

```swift
func createAppNotice(title: String, content: String, isPopup: Bool) async throws -> AppNotice {
    var params = ["title": title, "content": content, "isPopup": String(isPopup)]
    var request = APIClient.authorizedRequest(path: "/api/app-notices", method: "POST")
    request.httpBody = APIClient.formBody(params)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(AppNotice.self, from: data)
}

func deleteAppNotice(id: Int) async throws {
    let request = APIClient.authorizedRequest(path: "/api/app-notices/\(id)", method: "DELETE")
    _ = try await URLSession.shared.data(for: request)
}
```
ADMIN 권한이 있는 계정만 성공합니다 (일반 유저는 403/500).

---

## 9. 신고 기능 (게시글/댓글 공용)

새로 추가된 기능입니다. 게시글과 댓글을 **같은 API 하나로** 신고 처리합니다 — 대상이 게시글인지 댓글인지는 `targetType` 파라미터로 구분하고, 둘은 완전히 독립적으로 신고됩니다 (게시글 신고와 그 안의 댓글 신고는 서로 무관한 별개의 신고 건입니다).

### 모델

```swift
enum ReportTargetType: String {
    case post = "POST"
    case comment = "COMMENT"
}

enum ReportReason: String, CaseIterable {
    case spam = "SPAM"             // 스팸 또는 광고성 게시글
    case abuse = "ABUSE"           // 욕설 또는 혐오 표현
    case privacy = "PRIVACY"       // 개인정보 노출
    case falseInfo = "FALSE_INFO"  // 허위 정보
    case other = "OTHER"           // 기타
}

struct Report: Decodable {
    let id: Int
    let targetType: String
    let targetId: Int
    let reporterId: String
    let reason: String
    let detail: String?
    let status: String   // "PENDING" 또는 "RESOLVED"
    let createdAt: String
}
```

### 신고하기 — 게시글/댓글 공통 함수

```swift
func report(targetType: ReportTargetType, targetId: Int,
            reason: ReportReason, detail: String? = nil) async throws -> Report {
    var params = [
        "targetType": targetType.rawValue,
        "targetId": String(targetId),
        "reason": reason.rawValue
    ]
    if let detail, !detail.isEmpty {
        params["detail"] = detail
    }

    var request = APIClient.authorizedRequest(path: "/api/reports", method: "POST")
    request.httpBody = APIClient.formBody(params)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        throw NSError(domain: "이미 신고했거나 대상을 찾을 수 없습니다.", code: http.statusCode)
    }
    return try JSONDecoder().decode(Report.self, from: data)
}
```

**사용 예 — 게시글 신고 버튼**
```swift
try await report(targetType: .post, targetId: post.id, reason: .abuse, detail: "욕설이 포함되어 있습니다")
```

**사용 예 — 댓글 신고 버튼 (같은 함수, targetType만 다름)**
```swift
try await report(targetType: .comment, targetId: comment.id, reason: .spam)
```

첨부해주신 신고 화면(체크박스 5개 + 상세 사유 텍스트박스)을 그대로 쓰시되, "신고 제출하기" 버튼을 누를 때 **어느 화면에서 열렸는지(게시글 상세 vs 댓글 셀)에 따라 `targetType`/`targetId`만 다르게 넘기면** 됩니다. UI 자체는 완전히 재사용 가능합니다.

**제약사항**
- 같은 사용자가 같은 대상(같은 게시글 또는 같은 댓글)을 **두 번 신고할 수 없습니다** — 재시도 시 서버가 에러를 반환하니, "이미 신고한 게시물입니다" 같은 안내를 보여주세요.
- 이미 삭제된 게시글/댓글을 신고하려고 하면 에러가 납니다.

### 관리자 화면 — 신고 목록 조회 및 처리

```swift
func fetchPendingReports() async throws -> [Report] {
    let request = APIClient.authorizedRequest(path: "/api/reports/pending", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([Report].self, from: data)
}

func fetchAllReports() async throws -> [Report] {
    let request = APIClient.authorizedRequest(path: "/api/reports", method: "GET")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([Report].self, from: data)
}

func resolveReport(id: Int) async throws -> Report {
    let request = APIClient.authorizedRequest(path: "/api/reports/\(id)/resolve", method: "POST")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(Report.self, from: data)
}
```
ADMIN 권한이 있는 계정만 호출 가능합니다.

**관리자 처리 흐름 (중요 — 이 API가 자동으로 삭제/정지를 해주지 않습니다)**

`Report`는 신고 접수 및 "확인했다"는 표시만 담당합니다. 실제 조치는 관리자가 신고 내용을 보고, **기존에 이미 있는 다른 API를 조합해서** 처리해야 합니다.

```
1. fetchPendingReports() 로 미처리 신고 목록 확인
2. 신고 내용(reason, detail)을 보고 관리자가 판단
3-A. 삭제가 맞다고 판단
     → targetType == .post 면 DELETE /api/posts/{targetId}
     → targetType == .comment 면 DELETE /api/comments/{targetId}
3-B. 작성자 활동정지가 필요하다고 판단
     → 먼저 GET /api/posts/{targetId} (또는 댓글 목록에서) 조회해서 작성자 학번(authorId) 확인
     → POST /api/admin/users/{authorId}/ban 호출
4. resolveReport(id:) 호출로 이 신고 건을 처리완료 표시
```
관리자 화면에서는 신고 목록 각 항목에 "삭제" / "작성자 정지" / "처리완료" 버튼을 두고, 위 흐름대로 여러 API를 순차 호출하도록 구성하면 됩니다.

---

## 요약 — iOS 구현 시 체크리스트

1. **서버 주소가 `https://cync-backend.azurewebsites.net`으로 변경됨** — `baseURL` 꼭 업데이트
2. **게시글/댓글 작성 시 `authorName` 파라미터 제거** — 화면 입력값으로 실명 받을 필요 없음
3. **댓글은 `parentCommentId`로 트리 그룹핑**해서 그리기, `deleted` 필드로 삭제 표시
4. **학생회공지 작성/수정은 multipart 요청**으로 변경 — 위 예시 코드 그대로 사용
5. **`fetchMyProfile()`을 앱 진입/탭 전환 시 호출**해서 닉네임/색상/정지 여부를 미리 확보
6. **사물함은 신청 즉시 사용이 아니라 관리자 승인 방식(PENDING 단계)으로 변경됨** — `apply` → 대기 화면 → `approve`/`reject`/`cancel`, `dueDate` 필드는 사라짐
7. **학사일정은 일반적인 GET/POST 패턴**과 동일, `source` enum으로 UI 분기
8. **정지 여부(`currentlyBanned`)로 글쓰기 관련 버튼 사전 비활성화** — 서버 에러 이후 대응이 아니라 사전 방지
9. **학과공지에 `content`(본문) 필드 추가됨** — 상세 화면에서 본문을 바로 보여줄 수 있음
10. **앱 자체 공지사항(`AppNotice`) 신규 추가** — 앱 실행 시 `/api/app-notices/popup` 호출해서 팝업 처리, 설정 메뉴에는 `/api/app-notices` 전체 목록 표시
11. **신고 기능(`Report`) 신규 추가** — 게시글/댓글 공용 API, `targetType`으로 구분. 신고 처리는 관리자가 기존 삭제/정지 API를 조합해서 수동으로 진행
