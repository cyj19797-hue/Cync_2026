//
//  LaunchScreenView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `205:2219` ("start"). In-app SwiftUI splash
//  screen shown after the app's code starts running (distinct from the
//  OS-level system Launch Screen) — `CyncApp` overlays this on top of
//  `LoginView`/`RootTabView` for a beat before fading out, so it's always
//  the first thing a user sees.
//
//  The logo is the mark-only `Image` asset (the "C" + blue dot, same art
//  as the app icon). It used to be a separate vertically-stacked mark +
//  wordmark lockup (`CyncLogoLockup`), which has since been dropped.
//
//  Layout: the logo itself sits at the exact center of the screen (not
//  Figma's left alignment), with the tagline hanging below it. The logo
//  is the one thing to look at here, so it's what's centered — the
//  tagline doesn't pull it up. A hidden copy of the tagline above the
//  logo balances the stack so the logo lands dead center — of the whole
//  screen, not the safe area.
//
//  Reveal animation: the block fills in from top to bottom, like ink
//  poured in — a mask over the whole block (logo, then tagline) grows
//  downward from its top edge, with a short soft fade at the leading edge
//  so the fill has a gentle front instead of a hard line. Pure SwiftUI
//  (`.mask` + `scaleEffect(y:anchor: .top)`). With Reduce Motion the block
//  just appears.
//

import SwiftUI

struct LaunchScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    /// Height of the soft band at the fill's leading (bottom) edge.
    private static let featherHeight: CGFloat = 24

    var body: some View {
        // One ZStack ignoring the safe area as a whole, so the logo is
        // centered on the physical screen (an overlay on a safe-area-
        // ignoring background would still be laid out in the safe area,
        // whose taller top inset pushes it ~14pt low).
        ZStack {
            Color.appBackground
            VStack(spacing: Spacing.xs) {
                // Balances the tagline below so the logo is centered.
                tagline.hidden()

                VStack(spacing: Spacing.xs) {
                    Image("Image")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    tagline
                }
                .mask(alignment: .top) { fillMask }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if reduceMotion {
                isRevealed = true
            } else {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isRevealed = true
                }
            }
        }
    }

    // Brand slogan — identical in every language, so not localized.
    private var tagline: some View {
        Text(verbatim: "Campus, in Cync")
            .font(.launchTagline).tracking(Tracking.launchTagline)
            .foregroundStyle(Color.textPrimary)
    }

    /// Solid from the top, with a soft fade at its bottom edge that hangs
    /// past the block (negative padding), so at full size the whole block
    /// is solid; grows downward from the block's top edge.
    private var fillMask: some View {
        VStack(spacing: 0) {
            Rectangle()
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: Self.featherHeight)
        }
        .padding(.bottom, -Self.featherHeight)
        .scaleEffect(y: isRevealed ? 1 : 0.0001, anchor: .top)
    }
}

#Preview {
    LaunchScreenView()
}
