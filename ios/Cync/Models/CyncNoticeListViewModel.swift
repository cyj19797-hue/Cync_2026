//
//  CyncNoticeListViewModel.swift
//  Cync
//
//  Backs "6-2 Cync 공지": load state (loading skeleton / list / empty /
//  error) and pinned-first ordering. `load()` has no API to call yet and ends with an empty list — put
//  the real API call there once the board has an endpoint; the view already
//  handles every state that call can end in.
//

import Foundation

@MainActor
final class CyncNoticeListViewModel: ObservableObject {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var notices: [CyncNotice] = []

    func load() async {
        // Pull-to-refresh keeps the current list on screen instead of
        // swapping back to the skeleton.
        if notices.isEmpty {
            phase = .loading
        }
        // TODO: Cync 공지 API가 생기면 여기서 호출해 `CyncNotice.sortedForList(_:)`로
        // 정렬해 넣기 (실패 시 phase = .failed)
        notices = []
        phase = .loaded
    }
}
