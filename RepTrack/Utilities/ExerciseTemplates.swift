//
//  ExerciseTemplates.swift
//  RepTrack
//

import Foundation

struct ExerciseTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let muscleGroup: String
    let systemImageName: String
}

enum ExerciseTemplates {
    static let popular: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Bench Press",
            muscleGroup: "Chest",
            systemImageName: "figure.strengthtraining.traditional"
        ),
        ExerciseTemplate(
            name: "Incline Dumbbell Press",
            muscleGroup: "Chest",
            systemImageName: "dumbbell"
        ),
        ExerciseTemplate(
            name: "Squat",
            muscleGroup: "Legs",
            systemImageName: "figure.strengthtraining.functional"
        ),
        ExerciseTemplate(
            name: "Deadlift",
            muscleGroup: "Back",
            systemImageName: "figure.strengthtraining.functional"
        ),
        ExerciseTemplate(
            name: "Barbell Row",
            muscleGroup: "Back",
            systemImageName: "figure.core.training"
        ),
        ExerciseTemplate(
            name: "Overhead Press",
            muscleGroup: "Shoulders",
            systemImageName: "figure.strengthtraining.traditional"
        ),
        ExerciseTemplate(
            name: "Lat Pulldown",
            muscleGroup: "Back",
            systemImageName: "cable.connector.horizontal"
        ),
        ExerciseTemplate(
            name: "Bicep Curl",
            muscleGroup: "Arms",
            systemImageName: "dumbbell.fill"
        ),
        ExerciseTemplate(
            name: "Tricep Pushdown",
            muscleGroup: "Arms",
            systemImageName: "cable.connector.horizontal.fill"
        )
    ]
}

