//
//  LockerApplicationAccountDialog.swift
//  test
//
//  Figma: "26 2 창학" file, frame `243:4742` ("4-1-2 사물함 신청 팝업2").
//  Shown after "신청" is tapped on LockerApplicationConfirmDialog — bank
//  transfer instructions + a single "확인" button. Same dimmed-backdrop
//  overlay presentation as LockerApplicationConfirmDialog.
//

import SwiftUI

struct LockerApplicationAccountDialog: View {
    let onConfirm: () -> Void

    // TODO: Figma의 목업 문구("듀듀은행 123456-01-987654 듀듀듓 / 10,000원 입금이엇나 ...")는
    // 자리표시용 더미 텍스트라 실제 학과 계좌/입금 안내 문구로 교체 필요.
    // 문구 원본은 `Localizable.xcstrings`의 `locker.accountInfo` 키 (ko/en).
    private let accountInfoText: LocalizedStringResource = .lockerAccountInfo

    var body: some View {
        DialogCard {
            Text(.lockerAccountTitle)
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .dialogTitleGap()

            Text(accountInfoText)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textPrimary)
                .dialogBodyGap()

            DialogActionRow {
                DialogActionButton(titleKey: .commonOk, action: onConfirm)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        LockerApplicationAccountDialog {}
            .padding(.horizontal, Spacing.md)
    }
}
