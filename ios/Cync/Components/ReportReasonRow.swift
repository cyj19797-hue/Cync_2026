//
//  ReportReasonRow.swift
//  test
//
//  Figma node `434:2324` ("사유행") — one selectable reason row. Visually a
//  checkbox, but behaves as a single-select radio (only one reason can be
//  the report's cause), matching Figma's `434:2368` "checked" state (coral
//  fill, white checkmark) shown on exactly one row at a time.
//

import SwiftUI

struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.brandPrimary : Color.surface)
                    .frame(width: 20, height: 20)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isSelected ? Color.brandPrimaryDark : Color.borderLight, lineWidth: 1.2)
                    }
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }

                Text(reason.localizedKey)
                    .font(.communityPostBody)
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        ForEach(ReportReason.allCases) { reason in
            ReportReasonRow(reason: reason, isSelected: reason == .other) {}
        }
    }
    .padding()
}
