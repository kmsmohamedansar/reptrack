//
//  ForgeFloatingButton.swift
//  RepTrack
//

import SwiftUI

struct ForgeFloatingButton: View {
    let action: () -> Void
    var accessibilityLabel: String = "Add workout"

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(ForgeTheme.goldGradient)
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(ForgeTheme.gold.opacity(0.5), lineWidth: 1)
                    .frame(width: 56, height: 56)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(ForgeTheme.buttonIconDark)
            }
            // One layer of depth (primary action only)
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(ForgeFloatingButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens the add workout screen")
    }
}

private struct ForgeFloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        ForgeTheme.backgroundGradient.ignoresSafeArea()
        VStack { Spacer() }
        ForgeFloatingButton(action: {})
            .padding(.bottom, 24)
    }
    .preferredColorScheme(.light)
}
