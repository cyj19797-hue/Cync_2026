//
//  ToastView.swift
//  Cync
//
//  A short message that appears near the bottom and goes away by itself —
//  e.g. "제목과 내용을 입력해 주세요" when the dimmed "등록" is tapped.
//  Dark pill (`textPrimary` fill, white text: ~16:1) so it reads on any
//  screen. Attach with `.toast(message:)`; set the binding to show it, and
//  it clears itself after `duration`. VoiceOver reads it out as it appears.
//

import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.categoryBadge).tracking(Tracking.categoryBadge)
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.cardInset)
            .background(Capsule().fill(Color.textPrimary))
            .padding(.horizontal, Spacing.screenHorizontal)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: Duration

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ToastView(message: message)
                        .padding(.bottom, Spacing.md)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .allowsHitTesting(false)
                        // Restarts the timer when a new message (or the same
                        // one, tapped again) comes in.
                        .task(id: message) {
                            AccessibilityNotification.Announcement(message).post()
                            try? await Task.sleep(for: duration)
                            guard !Task.isCancelled else { return }
                            self.message = nil
                        }
                }
            }
            .animation(.easeOut(duration: 0.2), value: message)
    }
}

extension View {
    /// Shows `message` as a toast at the bottom, then clears it.
    func toast(message: Binding<String?>, duration: Duration = .seconds(2)) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

#Preview {
    Color.appBackground
        .toast(message: .constant("제목과 내용을 입력해 주세요"))
}
