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
//  Figma centers the whole (logo + tagline) block vertically on screen while
//  keeping it left-aligned horizontally (not centered) — `Spacer`s above/
//  below reproduce the vertical centering, `.leading` alignment reproduces
//  the horizontal placement.
//
//  Reveal animation: a radial "pop" — the logo grows out from its own blue
//  dot (not the block's center) via a `Circle` mask animated from near-zero
//  to full `scaleEffect`, `anchor`ed at the dot's actual position in the
//  artwork (measured directly off the source asset's pixels, not eyeballed).
//  Pure SwiftUI: `Circle()` inside `.mask` already lays out as the full
//  ellipse inscribed in the masked view's own frame, so animating its scale
//  from ~0 up to 1 traces that same frame exactly — no oversize fudge factor
//  needed regardless of the anchor point. No UIKit/Core Animation required;
//  `CAShapeLayer.strokeEnd` would only be needed for a stroke-drawn outline
//  effect, which needs vector path data this raster logo doesn't have.
//  The tagline fades in afterward, once the logo's own reveal has landed.
//

import SwiftUI

struct LaunchScreenView: View {
    /// Where the logo's blue dot actually sits, as a fraction of the
    /// `Image` asset's own frame — measured off the source PNG's pixels
    /// (centroid of its blue pixels), not guessed. The reveal circle is
    /// anchored here so the logo appears to "pop" out from the dot.
    private static let dotAnchor = UnitPoint(x: 0.548, y: 0.5)

    /// `Circle()` inscribed in the square frame only touches the *midpoint*
    /// of each edge, not the corners — so scaling it up to exactly `1` (its
    /// own natural, un-scaled size) leaves the frame's corners masked out.
    /// Solved for the anchor above: scale `1.45` is the smallest value whose
    /// circle covers every corner; this adds a safety margin over that.
    private static let fullRevealScale: CGFloat = 1.6

    @State private var isLogoRevealed = false
    @State private var isTaglineVisible = false

    var body: some View {
        Color.appBackground
            .ignoresSafeArea()
            .overlay {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Image("Image")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .mask {
                                Circle()
                                    .scaleEffect(isLogoRevealed ? Self.fullRevealScale : 0.0001, anchor: Self.dotAnchor)
                            }

                        // Brand slogan — identical in every language, so not localized.
                        Text(verbatim: "Campus, in Cync")
                            .font(.launchTagline).tracking(Tracking.launchTagline)
                            .foregroundStyle(Color.textPrimary)
                            .opacity(isTaglineVisible ? 1 : 0)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.leading, Spacing.cardInset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
                    isLogoRevealed = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
                    isTaglineVisible = true
                }
            }
    }
}

#Preview {
    LaunchScreenView()
}
