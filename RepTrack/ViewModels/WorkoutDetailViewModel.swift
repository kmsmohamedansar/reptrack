//
//  WorkoutDetailViewModel.swift
//  RepTrack
//

import Foundation
import SwiftData
import os

@Observable
final class WorkoutDetailViewModel {
    private var modelContext: ModelContext?
    var workout: Workout?
    private let calendar = Calendar.current
    var onError: ((String) -> Void)?

    /// All exercise logs for the same exercise name, across workouts, newest first (for comparison).
    var previousLogsByName: [String: [ExerciseLog]] = [:]

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    func setWorkout(_ workout: Workout) {
        self.workout = workout
        loadPreviousLogsForComparison()
    }

    func loadPreviousLogsForComparison() {
        guard let modelContext, let workout else { return }
        let descriptor = FetchDescriptor<ExerciseLog>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allLogs: [ExerciseLog]
        do {
            allLogs = try modelContext.fetch(descriptor)
        } catch {
            AppLog.persistence.error("Fetch logs for comparison failed: \(String(describing: error))")
            onError?("Couldn’t load previous logs.")
            return
        }

        var byName: [String: [ExerciseLog]] = [:]
        for log in allLogs {
            guard log.workout?.persistentModelID != workout.persistentModelID else { continue }
            byName[log.name, default: []].append(log)
        }
        previousLogsByName = byName
    }

    func addExercise(
        name: String,
        weight: Double,
        reps: Int,
        sets: Int,
        notes: String
    ) {
        guard let modelContext, let workout else { return }
        let log = ExerciseLog(
            name: name,
            weight: weight,
            reps: reps,
            sets: sets,
            notes: notes,
            workout: workout
        )
        modelContext.insert(log)
        workout.exercises.append(log)
        do {
            try modelContext.save()
        } catch {
            AppLog.persistence.error("Save new exercise failed: \(String(describing: error))")
            onError?("Couldn’t save exercise. Please try again.")
        }
        loadPreviousLogsForComparison()
    }

    func previousLog(forExerciseName name: String) -> ExerciseLog? {
        previousLogsByName[name]?.first
    }

    func updateExercise(
        _ log: ExerciseLog,
        name: String,
        weight: Double,
        reps: Int,
        sets: Int,
        notes: String
    ) {
        log.name = name
        log.weight = weight
        log.reps = reps
        log.sets = sets
        log.notes = notes
        do {
            try modelContext?.save()
        } catch {
            AppLog.persistence.error("Update exercise save failed: \(String(describing: error))")
            onError?("Couldn’t save changes. Please try again.")
        }
        loadPreviousLogsForComparison()
    }

    func deleteExercise(_ log: ExerciseLog) {
        guard let modelContext else { return }
        modelContext.delete(log)
        do {
            try modelContext.save()
        } catch {
            AppLog.persistence.error("Delete exercise save failed: \(String(describing: error))")
            onError?("Couldn’t delete exercise. Please try again.")
        }
        loadPreviousLogsForComparison()
    }

    // MARK: - Workout performance (for detail analytics)

    func totalSets(for workout: Workout) -> Int {
        workout.exercises.reduce(0) { $0 + $1.sets }
    }

    func totalReps(for workout: Workout) -> Int {
        workout.exercises.reduce(0) { $0 + ($1.reps * $1.sets) }
    }

    func totalVolume(for workout: Workout) -> Double {
        workout.exercises.reduce(0) { $0 + ($1.weight * Double($1.reps) * Double($1.sets)) }
    }

    /// Rough estimate: ~5 cal per set (very approximate).
    func estimatedCalories(for workout: Workout) -> Int {
        totalSets(for: workout) * 5
    }

    /// Weight progression per exercise name for chart: (exerciseName, [(date, weight)]).
    func weightProgression(for workout: Workout) -> [(name: String, points: [(Date, Double)])] {
        guard let modelContext else { return [] }
        let workoutId = workout.persistentModelID
        let descriptor = FetchDescriptor<ExerciseLog>(sortBy: [SortDescriptor(\.createdAt)])
        let allLogs: [ExerciseLog]
        do {
            allLogs = try modelContext.fetch(descriptor)
        } catch {
            AppLog.persistence.error("Fetch logs for progression failed: \(String(describing: error))")
            onError?("Couldn’t load progress chart.")
            return []
        }
        var byName: [String: [(Date, Double)]] = [:]
        for log in allLogs {
            guard let w = log.workout else { continue }
            guard w.persistentModelID == workoutId else { continue }
            byName[log.name, default: []].append((log.createdAt, log.weight))
        }
        return byName.map { (name: $0.key, points: $0.value.sorted { $0.0 < $1.0 }) }
    }

    // MARK: - Progress insights

    struct ProgressInsight: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let systemImage: String
        let tone: Tone

        enum Tone {
            case neutral
            case positive
        }
    }

    func progressInsight(for workout: Workout) -> ProgressInsight? {
        let currentVolume = totalVolume(for: workout)
        guard currentVolume > 0 else { return nil }

        if isBestVolumeThisWeek(workout: workout, currentVolume: currentVolume) {
            return ProgressInsight(
                title: "Best performance this week",
                message: "This is your strongest session by volume so far this week.",
                systemImage: "crown.fill",
                tone: .positive
            )
        }

        guard let prev = previousWorkout(before: workout) else { return nil }
        let prevVol = totalVolume(for: prev)
        guard prevVol > 0 else { return nil }

        let delta = currentVolume - prevVol
        let pct = (delta / prevVol) * 100

        if pct >= 5 {
            return ProgressInsight(
                title: "You lifted more than last time 💪",
                message: String(format: "Volume increased by %.0f%%.", pct),
                systemImage: "arrow.up.right",
                tone: .positive
            )
        }

        return nil
    }

    private func previousWorkout(before workout: Workout) -> Workout? {
        guard let modelContext else { return nil }
        let thisDay = calendar.startOfDay(for: workout.date)
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all: [Workout]
        do {
            all = try modelContext.fetch(descriptor)
        } catch {
            AppLog.persistence.error("Fetch workouts for insight failed: \(String(describing: error))")
            return nil
        }
        return all.first { calendar.startOfDay(for: $0.date) < thisDay }
    }

    private func isBestVolumeThisWeek(workout: Workout, currentVolume: Double) -> Bool {
        guard let modelContext else { return false }
        guard let week = calendar.dateInterval(of: .weekOfYear, for: workout.date) else { return false }
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all: [Workout]
        do {
            all = try modelContext.fetch(descriptor)
        } catch {
            AppLog.persistence.error("Fetch workouts for week insight failed: \(String(describing: error))")
            return false
        }
        let weekWorkouts = all.filter { $0.date >= week.start && $0.date < week.end }
        guard weekWorkouts.count >= 2 else { return false }
        let maxVol = weekWorkouts
            .map { totalVolume(for: $0) }
            .max() ?? 0
        return maxVol > 0 && abs(currentVolume - maxVol) < 0.0001
    }
}
