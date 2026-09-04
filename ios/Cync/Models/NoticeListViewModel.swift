//
//  NoticeListViewModel.swift
//  test
//
//  Backs NoticeListView with the real `GET /api/notices/council` call
//  (`docs/API.md` §3) — see `Notice.init(councilNotice:)` for the mapping.
//

import Combine
import Foundation

@MainActor
final class NoticeListViewModel: ObservableObject {
    @Published var notices: [Notice] = []
    @Published var selectedCategory: NoticeCategory = .all
    @Published var searchText: String = ""
    @Published var errorMessage: String?

    func load() async {
        do {
            let councilNotices = try await CyncAPI.fetchCouncilNotices()
            notices = councilNotices.map(Notice.init(councilNotice:)).sorted { $0.date > $1.date }
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
        notices[index].isBookmarked.toggle()
    }

    /// The notice shown before/after `notice` in the currently filtered,
    /// on-screen order — backs the "이전 글"/"다음 글" controls on
    /// NoticeDetailView. `nil` at either end disables that control.
    func notice(before notice: Notice) -> Notice? {
        guard let index = filteredNotices.firstIndex(where: { $0.id == notice.id }), index > 0 else { return nil }
        return filteredNotices[index - 1]
    }

    func notice(after notice: Notice) -> Notice? {
        guard let index = filteredNotices.firstIndex(where: { $0.id == notice.id }), index < filteredNotices.count - 1 else { return nil }
        return filteredNotices[index + 1]
    }
}
