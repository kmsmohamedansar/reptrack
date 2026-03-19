//
//  ForgeFloatingButton.swift
//  RepTrack
//

import SwiftUI

struct ForgeFloatingButton: View {
    let action: () -> Void
    var accessibilityLabel: String = "Add workout"
    var accessibilityHint: String = "Opens the add workout screen"

    private let size: CGFloat = 48
    private let iconSize: CGFloat = 20

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(ForgeTheme.goldGradient.opacity(0.92))
                    .frame(width: size, height: size)
                Circle()
                    .stroke(ForgeTheme.gold.opacity(0.35), lineWidth: 1)
                    .frame(width: size, height: size)
                Image(systemName: "plus")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(ForgeTheme.buttonIconDark)
            }
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ForgeFloatingButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

private struct ForgeFloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: ForgeTheme.quick), value: configuration.isPressed)
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
