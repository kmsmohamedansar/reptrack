//
//  ForgeSummaryCardView.swift
//  RepTrack
//
//  Unifies progress rings + streak + (optional) analytics into one calm summary card.
//

import SwiftUI

struct ForgeSummaryCardView: View {
    let workoutsProgress: Double
    let setsProgress: Double
    let volumeProgress: Double
    let workoutsValue: Int
    let setsValue: Int
    let volumeValue: Double
    let currentStreak: Int
    let longestStreak: Int
    let weeklyWorkoutGoal: Int
    let improvementHint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            // Primary: rings + streak
            ForgeProgressRingsView(
                workoutsProgress: workoutsProgress,
                setsProgress: setsProgress,
                volumeProgress: volumeProgress,
                workoutsValue: workoutsValue,
                setsValue: setsValue,
                volumeValue: volumeValue,
                embedded: true
            )

            if workoutsValue == 0 && setsValue == 0 {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceXS) {
                    Text("No progress yet")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ForgeTheme.secondaryText)
                    Text("Complete a workout to unlock your weekly summary.")
                        .font(.caption)
                        .foregroundStyle(ForgeTheme.tertiaryText)
                }
            }

            Divider()
                .overlay(ForgeTheme.cardLightBorder)

            weeklyGoalRow

            if let improvementHint {
                Text(improvementHint)
                    .font(.caption)
                    .foregroundStyle(ForgeTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(ForgeTheme.cardLightBorder)

            ForgeStreakView(currentStreak: currentStreak, longestStreak: longestStreak, embedded: true)
        }
        .padding(ForgeTheme.cardPadding)
        .forgeCard()
    }

    private var weeklyGoalRow: some View {
        let goal = max(1, weeklyWorkoutGoal)
        let completed = min(workoutsValue, goal)
        let progress = Double(completed) / Double(goal)

        return VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            HStack(alignment: .firstTextBaseline) {
                Text("Weekly goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ForgeTheme.primaryText)
                Spacer(minLength: 0)
                Text("\(completed)/\(goal) workouts")
                    .font(.subheadline)
                    .foregroundStyle(ForgeTheme.secondaryText)
            }

            ProgressView(value: progress)
                .tint(ForgeTheme.gold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly goal")
        .accessibilityValue("\(completed) of \(goal) workouts")
    }
}

#Preview {
    ZStack {
        ForgeTheme.backgroundGradient.ignoresSafeArea()
        ForgeSummaryCardView(
            workoutsProgress: 0.6,
            setsProgress: 0.8,
            volumeProgress: 0.4,
            workoutsValue: 3,
            setsValue: 24,
            volumeValue: 12500,
            currentStreak: 5,
            longestStreak: 12,
            weeklyWorkoutGoal: 3,
            improvementHint: "2 exercises are up from last session"
        )
        .padding()
    }
    .preferredColorScheme(.light)
}

