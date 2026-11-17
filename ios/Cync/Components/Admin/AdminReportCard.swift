//
//  AdminReportCard.swift
//  Cync
//
//  Figma component "관리자/신고 카드" (`729:3939`) — one reported target on
//  "관리자 - 신고 관리". Every report on the same post/comment is one card.
//
//    header   [게시글|댓글] [사유]          신고 n건  2시간 전
//    preview  avatar 닉네임 · 시각 / 제목 (posts only) / 본문 ≤2줄 / 작성자 학번
//    detail   ▎ "가장 최근 상세 사유"   (hidden when no report has one)
//    미처리    [삭제] [작성자 정지] [문제없음]
//    처리 완료  preview dimmed, gray tags, green "처리 완료 · 조치 내역"
//
//  The preview box has its own states: a gray skeleton while loading,
//  "댓글 내용을 불러올 수 없어요" (no single-comment API yet — 작성자 정지
//  is disabled since the 학번 is unknown), "이미 삭제된 게시글이에요" (only
//  문제없음 is offered), or a generic load failure.
//
//  The author line reuses `AuthorLine` (compact) + `ProfileAvatar`; the
//  학번 is always shown to the admin, even for anonymous posts — it's
//  what a ban needs.
//
//  Deviation from Figma: reds/greens are deepened for 4.5:1 text contrast
//  (`adminDanger`, `adminSuccess` — see Colors.swift).
//

import SwiftUI

struct AdminReportCard: View {
    enum Preview {
        case loading
        case content(
            authorName: String,
            authorColor: ProfileColor?,
            createdAt: Date,
            title: String?,
            body: String,
            studentId: String
        )
        case unavailable(LocalizedStringResource)
    }

    enum Status {
        /// The three action buttons.
        case pending(canDelete: Bool, canBan: Bool)
        /// Green result line — `summary` nil shows just "처리 완료".
        case resolved(summary: String?)
    }

    let kind: ReportTargetKind
    let reasonKey: LocalizedStringResource
    let count: Int
    let timeText: String
    let preview: Preview
    let detail: String?
    let status: Status
    /// A request is in flight — buttons are disabled.
    var isProcessing = false
    var onDelete: () -> Void = {}
    var onBan: () -> Void = {}
    var onDismiss: () -> Void = {}

    private static let buttonHeight: CGFloat = 40
    private static let avatarSize: CGFloat = 20

    private var isResolved: Bool {
        if case .resolved = status { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.cardInset) {
            header
            previewBox
            if let detail {
                detailQuote(detail)
            }
            footer
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Radius.listCard)
                .fill(Color.appBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.listCard)
                .strokeBorder(Color.borderLight, lineWidth: 1)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.tag) {
            tag(kind == .post ? .adminReportKindPost : .adminReportKindComment,
                text: .textSecondary, fill: .surface)
            tag(reasonKey,
                text: isResolved ? .textSecondary : .adminDanger,
                fill: isResolved ? .surface : .adminDangerTint)
                .layoutPriority(-1)
            Spacer(minLength: 0)
            Text(.adminReportCount(count))
                .font(.adminReportCount).tracking(Tracking.adminReportCount)
                .foregroundStyle(isResolved ? Color.textSecondary : Color.adminDanger)
                .fixedSize()
            Text(timeText)
                .font(.adminFootnote).tracking(Tracking.adminFootnote)
                .foregroundStyle(Color.textSecondary)
                .fixedSize()
        }
        .lineLimit(1)
    }

    private func tag(_ key: LocalizedStringResource, text: Color, fill: Color) -> some View {
        Text(key)
            .font(.adminReportTag).tracking(Tracking.adminReportTag)
            .foregroundStyle(text)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background {
                RoundedRectangle(cornerRadius: Radius.tag)
                    .fill(fill)
            }
    }

    // MARK: - Preview

    private var previewBox: some View {
        VStack(alignment: .leading, spacing: Spacing.tag) {
            switch preview {
            case .loading:
                skeleton
            case let .content(authorName, authorColor, createdAt, title, body, studentId):
                HStack(spacing: Spacing.xxs) {
                    ProfileAvatar(nickname: authorName, color: authorColor, size: Self.avatarSize,
                                  initialFont: .adminReportTag)
                    AuthorLine(authorName: authorName, createdAt: createdAt, style: .compact)
                }
                if let title {
                    Text(verbatim: title)
                        .font(.adminReportTitle).tracking(Tracking.adminReportTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
                Text(verbatim: body)
                    .font(.adminCardBody).tracking(Tracking.adminCardBody)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(5)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(.adminReportAuthorStudentId(studentId))
                    .font(.adminFootnote).tracking(Tracking.adminFootnote)
                    .foregroundStyle(Color.textSecondary)
            case .unavailable(let key):
                Text(key)
                    .font(.adminCardBody).tracking(Tracking.adminCardBody)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background {
            RoundedRectangle(cornerRadius: Radius.chipSelected)
                .fill(Color.gray50)
        }
        .opacity(isResolved ? 0.6 : 1)
        .accessibilityElement(children: .combine)
    }

    /// Gray bars in the shape of the loaded content.
    private var skeleton: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            bar(width: 120, height: 14)
            bar(width: nil, height: 14)
            bar(width: 180, height: 14)
            bar(width: 110, height: 12)
        }
        .accessibilityLabel(Text(.adminReportPreviewLoading))
    }

    private func bar(width: CGFloat?, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.surface)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    // MARK: - Detail

    /// "▎ "욕설이 포함되어 있습니다"" — 3pt bar + the reporter's words.
    private func detailQuote(_ detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.borderLight)
                .frame(width: 3)
            Text(.adminReportDetailQuote(detail))
                .font(.adminCardBody).tracking(Tracking.adminCardBody)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch status {
        case let .pending(canDelete, canBan):
            HStack(spacing: Spacing.xs) {
                if canDelete {
                    actionButton(.adminReportActionDelete, label: .adminDanger, action: onDelete)
                    actionButton(.adminReportActionBan, label: .textPrimary, action: onBan)
                        .disabled(!canBan)
                }
                actionButton(.adminReportActionDismiss, label: .textPrimary, action: onDismiss)
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.6 : 1)
        case .resolved(let summary):
            HStack(spacing: Spacing.tag) {
                Text(.adminReportResolved)
                    .font(.adminReportResult).tracking(Tracking.adminReportResult)
                if let summary {
                    Text(verbatim: "· \(summary)")
                        .font(.adminCardBody).tracking(Tracking.adminCardBody)
                }
            }
            .foregroundStyle(Color.adminSuccess)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.cardInset)
            .padding(.vertical, Spacing.innerBox)
            .background {
                RoundedRectangle(cornerRadius: Radius.chipSelected)
                    .fill(Color.adminSuccessTint)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func actionButton(_ key: LocalizedStringResource, label: Color, action: @escaping () -> Void) -> some View {
        AdminReportActionButton(titleKey: key, labelColor: label, height: Self.buttonHeight, action: action)
    }
}

/// One of the card's three gray buttons — dims itself when disabled
/// (작성자 정지 without a 학번).
private struct AdminReportActionButton: View {
    let titleKey: LocalizedStringResource
    let labelColor: Color
    let height: CGFloat
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(.adminLockerRowAction).tracking(Tracking.adminLockerRowAction)
                .foregroundStyle(isEnabled ? labelColor : Color.gray400)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: height)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(Color.surface)
                }
                // 40pt to look at, 44pt to tap.
                .padding(.vertical, 2)
                .contentShape(Rectangle())
                .padding(.vertical, -2)
        }
        .buttonStyle(.plain)
    }
}

