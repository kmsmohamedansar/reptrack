//
//  WorkoutTemplate.swift
//  RepTrack
//

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var name: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateExercise.template)
    var exercises: [WorkoutTemplateExercise] = []

    init(name: String, exercises: [WorkoutTemplateExercise] = []) {
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.exercises = exercises
    }

    var sortedExercises: [WorkoutTemplateExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
final class WorkoutTemplateExercise {
    var orderIndex: Int
    var name: String
    var defaultWeight: Double
    var defaultReps: Int
    var defaultSets: Int
    var template: WorkoutTemplate?

    init(
        orderIndex: Int,
        name: String,
        defaultWeight: Double = 0,
        defaultReps: Int = 0,
        defaultSets: Int = 0,
        template: WorkoutTemplate? = nil
    ) {
        self.orderIndex = orderIndex
        self.name = name
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self.defaultSets = defaultSets
        self.template = template
    }
}
