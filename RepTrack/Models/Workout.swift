//
//  Workout.swift
//  RepTrack
//

import Foundation
import SwiftData

@Model
final class Workout {
    var date: Date
    var createdAt: Date
    var notes: String
    var isFinished: Bool
    var finishedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.workout)
    var exercises: [ExerciseLog] = []

    init(
        date: Date = Date(),
        exercises: [ExerciseLog] = [],
        notes: String = "",
        isFinished: Bool = false,
        finishedAt: Date? = nil
    ) {
        self.date = date
        self.createdAt = Date()
        self.notes = notes
        self.isFinished = isFinished
        self.finishedAt = finishedAt
        self.exercises = exercises
    }

    var sortedExercises: [ExerciseLog] {
        exercises.sorted {
            if $0.orderIndex == $1.orderIndex {
                return $0.createdAt < $1.createdAt
            }
            return $0.orderIndex < $1.orderIndex
        }
    }
}
