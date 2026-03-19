//
//  ExerciseRowView.swift
//  RepTrack
//
//  Thin wrapper that delegates to ExerciseCardView for consistent card styling.
//

import SwiftUI
import SwiftData

struct ExerciseRowView: View {
    let log: ExerciseLog
    let previous: ExerciseLog?

    init(log: ExerciseLog, progression previous: ExerciseLog?) {
        self.log = log
        self.previous = previous
    }

    var body: some View {
        ExerciseCardView(log: log, progression: previous)
    }
}

#Preview {
    List {
        ExerciseRowView(
            log: ExerciseLog(name: "Bench Press", weight: 135, reps: 10, sets: 3),
            progression: ExerciseLog(name: "Bench Press", weight: 130, reps: 10, sets: 3)
        )
    }
}
