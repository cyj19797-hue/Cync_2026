//
//  AdminBanFormFields.swift
//  Cync
//
//  The two inputs every ban form has — shared by the report screen's
//  "작성자 활동 정지" card (`AdminBanCard`, Figma `731:4209`) and the
//  학번-entry "활동 정지 관리" screen, so both look and behave the same:
//
//  - `AdminBanPeriodPicker`: "정지 기간" + `SelectableChip` (`.tab`) row
//    1일 / 3일 / 7일 / 30일 / 영구, 6pt apart (Figma `731:4225`).
//  - `AdminBanReasonField`: "사유" + a `LabeledInputField` (required).
//  - `AdminStudentIdField`: "학번" + a number-pad `LabeledInputField`
//    ("활동 정지 관리" only).
//
//  Deviation from Figma: the reason box is the app's bordered
//  `LabeledInputField` (blue border while editing, ⓧ to clear) instead of
//  Figma's gray filled box, so it matches every other text field.
//

import SwiftUI

/// How long a ban lasts. `days == nil` is permanent.
enum AdminBanPeriod: CaseIterable, Hashable {
    case oneDay, threeDays, sevenDays, thirtyDays, permanent

    /// Pre-selected in every ban form.
    static let `default`: AdminBanPeriod = .sevenDays

    var days: Int? {
        switch self {
        case .oneDay: return 1
        case .threeDays: return 3
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .permanent: return nil
        }
    }

    /// Chip label — "7일" / "영구".
    var labelKey: LocalizedStringResource {
        days.map { LocalizedStringResource.adminBanPeriodDays($0) } ?? .adminBanPeriodPermanent
    }

    /// Main button — "7일 정지하기" / "영구 정지하기".
    var confirmKey: LocalizedStringResource {
        days.map { LocalizedStringResource.adminBanConfirmDays($0) } ?? .adminBanConfirmPermanent
    }
}

/// Section title over an admin form block ("학번", "정지 기간", "사유",
/// "이 기기에서 처리한 내역").
struct AdminFormLabel: View {
    let key: LocalizedStringResource

    var body: some View {
        Text(key)
            .font(.adminFormLabel).tracking(Tracking.adminFormLabel)
            .foregroundStyle(Color.textPrimary)
    }
}

struct AdminBanPeriodPicker: View {
    @Binding var selection: AdminBanPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            AdminFormLabel(key: .adminBanPeriodTitle)
            HStack(spacing: Spacing.tag) {
                ForEach(AdminBanPeriod.allCases, id: \.self) { period in
                    SelectableChip(
                        titleKey: period.labelKey,
                        isSelected: selection == period,
                        appearance: .tab
                    ) {
                        selection = period
                    }
                }
            }
        }
    }
}

struct AdminBanReasonField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            AdminFormLabel(key: .adminBanReasonTitle)
            LabeledInputField(
                placeholder: .adminBanReasonPlaceholder,
                text: $text,
                showsClearButton: true
            )
            .accessibilityLabel(Text(.adminBanReasonTitle))
        }
    }
}

struct AdminStudentIdField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            AdminFormLabel(key: .adminBanManageStudentIdTitle)
            LabeledInputField(
                placeholder: .adminBanManageStudentIdPlaceholder,
                text: $text,
                keyboardType: .numberPad,
                showsClearButton: true
            )
            .accessibilityLabel(Text(.adminBanManageStudentIdTitle))
            // No spaces — pasted "2201 1234" becomes "22011234".
            .onChange(of: text) { _, newValue in
                let trimmed = newValue.filter { !$0.isWhitespace }
                if trimmed != newValue { text = trimmed }
            }
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var period = AdminBanPeriod.default
        @State private var reason = "욕설 또는 혐오 표현 (신고 3건)"
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.md) {
                AdminBanPeriodPicker(selection: $period)
                AdminBanReasonField(text: $reason)
            }
            .padding()
        }
    }
    return PreviewHost()
}
