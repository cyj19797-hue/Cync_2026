//
//  LaunchScreenView.swift
//  Cync
//
//  In-app SwiftUI splash screen shown after the app's code starts running
//  (distinct from the OS-level system Launch Screen). Displays the logo
//  centered on the app background.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        Color.appBackground
            .ignoresSafeArea()
            .overlay {
                Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }
    }
}

#Preview {
    LaunchScreenView()
}
