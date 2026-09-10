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
//  The logo ("C" mark stacked over the "cync" wordmark, `CyncLogoLockup`)
//  isn't the same asset as `Image`/`CyncWordmark` used elsewhere (those are
//  a mark-only icon and a horizontal one-line lockup, respectively) —
//  Figma's "start" frame uses a third, vertically-stacked variant exported
//  as its own flattened asset, so that's what was pulled in here instead of
//  approximating it from the other two.
//
//  Figma centers the whole (logo + tagline) block vertically on screen while
//  keeping it left-aligned horizontally (not centered) — `Spacer`s above/
//  below reproduce the vertical centering, `.leading` alignment reproduces
//  the horizontal placement.
//
//  Reveal animation: a radial "pop" — the logo grows out from its own red
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
    /// Where the logo's red dot actually sits, as a fraction of the
    /// `CyncLogoLockup` image's own frame — measured off the source PNG's
    /// pixels (centroid of its red pixels), not guessed. The reveal circle
    /// is anchored here so the logo appears to "pop" out from the dot.
    private static let dotAnchor = UnitPoint(x: 0.53, y: 0.31)

    /// `Circle()` inscribed in a non-square frame only touches the *midpoint*
    /// of each edge, not the corners — so scaling it up to exactly `1` (its
    /// own natural, un-scaled size) leaves the four corners of the
    /// `CyncLogoLockup` frame still masked out, clipping the wordmark's
    /// bottom corners. Solved analytically for this frame's aspect ratio and
    /// the anchor above: scale `2` is the smallest value whose ellipse fully
    /// covers every corner; this adds a safety margin over that.
    private static let fullRevealScale: CGFloat = 2.2

    @State private var isLogoRevealed = false
    @State private var isTaglineVisible = false

    var body: some View {
        Color.appBackground
            .ignoresSafeArea()
            .overlay {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Image("CyncLogoLockup")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 105)
                            .mask {
                                Circle()
                                    .scaleEffect(isLogoRevealed ? Self.fullRevealScale : 0.0001, anchor: Self.dotAnchor)
                            }

                        Text("Campus, in Cync")
                            .font(.launchTagline)
                            .foregroundStyle(Color.textPrimary)
                            .opacity(isTaglineVisible ? 1 : 0)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.leading, Spacing.md)
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
