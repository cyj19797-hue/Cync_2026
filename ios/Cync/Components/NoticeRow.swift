//
//  NoticeRow.swift
//  test
//
//  Figma node `44:269` ("공지사항 글") — one notice list entry: title (up to
//  two lines) over "카테고리 · 날짜 · 마감 D-n", with the bookmark centered
//  on the title's first line, so its top lines up with where the text
//  starts. `Spacing.cardInset` from the title, plus `Spacing.xxs` in from
//  the trailing edge.
//  The category text and the bookmark's fill use the category's color
//  (`NoticeCategory.accentColor`).
//  Figma puts the category badge in front of the title, but that cut most
//  titles off after a few characters, so the category moved to the date
//  line as plain text (and is hidden under a specific category filter).
//
//  The hairline divider under each entry (`I44:269;184:1676`, image asset
//  "Frame 121") is not redrawn as a custom asset — `List` already supplies a
//  row separator, so the parent view relies on that instead (see §10 of the
//  design-to-code guide: don't hand-roll separators `List` gives for free).
//
//  The row's tap target is a real `Button` (`.buttonStyle(.plain)`), not a
//  bare `.contentShape(Rectangle()).onTapGesture` — inside a `List`, a plain
//  tap gesture placed beside a sibling `Button` (here, `BookmarkButton`)
//  doesn't reliably fire; `List` only arbitrates correctly between an
//  *outer* row `Button` and an inner nested one (`BookmarkButton` sitting
//  inside this `Button`'s label), which is the pattern below.
//

import SwiftUI

struct NoticeRow: View {
    let notice: Notice
    /// Shows the category in the date line — the list passes `false` once a
    /// specific category filter is selected, where every row's category
    /// would be the same.
    var showsCategory = true
    let onToggleBookmark: () -> Void
    /// Opens the "2-1 공지글" detail card. `nil` keeps the row static (used
    /// by the standalone preview below).
    var onSelect: (() -> Void)?

    var body: some View {
        Button {
            onSelect?()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.cardInset) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(notice.title)
                        .font(.noticeTitle).tracking(Tracking.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: Spacing.xs) {
                        if showsCategory {
                            Text(notice.category.label)
                                .font(.noticeDate).tracking(Tracking.noticeDate)
                                .foregroundStyle(notice.category.accentColor)

                            separatorDot
                        }

                        Text(notice.listDateText)
                            .font(.noticeDate).tracking(Tracking.noticeDate)
                            .foregroundStyle(Color.textSecondary)

                        if let deadlineDays = notice.deadlineDays {
                            separatorDot

                            Text(.noticeDeadline(deadlineDays))
                                .font(.noticeDeadline).tracking(Tracking.noticeDeadline)
                                .foregroundStyle(Color.accentRed)
                        }
                    }
                }

                BookmarkButton(
                    isBookmarked: notice.isBookmarked,
                    tint: notice.category.accentColor,
                    action: onToggleBookmark
                )
                .centeredOnFirstLine(titleSize: 16)
                .padding(.trailing, Spacing.xxs)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.xxs)
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.gray400)
            .frame(width: 4, height: 4)
    }
}

#Preview {
    List {
        ForEach(Notice.mockList) { notice in
            NoticeRow(notice: notice) {}
        }
    }
    .listStyle(.plain)
}

#Preview("북마크 켬 — 학사·학생회, 제목 1·2줄") {
    func sample(_ id: Int, _ category: NoticeCategory, _ title: String) -> Notice {
        Notice(id: id, category: category, title: title, date: Date(), deadlineDays: nil, isBookmarked: true, originalText: "")
    }
    return List {
        NoticeRow(notice: sample(1, .academic, "수강정정 안내")) {}
        NoticeRow(notice: sample(2, .academic, "2026학년도 2학기 교내 장학금 신청 안내 및 제출 서류 변경 사항 공지")) {}
        NoticeRow(notice: sample(3, .studentCouncil, "기말고사 응원 간식 행사")) {}
        NoticeRow(notice: sample(4, .studentCouncil, "[학생회] 기말고사 응원 간식 행사 안내 — 장소와 시간이 변경되었습니다")) {}
    }
    .listStyle(.plain)
}
