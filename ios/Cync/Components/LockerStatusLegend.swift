//
//  LockerStatusLegend.swift
//  Cync
//
//  Color key shown above the "전체 사물함" map on LockerView — no
//  background, square swatches shaped like the map's cells, four entries
//  (신청 가능 · 승인 대기중 · 사용 불가 · 내 사물함). Colors and labels come
//  from `LockerCellStatus.color`/`legendLabel`, the same source the map's
//  cells use.
//
//  One line when it fits; otherwise (very large text sizes) it drops to a
//  2×2 grid instead of truncating the labels.
//

import SwiftUI

struct LockerStatusLegend: View {
    private static let statuses: [LockerCellStatus] = [.empty, .pending, .occupied, .selected]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.md) {
                ForEach(Self.statuses, id: \.self) { status in
                    entry(status)
                        .fixedSize()
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                alignment: .leading,
                spacing: Spacing.xs
            ) {
                ForEach(Self.statuses, id: \.self) { status in
                    entry(status)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func entry(_ status: LockerCellStatus) -> some View {
        HStack(spacing: Spacing.xxs + 2) {
            RoundedRectangle(cornerRadius: 3)
                .fill(status.color)
                .overlay {
                    if status.needsLegendBorder {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Color.borderLight)
                    }
                }
                .frame(width: 12, height: 12)
            Text(verbatim: status.legendLabel)
                .font(.lockerLocationText).tracking(Tracking.lockerLocationText)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        }
    }
}
