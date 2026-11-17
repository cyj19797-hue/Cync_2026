//
//  AppNoticePopupCard.swift
//  Cync
//
//  The app-launch popup notice card — Figma `743:4865` (시안 A "아이콘
//  카드"), shown by `AppNoticePopupOverlay`. Top to bottom, centered:
//  megaphone in a pale-accent circle, "Cync 공지 · date" label, title,
//  body, buttons; with several notices queued, a "1 / 2" pill sits top right.
//
//  The popup is a summary, not the whole notice: the body shows at most
//  `bodyLineLimit` lines.
//  - Body fits → [확인] + "다시 보지 않기" (as in Figma).
//  - Body cut off → [자세히 보기] (opens the full notice on the Cync 공지
//    detail screen) + "다시 보지 않기 · 닫기".
//  Admins are told about the limit next to the popup switch on the
//  compose screen, so the key point goes first.
//
//  Its own component, not `DialogCard`: this card is rounder (24 vs 20),
//  borderless and centered, and every other popup must keep its look.
//
//  Differences from Figma, on purpose:
//  - No gray "일시 …" info box under the body — `AppNotice` only has a
//    title, body and popup flag, so there's nothing to fill it with.
//  - No images, even if a `CyncNotice` has some (the server has none).
//
//  At very large text sizes the card may still outgrow `maxHeight` (the
//  overlay passes ~75% of the screen); then the title + body area scrolls
//  and the buttons stay put.
//

import SwiftUI

struct AppNoticePopupCard: View {
    let notice: AppNotice
    /// 1-based position of this notice among the queued ones.
    var position: Int = 1
    var total: Int = 1
    /// Tallest the card may get; beyond that the text area scrolls.
    var maxHeight: CGFloat = .infinity
    let onConfirm: () -> Void
    let onDontShowAgain: () -> Void
    let onViewDetail: () -> Void

    /// Body lines shown before the popup switches to "자세히 보기".
    static let bodyLineLimit = 4

    @ScaledMetric(relativeTo: .title3) private var iconCircleSize: CGFloat = 56
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 28
    /// 160% line height on the 15pt body (Figma `leading-[1.6]`).
    @ScaledMetric(relativeTo: .subheadline) private var bodyLineSpacing: CGFloat = 6
    /// 135% line height on the 21pt title.
    @ScaledMetric(relativeTo: .title3) private var titleLineSpacing: CGFloat = 3

    /// Heights of the body as shown (line-limited) and in full — they differ
    /// exactly when the body is cut off.
    @State private var shownBodyHeight: CGFloat = 0
    @State private var fullBodyHeight: CGFloat = 0
    private var isBodyTruncated: Bool { fullBodyHeight > shownBodyHeight + 1 }

    /// Figma's card paddings: 28 top, 24 sides, 16 bottom.
    private static let topPadding: CGFloat = Spacing.sm + Spacing.xxs
    private static let primaryButtonHeight: CGFloat = 52

    var body: some View {
        VStack(spacing: 0) {
            // The text block inline if it fits under `maxHeight`, else
            // scrolling (only at very large text sizes).
            ViewThatFits(in: .vertical) {
                textBlock
                ScrollView { textBlock }
                    .scrollBounceBehavior(.basedOnSize)
            }

            buttons
        }
        .padding(.top, Self.topPadding)
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            if total > 1 {
                orderPill
                    .padding(.top, Spacing.md + Spacing.xxs)
                    .padding(.trailing, Spacing.md)
            }
        }
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: Radius.popupCard))
        .clipShape(RoundedRectangle(cornerRadius: Radius.popupCard))
        // Caps the height offered to the card (the visible card above stays
        // its natural size; the frame itself is invisible).
        .frame(maxHeight: maxHeight)
        // One modal unit: VoiceOver stays inside the card (title → body →
        // buttons, via the sort priorities below).
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Text

    private var textBlock: some View {
        VStack(spacing: 0) {
            icon
                .padding(.bottom, Spacing.md)

            Text(.appNoticePopupLabel(RelativeTime.absoluteDateText(for: SpringDate.parse(notice.createdAt))))
                .font(.appNoticePopupLabel).tracking(Tracking.appNoticePopupLabel)
                .foregroundStyle(Color.eventAccent)
                .multilineTextAlignment(.center)
                .padding(.bottom, Spacing.xxs + 2)
                .accessibilitySortPriority(6)

            Text(verbatim: notice.title)
                .font(.appNoticePopupTitle).tracking(Tracking.appNoticePopupTitle)
                .lineSpacing(titleLineSpacing)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Spacing.cardInset)
                .accessibilityAddTraits(.isHeader)
                .accessibilitySortPriority(10)

            bodyText
                .lineLimit(Self.bodyLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shownBodyHeight = $0 }
                // The same text unlimited, invisible, only to measure.
                .background(alignment: .top) {
                    bodyText
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullBodyHeight = $0 }
                        .hidden()
                        .accessibilityHidden(true)
                }
                // VoiceOver reads the whole body, not the cut-off copy.
                .accessibilityLabel(Text(verbatim: notice.content))
                .accessibilitySortPriority(9)
        }
    }

    private var icon: some View {
        Image(systemName: "megaphone")
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(Color.eventAccent)
            .frame(width: iconCircleSize, height: iconCircleSize)
            .background(Color.eventAccentTint, in: Circle())
            .accessibilityHidden(true)
    }

    private var bodyText: some View {
        Text(verbatim: notice.content)
            .font(.appNoticePopupBody).tracking(Tracking.appNoticePopupBody)
            .lineSpacing(bodyLineSpacing)
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: Spacing.xxs) {
            PrimaryActionButton(
                titleKey: isBodyTruncated ? .appNoticePopupViewDetail : .appNoticePopupConfirm,
                font: .appNoticePopupConfirm,
                tracking: Tracking.appNoticePopupConfirm,
                enabledCornerRadius: Radius.popupButton,
                minHeight: Self.primaryButtonHeight,
                action: isBodyTruncated ? onViewDetail : onConfirm
            )
            .accessibilitySortPriority(8)

            if isBodyTruncated {
                HStack(spacing: 0) {
                    textButton(.appNoticePopupDontShowAgain, color: .gray400, action: onDontShowAgain)
                        .accessibilitySortPriority(7)
                    Circle()
                        .fill(Color.gray400)
                        .frame(width: 3, height: 3)
                        .accessibilityHidden(true)
                    textButton(.appNoticePopupClose, color: .textSecondary, action: onConfirm)
                        .accessibilitySortPriority(7.5)
                }
            } else {
                textButton(.appNoticePopupDontShowAgain, color: .gray400, action: onDontShowAgain)
                    .accessibilitySortPriority(7)
            }
        }
        // Figma has 16 + info box + 24 here; without the box, a single
        // `Spacing.md` keeps the buttons close to the body.
        .padding(.top, Spacing.md)
    }

    private func textButton(_ titleKey: LocalizedStringResource, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titleKey)
                .font(.appNoticePopupDismiss).tracking(Tracking.appNoticePopupDismiss)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var orderPill: some View {
        Text(.appNoticePopupOrder(position, total))
            .font(.appNoticePopupOrder).tracking(Tracking.appNoticePopupOrder)
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Color.surfaceSubtle, in: Capsule())
            .accessibilityLabel(Text(.appNoticePopupOrderAccessibility(total, position)))
            .accessibilitySortPriority(5)
    }
}
