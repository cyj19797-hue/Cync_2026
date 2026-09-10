//
//  AppIntroView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `240:1588` ("1-3 앱 소개"). Shown after
//  `LaunchScreenView` fades out, before `LoginView` — `CyncApp`'s `RootView`
//  keeps this up until "연결하기" is tapped, then switches to `LoginView`.
//
//  Logo reuses the same `CyncLogoLockup` asset as `LaunchScreenView` (the
//  vertically-stacked mark + wordmark) rather than pulling in yet another
//  export — Figma's `logo_all` node here is the same flattened artwork at a
//  different crop/size, same as the launch screen's `logo_image`/
//  `logo_text` nodes were.
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

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Spacer(minLength: 0)

            VStack(spacing: Spacing.xs) {
                Image("CyncLogoLockup")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .padding(.vertical, Spacing.md)

                VStack(spacing: Spacing.xs) {
                    Text("학과 생활을 하나로 연결하다,")
                        .font(.appIntroTitle)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("공지부터 사물함, 커뮤니티까지\n누구나 컴퓨터공학과의 정보를 한 곳에서.")
                        .font(.appIntroBody)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }

            PrimaryActionButton(
                titleKey: "연결하기",
                tint: .eventAccent,
                font: .loginButtonLabel,
                borderColor: .eventAccentLight,
                action: onConnect
            )

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    AppIntroView(onConnect: {})
}
