//
//  CalendarEventDetailOverlay.swift
//  Cync
//
//  The notice detail card (`NoticeDetailView`) opened by tapping an event
//  row on 캘린더 or "N월 전체 일정" — the same dim-backdrop card the
//  공지사항 tab shows. Each screen puts this on top of its content in a
//  `ZStack` (with `.animation(.noticeDetail, value: selectedEvent?.id)`), as
//  `NoticeListView` does.
//
//  An event from a bookmarked notice shows that notice in full; a server
//  schedule shows its title, category and period (`NoticeDetailContent`).
//
//  Removing the bookmark of a notice event doesn't close the card: the
//  icon just goes empty, and tapping it again puts the bookmark back. The
//  removal is applied when the card closes — only then do the notice's
//  dates leave the calendar (`CalendarViewModel.toggleBookmark`). Closing
//  it right away read like the app had crashed.
//

import SwiftUI

struct CalendarEventDetailOverlay: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var selectedEvent: CalendarEvent?

    /// The open notice's bookmark was taken off — applied in `close()`.
    @State private var isRemovalPending = false

    var body: some View {
        if let event = selectedEvent, let content = viewModel.detailContent(for: event) {
            NoticeDetailView(
                content: shown(content),
                onToggleBookmark: {
                    if event.sourceNoticeId != nil {
                        isRemovalPending.toggle()
                    } else {
                        // Server schedule: a local flag, nothing leaves the list.
                        viewModel.toggleBookmark(for: event)
                    }
                },
                onDismiss: close,
                showsNavigationBar: false
            )
            .noticeDetailTransition()
        }
    }

    private func shown(_ content: NoticeDetailContent) -> NoticeDetailContent {
        var content = content
        if isRemovalPending { content.isBookmarked = false }
        return content
    }

    private func close() {
        if isRemovalPending, let event = selectedEvent {
            viewModel.toggleBookmark(for: event)
        }
        isRemovalPending = false
        selectedEvent = nil
    }
}
