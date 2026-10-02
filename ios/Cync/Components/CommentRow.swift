//
//  CommentRow.swift
//  Cync
//
//  Figma node `295:1985` ("댓글") — one comment or reply, in two lines:
//    1. "작성자 · 시간" on the left; heart (+ count), reply, ⋮ on the right
//    2. the comment text
//
//  The actions (heart, reply, delete/report or ⋮) are 12pt icons (the
//  same size as the date and the "글쓴이" tag) with
//  the same 16pt gap between each, packed toward the trailing edge: one
//  that doesn't apply (no reply on a reply, no heart on your own comment)
//  is simply left out and the rest close up. Each keeps a 44×44pt touch
//  area (neighbors' areas overlap slightly at that gap). Icons match the
//  post's own reactions (heart, speech bubble); the bubble opens the
//  comment input as a reply to this comment.
//
//  A reply (`295:2003`) is indented, with a line in the indent joining it
//  to its parent: one continuous stem from the first reply down to the
//  last, with a short branch into each (`connector`). Dividers only sit
//  where a thread ends (`showsDivider`) — not between a comment and its
//  replies — so each thread reads as one group.
//
//  The post author's comments show the same name as the post plus a
//  "글쓴이" in blue text (`AuthorLine.badgeKey`) — "익명 글쓴이 · 9/15".
//
//  ⋮ opens the same `PopupMenu` as the post's (the screen owns the menu;
//  this row only marks where it opens, via `popupMenuAnchor(id:)` with
//  `menuAnchorID`). A deleted comment ("삭제된 댓글입니다", only kept
//  when it still has replies) shows just that text: no author or actions.
//  At large text sizes the actions drop below the author line rather
//  than overlap it.
//

import SwiftUI

struct CommentRow: View {
    /// The stem in a reply's indent — see the header comment.
    enum Connector {
        /// Not a reply.
        case none
        /// A reply with more replies below it: the stem runs on through.
        case continuing
        /// The thread's last reply: the stem ends at its branch.
        case last
    }

    let comment: Comment
    let authorLabel: CommentAuthorLabel
    /// The post's own author name ("익명" or a nickname), shown for
    /// `.postAuthor` comments in front of the "글쓴이" tag.
    var postAuthorName: String = ""
    var connector: Connector = .none
    /// Line under this row — only where a thread ends.
    var showsDivider: Bool = true
    /// `false` on your own comment — no heart to tap there.
    var canLike: Bool = true
    /// This is the comment being replied to — its reply icon turns
    /// `secondaryAccent` instead of gray (no separate "답글 작성 중" strip).
    var isReplyTarget: Bool = false
    /// Which ⋮ items this viewer gets; empty leaves the ⋮ column blank.
    var actions: [CommentAction] = []
    let onLike: () -> Void
    /// `nil` on a reply (the server allows one level of nesting).
    var onReply: (() -> Void)?
    /// ⋮ tapped — the screen opens its `PopupMenu` under this row's anchor.
    var onMore: () -> Void = {}
    /// A direct action icon tapped (delete / report / edit) — see
    /// `showsSingleActionAsIcon`.
    var onAction: (CommentAction) -> Void = { _ in }

    /// When a comment has exactly one action for this viewer, show that
    /// action's own icon (🗑 delete on your comment, ⚑ report on others')
    /// in the ⋮ column instead of ⋮ → menu. Moderators (edit + delete)
    /// still get ⋮. Set to `false` to go back to ⋮ on every comment — the
    /// previous behavior; the menu path below is untouched.
    static let showsSingleActionAsIcon = true

    /// Heart / bubble / delete / report glyphs are drawn into the same
    /// square so they look the same size (SF Symbols at one font size
    /// differ — the heart read smaller than the bubble). Scales with the
    /// text size setting.
    @ScaledMetric(relativeTo: .caption2) private var iconSize: CGFloat = 16

    /// `PopupMenu` anchor id for this comment's ⋮.
    static func menuAnchorID(for comment: Comment) -> String {
        "comment-\(comment.id)"
    }

    private var isReply: Bool { connector != .none }

    /// Vertical padding of a row — also where the author line sits.
    private static let rowPadding: CGFloat = Spacing.cardInset
    /// Visible height of the author/actions line (about the author text's
    /// line height) — where the reply connector branches off.
    private static let actionHeight: CGFloat = 20
    /// Gap between action icons. Narrower than the 44pt touch areas need
    /// to stay apart, so neighbors' touch areas overlap a little in the
    /// middle (a tap there goes to one of the two).
    private static let actionSpacing: CGFloat = 16

