//
//  ForgeStreakView.swift
//  RepTrack
//
//  Current and longest workout streak. Flame icon with Forge gold glow.
//

import SwiftUI

struct ForgeStreakView: View {
    let currentStreak: Int
    let longestStreak: Int
    var embedded: Bool = false

    @State private var appeared = false
    @State private var bump: CGFloat = 1
    @State private var lastStreak: Int = 0

    var body: some View {
        let isActive = currentStreak > 0
        let content = HStack(spacing: ForgeTheme.spaceM) {
            Image(systemName: "flame.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(isActive ? AnyShapeStyle(ForgeTheme.goldGradient) : AnyShapeStyle(ForgeTheme.tertiaryText))
                .scaleEffect(bump)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(currentStreak)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(isActive ? ForgeTheme.gold : ForgeTheme.primaryText)
                        .scaleEffect(bump)
                    Text("day streak")
                        .font(.subheadline)
                        .foregroundStyle(ForgeTheme.secondaryText)
                }

                Text(streakMessage(for: currentStreak))
                    .font(.caption)
                    .foregroundStyle(isActive ? ForgeTheme.primaryText : ForgeTheme.tertiaryText)

                ForgeTypography.caption("Best: \(longestStreak) days")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(embedded ? 0 : ForgeTheme.cardPadding)
        .padding(.vertical, embedded ? 0 : 2)
        .background {
            if !embedded && isActive {
                RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous)
                    .fill(ForgeTheme.gold.opacity(0.06))
            }
        }
        return Group {
            if embedded {
                content
            } else {
                content
                    .forgeCard()
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            lastStreak = currentStreak
        }
        .onChange(of: currentStreak) { _, newValue in
            guard newValue > lastStreak else {
                lastStreak = newValue
                return
            }
            lastStreak = newValue
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                bump = 1.08
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9).delay(0.08)) {
                bump = 1
            }
        }
    }

    private func streakMessage(for streak: Int) -> String {
        if streak >= 10 { return "Unstoppable 🔥" }
        if streak >= 5 { return "You're building momentum" }
        if streak >= 1 { return "Good start" }
        return "Start a streak"
    }
}

#Preview {
    ZStack {
        ForgeTheme.backgroundGradient.ignoresSafeArea()
        ForgeStreakView(currentStreak: 5, longestStreak: 12)
            .padding()
    }
    .preferredColorScheme(.light)
}
