//
//  AppSwitchToggleStyle.swift
//  Cync
//
//  A drawn on/off switch in place of iOS's, whose "off" track can't be
//  recolored and is nearly invisible on white (~1.2:1). Same 51×31 shape
//  as the iOS switch. Both tracks come from color tokens and reach 3:1
//  against white: `switchOnTrack` (#0099FE) and `switchOffTrack` (#8A95A9).
//
//  The whole row is the tap target — label included — and toggling gives
//  a light haptic. VoiceOver still treats it as a native switch ("마감 임박
//  알림, 마감 하루 전에 알려줘요, 켬, 스위치 버튼") through
//  `accessibilityRepresentation`. The label may wrap at large text sizes;
//  the switch keeps its size and stays vertically centered.
//

import SwiftUI

struct AppSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        AppSwitchRow(configuration: configuration)
    }
}

private struct AppSwitchRow: View {
    let configuration: ToggleStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: Spacing.md) {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
            AppSwitchTrack(isOn: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isEnabled else { return }
            withAnimation(.snappy(duration: 0.2)) { configuration.isOn.toggle() }
        }
        .sensoryFeedback(.selection, trigger: configuration.isOn)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

/// The switch graphic alone.
private struct AppSwitchTrack: View {
    let isOn: Bool

    private static let size = CGSize(width: 51, height: 31)
    private static let knobInset: CGFloat = 2

    var body: some View {
        let knob = Self.size.height - Self.knobInset * 2
        Capsule()
            .fill(isOn ? Color.switchOnTrack : Color.switchOffTrack)
            .frame(width: Self.size.width, height: Self.size.height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .frame(width: knob, height: knob)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
                    .padding(Self.knobInset)
            }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var a = true
        @State private var b = false
        var body: some View {
            VStack(spacing: Spacing.md) {
                Toggle("켜짐", isOn: $a)
                Toggle("꺼짐", isOn: $b)
                Toggle("비활성", isOn: $a).disabled(true)
            }
            .toggleStyle(AppSwitchToggleStyle())
            .padding()
        }
    }
    return PreviewHost()
}