    var body: some View {
        content
            .padding(.vertical, Self.rowPadding)
            .padding(.leading, isReply ? Spacing.xl : 0)
            .background(alignment: .topLeading) {
                if isReply {
                    ReplyConnector(
                        branchY: Self.rowPadding + Self.actionHeight / 2,
                        isLast: connector == .last
                    )
                    .stroke(Color.gray300, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: Spacing.xl)
                    .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottom) {
                if showsDivider {
                    Rectangle()
                        .fill(Color.borderLight)
                        .frame(height: 1)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if comment.deleted {
                Text(.commentDeleted)
                    .font(.communityPostBody).tracking(Tracking.communityPostBody)
                    .foregroundStyle(Color.textSecondary)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) {
                        authorLine
                        Spacer(minLength: 0)
                        actionColumns
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        authorLine
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            actionColumns
                        }
                    }
                }

                Text(comment.content)
                    .font(.communityPostBody).tracking(Tracking.communityPostBody)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var authorLine: some View {
        AuthorLine(
            authorName: authorLabel == .postAuthor ? postAuthorName : authorLabel.text,
            createdAt: comment.createdAt,
            badgeKey: authorLabel == .postAuthor ? .commentPostAuthor : nil
        )
    }

    private var actionColumns: some View {
        HStack(spacing: Self.actionSpacing) {
            if canLike { likeButton }
            if let onReply { replyButton(onReply) }
            if Self.showsSingleActionAsIcon, actions.count == 1, let action = actions.first {
                directActionButton(action)
            } else if !actions.isEmpty {
                menu
            }
        }
    }

    private var likeButton: some View {
        Button(action: onLike) {
            HStack(spacing: Spacing.xxs) {
                ReactionIcon(systemName: comment.isLikedByMe ? "heart.fill" : "heart", size: iconSize)
                // Same as the post's heart, except 0 is left out.
                if comment.likeCount > 0 {
                    Text(comment.likeCount, format: .number)
                }
            }
            .font(.communityReactionCount).tracking(Tracking.communityReactionCount)
            .foregroundStyle(comment.isLikedByMe ? Color.eventAccent : Color.textSecondary)
            .touchArea(iconSize: iconSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.commentLike))
        .accessibilityValue(comment.likeCount > 0 ? Text(comment.likeCount, format: .number) : Text(verbatim: ""))
        .accessibilityAddTraits(comment.isLikedByMe ? .isSelected : [])
    }

    private func replyButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ReactionIcon(systemName: "bubble.right", size: iconSize)
                .foregroundStyle(isReplyTarget ? Color.secondaryAccent : Color.textSecondary)
                .touchArea(iconSize: iconSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.commentReplyShort))
        .accessibilityAddTraits(isReplyTarget ? .isSelected : [])
    }

    /// The one action this viewer has on the comment, as its own icon.
    private func directActionButton(_ action: CommentAction) -> some View {
        let (symbol, label): (String, LocalizedStringResource) = switch action {
        case .delete: ("trash", .commentDelete)
        case .report: ("flag", .commentReport)
        case .edit: ("pencil", .commentEdit)
        }
        return Button {
            onAction(action)
        } label: {
            ReactionIcon(systemName: symbol, size: iconSize)
                .foregroundStyle(Color.textSecondary)
                .touchArea(iconSize: iconSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private var menu: some View {
        Button(action: onMore) {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.communityReactionCount)
                .foregroundStyle(Color.textSecondary)
                .touchArea(iconSize: iconSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.commentMore))
        .popupMenuAnchor(id: Self.menuAnchorID(for: comment))
    }
}

/// An SF Symbol fitted into a `size`×`size` square, so different glyphs
/// (heart, bubble, trash, flag) come out the same visual size.
struct ReactionIcon: View {
    let systemName: String
    let size: CGFloat

    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .fontWeight(.regular)
            .frame(width: size, height: size)
    }
}

private extension View {
    /// Inside a button's label: at least an `iconSize` square on screen,
    /// with a tappable shape grown on every side to 44×44pt (16pt each way
    /// for a 12pt icon) that doesn't change the layout. It has to be on the label — a
    /// content shape on a view *around* the button doesn't make the button
    /// itself respond there.
    func touchArea(iconSize: CGFloat) -> some View {
        frame(minWidth: iconSize, minHeight: iconSize)
            .minimumHitTarget(inset: max(12, (44 - iconSize) / 2))
    }
}

/// The stem in a reply's indent: down the middle of the indent (all the
/// way through, or only to the branch on the last reply), then a short
/// branch across to the reply at `branchY`.
private struct ReplyConnector: Shape {
    let branchY: CGFloat
    let isLast: Bool

    /// Length of the branch into the reply.
    private static let branchLength: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let x = rect.midX
        var path = Path()
        path.move(to: CGPoint(x: x, y: rect.minY))
        path.addLine(to: CGPoint(x: x, y: isLast ? branchY : rect.maxY))
        path.move(to: CGPoint(x: x, y: branchY))
        path.addLine(to: CGPoint(x: x + Self.branchLength, y: branchY))
        return path
    }
}

#Preview {
    VStack(spacing: 0) {
        CommentRow(comment: Comment.mockList[0], authorLabel: .anonymous(number: 1), showsDivider: false, actions: [.report], onLike: {}, onReply: {})
        CommentRow(comment: Comment.mockList[3], authorLabel: .postAuthor, postAuthorName: "익명", connector: .continuing, showsDivider: false, canLike: false, actions: [.delete], onLike: {})
        CommentRow(comment: Comment.mockList[3], authorLabel: .anonymous(number: 2), connector: .last, actions: [.report], onLike: {})
    }
    .padding()
}
