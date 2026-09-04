//
//  LockerApplicationConfirmDialog.swift
//  test
//
//  Figma: "26 2 창학" file, frame `240:4403` ("4-1-1 사물함 신청 팝업").
//  Locker number + location, a confirmation message, and 취소/신청 buttons.
//  Presented as a dimmed-backdrop overlay from LockerApplicationView — same
//  pattern as NoticeDetailView ("2-1 공지글"), not a system `.sheet`/`.alert`,
//  since neither can reproduce this exact floating rounded-20 card look.
//

import SwiftUI

struct LockerApplicationConfirmDialog: View {
    let locker: Locker
    let location: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        DialogCard {
            HStack(alignment: .lastTextBaseline, spacing: Spacing.xxs) {
                Text("\(String(format: "%03d", locker.lockerNumber))번")
                    .font(.noticeDetailTitle)
                Text(location)
                    .font(.categoryBadge)
            }
            .foregroundStyle(Color.textPrimary)

            Text("사물함을 신청하시겠습니까?")
                .font(.dialogBody)
                .foregroundStyle(Color.textPrimary)
                .padding(.vertical, Spacing.xxs)

            HStack(spacing: Spacing.sm) {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: "취소", action: onCancel)
                DialogActionButton(titleKey: "신청", style: .primary, action: onConfirm)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        LockerApplicationConfirmDialog(
            locker: Locker(id: 128, lockerNumber: 128, location: "센 B03 뒷문 방향", status: .available, currentUserId: nil, assignedAt: nil, dueDate: nil, password: nil),
            location: "센 B03 뒷문 방향",
            onCancel: {},
            onConfirm: {}
        )
        .padding(.horizontal, Spacing.md)
    }
}
