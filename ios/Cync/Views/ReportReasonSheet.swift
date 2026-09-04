//
//  ReportReasonSheet.swift
//  test
//
//  Figma: "26 2 창학" file, frames `434:2315` ("커뮤니티 - 신고사유입력") and
//  `434:2347` ("커뮤니티 - 신고사유입력(기타선택)") — the same sheet, the second
//  being the state where "기타" is selected and a free-text field appears.
//  One view covers both, driven by `selectedReason`, rather than
//  duplicating the whole sheet per state (same approach as the calendar
//  screen's empty-state variant).
//
//  Presented via `.sheet(item:)` from CommunityView/CommunityPostDetailView
//  (see Components/CommunityPostActionMenu.swift). `.presentationDetents` +
//  `.presentationDragIndicator(.visible)` give the native rounded-top-corner
//  card and grabber Figma drew as `핸들 영역` — no hand-built handle bar
//  needed.
//

import SwiftUI

struct ReportReasonSheet: View {
    let onSubmit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var otherDetail: String = ""

    private var canSubmit: Bool {
        switch selectedReason {
        case .none: return false
        case .other: return !otherDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .some: return true
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            header

            Divider()
                .overlay(Color.borderLight)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(ReportReason.allCases) { reason in
                    ReportReasonRow(reason: reason, isSelected: selectedReason == reason) {
                        selectedReason = reason
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.top, Spacing.xs)

            if selectedReason == .other {
                PlaceholderTextEditor(
                    text: $otherDetail,
                    placeholder: "신고 사유를 자세히 적어주세요",
                    font: .noticeDate,
                    placeholderColor: .textSecondary,
                    textColor: .textPrimary
                )
                .frame(height: 88)
                .padding(Spacing.sm)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .strokeBorder(Color.borderLight)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.top, Spacing.xxs)
            }

            PrimaryActionButton(titleKey: "신고 제출하기", isEnabled: canSubmit) {
                // TODO: 실제 신고 접수 API(POST /api/community/reports) 연동 필요
                onSubmit()
            }
            .padding(Spacing.md)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Text("신고하기")
                .font(.myLockerTitle)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.gray50))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.sm)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ReportReasonSheet {}
        }
}
