//
//  KeyboardObserver.swift
//  Cync
//
//  Tracks the software keyboard's current height so a custom modal (one of
//  this project's ZStack + `.overlay` popups, not a system `.sheet`) can
//  reposition itself to stay above the keyboard — `.sheet` gets this for
//  free from UIKit, a plain SwiftUI overlay doesn't.
//
//  Uses `keyboardWillChangeFrameNotification` alone (rather than a
//  show/hide pair) — it fires for every frame change, including the
//  transition to/from zero height, so there's a single source of truth
//  instead of two notifications that can race or fire out of order.
//

import Combine
import UIKit

@MainActor
final class KeyboardObserver: ObservableObject {
    @Published private(set) var height: CGFloat = 0

    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { frame -> CGFloat in
                guard let screenHeight = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.screen.bounds.height })
                    .first
                else { return 0 }
                // A frame whose top edge is at/beyond the screen's bottom
                // means the keyboard is offscreen (dismissed).
                let visibleHeight = screenHeight - frame.origin.y
                return max(0, visibleHeight)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in self?.height = height }
    }
}
