//
//  ReportSubmittedView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `434:2386` ("커뮤니티 - 신고완료").
//  A small success sheet shown after ReportReasonSheet submits — checkmark
//  badge, confirmation text, and a single "확인" button.
//

import SwiftUI

struct ReportSubmittedView: View {
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.white)
                }

            Text("신고가 접수되었어요")
                .font(.myLockerTitle)
                .foregroundStyle(Color.textPrimary)

            PrimaryActionButton(titleKey: "확인", action: onConfirm)
        }
        .padding(Spacing.md)
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ReportSubmittedView {}
        }
}