#Preview("미처리 / 처리 완료") {
    ScrollView {
        VStack(spacing: Spacing.cardInset) {
            AdminReportCard(
                kind: .post, reasonKey: .reportReasonAbuse, count: 3, timeText: "2시간 전",
                preview: .content(authorName: "익명", authorColor: nil, createdAt: Date().addingTimeInterval(-7200),
                                  title: "오늘 자료구조 과제 같이 할 사람",
                                  body: "과제 같이 하실 분 구해요. 지난번에 같이 한 사람들은 진짜 … (욕설이 포함된 문장이 이어짐)",
                                  studentId: "22011234"),
                detail: "단톡방 캡처에 욕설이 그대로 있어요",
                status: .pending(canDelete: true, canBan: true)
            )
            AdminReportCard(
                kind: .post, reasonKey: .reportReasonAbuse, count: 3, timeText: "11/14",
                preview: .content(authorName: "익명", authorColor: nil, createdAt: Date().addingTimeInterval(-86400),
                                  title: "오늘 자료구조 과제 같이 할 사람",
                                  body: "과제 같이 하실 분 구해요. 지난번에 같이 한 사람들은 진짜 … (욕설이 포함된 문장이 이어짐)",
                                  studentId: "22011234"),
                detail: "단톡방 캡처에 욕설이 그대로 있어요",
                status: .resolved(summary: "게시글 삭제, 작성자 7일 정지")
            )
        }
        .padding()
    }
}

#Preview("로딩 / 댓글 대체 표시 / 삭제됨") {
    ScrollView {
        VStack(spacing: Spacing.cardInset) {
            AdminReportCard(kind: .post, reasonKey: .reportReasonSpam, count: 1, timeText: "방금",
                            preview: .loading, detail: nil, status: .pending(canDelete: true, canBan: false))
            AdminReportCard(kind: .comment, reasonKey: .reportReasonSpam, count: 1, timeText: "5시간 전",
                            preview: .unavailable(.adminReportCommentUnavailable), detail: nil,
                            status: .pending(canDelete: true, canBan: false))
            AdminReportCard(kind: .post, reasonKey: .reportReasonPrivacy, count: 1, timeText: "11/14",
                            preview: .unavailable(.adminReportPostDeleted),
                            detail: "다른 학생 전화번호가 그대로 올라와 있어요",
                            status: .pending(canDelete: false, canBan: false))
        }
        .padding()
    }
}
