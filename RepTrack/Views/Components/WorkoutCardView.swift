//
//  WorkoutCardView.swift
//  RepTrack
//

import SwiftUI
import SwiftData

struct WorkoutCardView: View {
    let workout: Workout
    private let iconSize: CGFloat = 56

    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets }
    }

    private var estimatedVolume: Double {
        workout.exercises.reduce(0) { $0 + ($1.weight * Double($1.reps) * Double($1.sets)) }
    }

    var body: some View {
        HStack(spacing: ForgeTheme.spaceM) {
            iconBadge
            textContent
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ForgeTheme.gold.opacity(0.8))
                .accessibilityHidden(true)
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens workout details")
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(ForgeTheme.backgroundLight)
                .frame(width: iconSize, height: iconSize)
            Circle()
                .stroke(ForgeTheme.gold.opacity(0.6), lineWidth: 1.5)
                .frame(width: iconSize, height: iconSize)
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 26))
                .foregroundStyle(ForgeTheme.gold)
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceXS) {
            Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
                .foregroundStyle(ForgeTheme.primaryText)
            Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                .font(.body)
                .foregroundStyle(ForgeTheme.secondaryText)
            if totalSets > 0 || estimatedVolume > 0 {
                HStack(spacing: ForgeTheme.spaceS) {
                    if totalSets > 0 {
                        Text("\(totalSets) sets")
                            .font(.caption)
                        .foregroundStyle(ForgeTheme.tertiaryText)
                    }
                    if estimatedVolume > 0 {
                        Text(formatVolume(estimatedVolume))
                            .font(.caption)
                        .foregroundStyle(ForgeTheme.tertiaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1fk lb", v / 1000) }
        return "\(Int(v)) lb"
    }

    private var accessibilitySummary: String {
        var parts: [String] = []
        parts.append("Workout on \(workout.date.formatted(date: .complete, time: .omitted))")
        parts.append("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
        if totalSets > 0 { parts.append("\(totalSets) sets") }
        if estimatedVolume > 0 { parts.append("volume \(formatVolume(estimatedVolume))") }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    ZStack {
        ForgeTheme.backgroundGradient.ignoresSafeArea()
        WorkoutCardView(workout: Workout(date: Date()))
            .padding()
    }
    .preferredColorScheme(.light)
}
