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
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            content
        }
        .padding(Spacing.sm)
        .background(Color.appBackground)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Color.borderLight)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

#Preview {
    DialogCard {
        Text("미리보기")
            .font(.dialogBody).tracking(Tracking.dialogBody)
    }
    .padding()
}
