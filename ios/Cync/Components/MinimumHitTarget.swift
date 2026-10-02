//
//  MinimumHitTarget.swift
//  Cync
//
//  Grows a small control's tappable area toward Apple's 44×44pt minimum
//  without changing how big it looks or how much room it takes in the
//  layout: pad out, set the hit shape on the padded frame, then pad back in
//  by the same amount. Give the control a visible frame of at least
//  20×20pt so the default 12pt inset reaches 44pt.
//

import SwiftUI

extension View {
    func minimumHitTarget(inset: CGFloat = 12) -> some View {
        padding(inset)
            .contentShape(Rectangle())
            .padding(-inset)
    }
}
