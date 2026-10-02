//
//  AppIntroView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `240:1588` ("1-3 앱 소개"). Shown after
//  `LaunchScreenView` fades out, before `LoginView` — `CyncApp`'s `RootView`
//  keeps this up until "연결하기" is tapped, then switches to `LoginView`.
//
//  Logo reuses the same mark-only `Image` asset as `LaunchScreenView`
//  (the "C" + blue dot, same art as the app icon).
//
//  "연결하기" reuses `PrimaryActionButton` with the login screen's own
//  accent (`eventAccent`, Figma's `primary` style, #36AFFF) plus its
//  `primary_light` border (`eventAccentLight`) — one shared button
//  component instead of a one-off duplicate.
//
//  No UIKit anywhere on this screen — everything is plain `VStack`/`Text`.
//

import SwiftUI

struct AppIntroView: View {
    let onConnect: () -> Void

    /// 기하학적 중앙보다 살짝 위(광학적 중앙)에 두어야 눈에는 가운데로
    /// 보이고, 위쪽 여백이 유독 넓어 보이지 않는다.
    private let opticalCenterOffset: CGFloat = -40

    var body: some View {
        ZStack {
            // 로고 + 소개 문구는 버튼 높이와 무관하게 화면 중앙 기준으로 배치.
            VStack(spacing: Spacing.xs) {
                Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.vertical, Spacing.xl)

                VStack(spacing: Spacing.xs) {
                    Text(.introHeadline)
                        .font(.appIntroTitle).tracking(Tracking.appIntroTitle)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(.introBody)
                        .font(.appIntroBody).tracking(Tracking.appIntroBody)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }
            .offset(y: opticalCenterOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // `TermsAgreementView`와 동일한 하단 버튼 배치/여백.
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                PrimaryActionButton(
                    titleKey: .introConnect,
                    tint: .eventAccent,
                    borderColor: .eventAccentLight,
                    action: onConnect
                )
                .padding(Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    AppIntroView(onConnect: {})
}
