//
//  DialogCard.swift
//  test
//
//  Shared chrome for the two locker application popups (`240:4403`
//  "4-1-1 사물함 신청 팝업" and `243:4742` "4-1-2 사물함 신청 팝업2") — both are a
//  white, rounded-20 card with a `border` (#DDE1E7) stroke, just with
//  different title/body/button content, so the card shape itself is
//  factored out once instead of duplicated per dialog.
//

import SwiftUI

struct DialogCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        // No spacing of its own — every gap comes from `DialogMetrics`
        // (`dialogTitleGap()`, `dialogBodyGap()`), so all dialogs match.
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        // Always as wide as the space the host gives it (screen minus its
        // side padding), so a message wraps at the card's inner edge
        // instead of at whatever width the button row happened to need.
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DialogMetrics.horizontalPadding)
        .padding(.vertical, DialogMetrics.verticalPadding)
        .background(Color.appBackground)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Color.borderLight)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

/// Spacing shared by every popup built on `DialogCard`.
enum DialogMetrics {
    /// Card's inner top/bottom padding.
    static let verticalPadding: CGFloat = Spacing.sm
    /// Card's inner side padding — the same as top/bottom.
    static let horizontalPadding: CGFloat = verticalPadding
    /// Title → body.
    static let titleToBody: CGFloat = 12
    /// Body (message, options, field…) → button row.
    static let bodyToActions: CGFloat = 24
    /// Between two buttons in the row.
    static let actionSpacing: CGFloat = 14
    /// Visible height of a `DialogActionButton` (its touch area stays 44pt).
    static let buttonHeight: CGFloat = 40
}

extension View {
    /// Under a dialog's title: the gap to the body.
    func dialogTitleGap() -> some View {
        padding(.bottom, DialogMetrics.titleToBody)
    }

    /// Under a dialog's body: the gap to the button row.
    func dialogBodyGap() -> some View {
        padding(.bottom, DialogMetrics.bodyToActions)
    }
}

/// A dialog's button row: buttons together at the trailing edge (취소
/// first, then the main action), `DialogMetrics.actionSpacing` apart.
struct DialogActionRow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: DialogMetrics.actionSpacing) {
            Spacer(minLength: 0)
            content
        }
    }
}

#Preview {
    DialogCard {
        Text("미리보기")
            .font(.dialogBody).tracking(Tracking.dialogBody)
    }
    .padding()
}
