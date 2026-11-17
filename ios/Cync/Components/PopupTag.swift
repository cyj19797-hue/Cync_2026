//
//  PopupTag.swift
//  Cync
//
//  The orange "팝업" tag (Figma `734:4276`) — marks a Cync 공지 that pops
//  up when the app launches. Used on the list row and under the detail
//  date, so both look the same. Never shrinks or wraps; a long title next
//  to it truncates instead.
//

import SwiftUI

struct PopupTag: View {
    var body: some View {
        Text(.appNoticeTagPopup)
            .font(.popupTag).tracking(Tracking.popupTag)
            .foregroundStyle(Color.popupTagText)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background {
                RoundedRectangle(cornerRadius: Radius.tag)
                    .fill(Color.popupTagBackground)
            }
    }
}

#Preview {
    PopupTag()
        .padding()
}
