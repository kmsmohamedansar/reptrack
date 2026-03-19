//
//  ExercisePickerCards.swift
//  RepTrack
//
//  Shared cards for picking an exercise (Add and Edit flows).
//

import SwiftUI

struct WgerExerciseCard: View {
    let exercise: WgerExercise
    let isSelected: Bool

    private var iconName: String {
        switch exercise.displayCategory.lowercased() {
        case let c where c.contains("chest"): return "figure.strengthtraining.traditional"
        case let c where c.contains("back"): return "figure.core.training"
        case let c where c.contains("leg"): return "figure.strengthtraining.functional"
        case let c where c.contains("shoulder"): return "figure.strengthtraining.traditional"
        case let c where c.contains("arm"): return "dumbbell.fill"
        default: return "dumbbell"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            ZStack {
                RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(height: 72)

            VStack(alignment: .leading, spacing: ForgeTheme.spaceXS) {
                Text(exercise.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(minHeight: 36, alignment: .topLeading)
                if !exercise.displayCategory.isEmpty {
                    Text(exercise.displayCategory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(ForgeTheme.spaceM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        // Keep picker cards flat; selection border is sufficient.
    }
}

struct ExerciseTemplateCard: View {
    let template: ExerciseTemplate
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            ZStack {
                RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                Image(systemName: template.systemImageName)
                    .font(.system(size: 28, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 88, height: 72)

            VStack(alignment: .leading, spacing: ForgeTheme.spaceXS) {
                Text(template.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(template.muscleGroup)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(ForgeTheme.spaceM)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        // Keep picker cards flat; selection border is sufficient.
    }
}
