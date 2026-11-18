//
//  NoticeListViewModel.swift
//  test
//
//  Backs NoticeListView with the real `GET /api/notices/council` (mostly
//  empty — no one's posted there yet) and `GET /api/notices/school`
//  (`docs/API.md` §3 / §7) calls, merged into one list — see
//  `Notice.init(councilNotice:)` / `Notice.init(schoolNotice:)`.
//
//  Bookmarking reads/writes `BookmarkStore` — see its header comment —
//  which is what surfaces bookmarked notices on "캘린더" too.
//

import Combine
import Foundation

@MainActor
final class NoticeListViewModel: ObservableObject {
    @Published var notices: [Notice] = []
    @Published var selectedCategory: NoticeCategory = .all
    @Published var searchText: String = ""
    @Published var errorMessage: String?
    /// Shows the 공지 작성 button and the detail's 수정/삭제 menu. Only the
    /// server enforces it — these are just hidden for everyone else.
    @Published private(set) var isAdmin = CurrentUserSession.shared.profile?.isAdmin ?? false
    private var bookmarkSubscription: AnyCancellable?

    init() {
        // Bookmarks also change outside this tab (removed from a 캘린더
        // event's detail card). Without following them, the row kept its
        // filled bookmark — and tapping it then *added* the bookmark back,
        // since `BookmarkStore.toggle` saw it as not saved.
        bookmarkSubscription = BookmarkStore.shared.$bookmarkedNotices
            .sink { [weak self] saved in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    let ids = Set(saved.map(\.id))
                    for index in self.notices.indices where self.notices[index].isBookmarked != ids.contains(self.notices[index].id) {
                        self.notices[index].isBookmarked.toggle()
                    }
                }
            }
    }

    func load() async {
        // Who's signed in decides the admin controls; a failure here just
        // leaves them hidden and doesn't block the list.
        Task {
            if let profile = try? await CurrentUserSession.shared.refresh() {
                isAdmin = profile.isAdmin
            }
        }
        do {
            async let council = CyncAPI.fetchCouncilNotices()
            async let school = CyncAPI.fetchSchoolNotices()
            let councilNotices = try await council
            let schoolNotices = try await school
            let merged = councilNotices.map(Notice.init(councilNotice:)) + schoolNotices.map(Notice.init(schoolNotice:))
            // Drop bookmarks of notices no longer on the server (→ 캘린더).
            BookmarkStore.shared.sync(with: merged)
            notices = merged
                .map { notice in
                    var notice = notice
                    notice.isBookmarked = BookmarkStore.shared.isBookmarked(notice.id)
                    return notice
                }
                .sorted { $0.date > $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var filteredNotices: [Notice] {
        notices.filter { notice in
            let matchesCategory = selectedCategory == .all || notice.category == selectedCategory
            let matchesSearch = searchText.isEmpty || notice.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    func toggleBookmark(for notice: Notice) {
        guard let index = notices.firstIndex(where: { $0.id == notice.id }) else { return }
        notices[index].isBookmarked = BookmarkStore.shared.toggle(notices[index])
    }

    // MARK: - 학생회 공지 (admin)

    /// A notice just written — goes to the top (it's the newest).
    func insertCouncilNotice(_ councilNotice: CouncilNotice) -> Notice {
        let notice = Notice(councilNotice: councilNotice)
        notices.insert(notice, at: 0)
        return notice
    }

    /// An edited notice, in place. Keeps the row's bookmark state.
    func replaceCouncilNotice(_ councilNotice: CouncilNotice) -> Notice {
        var notice = Notice(councilNotice: councilNotice)
        if let index = notices.firstIndex(where: { $0.id == notice.id }) {
            notice.isBookmarked = notices[index].isBookmarked
            notices[index] = notice
        }
        return notice
    }

    func deleteCouncilNotice(_ notice: Notice) async throws {
        guard let councilId = notice.councilId else { return }
        try await CyncAPI.deleteCouncilNotice(id: councilId)
        notices.removeAll { $0.id == notice.id }
        BookmarkStore.shared.remove(noticeId: notice.id)
    }

    func notice(before notice: Notice) -> Notice? {
        guard let index = filteredNotices.firstIndex(where: { $0.id == notice.id }), index > 0 else { return nil }
        return filteredNotices[index - 1]
    }

    func notice(after notice: Notice) -> Notice? {
        guard let index = filteredNotices.firstIndex(where: { $0.id == notice.id }), index < filteredNotices.count - 1 else { return nil }
        return filteredNotices[index + 1]
    }
}
