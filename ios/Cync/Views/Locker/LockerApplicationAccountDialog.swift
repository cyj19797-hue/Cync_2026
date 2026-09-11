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
    private let accountInfoText: LocalizedStringKey = """
    듀듀은행 123456-01-987654 (예금주: 컴퓨터공학과 학생회)
    사물함 이용료 10,000원을 입금해 주세요.
    입금자명은 "학번+이름"으로 입력해 주세요.
    확인 후 승인까지 최대 2~3일 소요됩니다.
    """

    var body: some View {
        DialogCard {
            Text("계좌 안내")
                .font(.dialogTitle).tracking(Tracking.dialogTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            Text(accountInfoText)
                .font(.dialogBody).tracking(Tracking.dialogBody)
                .foregroundStyle(Color.textPrimary)
                .padding(.bottom, Spacing.xxs)

            HStack {
                Spacer(minLength: 0)
                DialogActionButton(titleKey: "확인", action: onConfirm)
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
