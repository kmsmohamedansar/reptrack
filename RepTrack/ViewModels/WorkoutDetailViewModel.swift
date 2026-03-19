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
    private var allLogsByName: [String: [ExerciseLog]] = [:]

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

        var allByName: [String: [ExerciseLog]] = [:]
        var previousByName: [String: [ExerciseLog]] = [:]
        for log in allLogs {
            allByName[log.name, default: []].append(log)
            guard log.workout?.persistentModelID != workout.persistentModelID else { continue }
            previousByName[log.name, default: []].append(log)
        }
        allLogsByName = allByName
        previousLogsByName = previousByName
    }

    func addExercise(
        name: String,
        weight: Double,
        reps: Int,
        sets: Int,
        notes: String
    ) {
        guard let modelContext, let workout else { return }
        let nextOrder = (workout.exercises.map(\.orderIndex).max() ?? -1) + 1
        let log = ExerciseLog(
            orderIndex: nextOrder,
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

    @discardableResult
    func saveWorkoutAsTemplate(_ workout: Workout, templateName: String) -> Bool {
        guard let modelContext else { return false }
        let trimmed = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?("Template name is required.")
            return false
        }
        guard !workout.sortedExercises.isEmpty else {
            onError?("Add at least one exercise before saving a template.")
            return false
        }

        let template = WorkoutTemplate(name: trimmed)
        modelContext.insert(template)

        for (index, log) in workout.sortedExercises.enumerated() {
            let item = WorkoutTemplateExercise(
                orderIndex: index,
                name: log.name,
                defaultWeight: log.weight,
                defaultReps: log.reps,
                defaultSets: log.sets,
                template: template
            )
            modelContext.insert(item)
            template.exercises.append(item)
        }

        do {
            try modelContext.save()
            return true
        } catch {
            AppLog.persistence.error("Save workout as template failed: \(String(describing: error))")
            onError?("Couldn’t save template. Please try again.")
            return false
        }
    }

    @discardableResult
    func duplicateWorkout(_ source: Workout, date: Date = Date()) -> Workout? {
        guard let modelContext else { return nil }
        let workout = Workout(date: date)
        modelContext.insert(workout)
        copyExercises(from: source, to: workout, using: modelContext)
        do {
            try modelContext.save()
            return workout
        } catch {
            AppLog.persistence.error("Duplicate workout failed: \(String(describing: error))")
            onError?("Couldn’t duplicate workout. Please try again.")
            return nil
        }
    }

    @discardableResult
    func mergeWorkout(_ source: Workout, into target: Workout) -> Bool {
        guard let modelContext else { return false }
        copyExercises(from: source, to: target, using: modelContext)
        do {
            try modelContext.save()
            return true
        } catch {
            AppLog.persistence.error("Merge workout failed: \(String(describing: error))")
            onError?("Couldn’t merge workout. Please try again.")
            return false
        }
    }

    private func copyExercises(from source: Workout, to target: Workout, using modelContext: ModelContext) {
        let start = (target.exercises.map(\.orderIndex).max() ?? -1) + 1
        for (offset, log) in source.sortedExercises.enumerated() {
            let cloned = ExerciseLog(
                orderIndex: start + offset,
                name: log.name,
                weight: log.weight,
                reps: log.reps,
                sets: log.sets,
                notes: log.notes,
                workout: target
            )
            modelContext.insert(cloned)
            target.exercises.append(cloned)
        }
    }

    @discardableResult
    func reorderExercises(in workout: Workout, from source: IndexSet, to destination: Int) -> Bool {
        guard let modelContext else { return false }
        var reordered = workout.sortedExercises
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, log) in reordered.enumerated() {
            log.orderIndex = idx
        }
        workout.exercises = reordered
        do {
            try modelContext.save()
            return true
        } catch {
            AppLog.persistence.error("Reorder exercises save failed: \(String(describing: error))")
            onError?("Couldn’t save exercise order. Please try again.")
            return false
        }
    }

    @discardableResult
    func finishWorkout(_ workout: Workout) -> Bool {
        guard let modelContext else { return false }
        workout.isFinished = true
        workout.finishedAt = Date()
        do {
            try modelContext.save()
            return true
        } catch {
            AppLog.persistence.error("Finish workout (detail) save failed: \(String(describing: error))")
            onError?("Couldn’t finish workout. Please try again.")
            return false
        }
    }

    @discardableResult
    func reopenWorkout(_ workout: Workout) -> Bool {
        guard let modelContext else { return false }
        workout.isFinished = false
        workout.finishedAt = nil
        do {
            try modelContext.save()
            return true
        } catch {
            AppLog.persistence.error("Reopen workout (detail) save failed: \(String(describing: error))")
            onError?("Couldn’t continue workout. Please try again.")
            return false
        }
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

    struct ExerciseInsight: Identifiable {
        let id = UUID()
        let exerciseName: String
        let message: String
    }

    struct ExercisePRSummary: Identifiable {
        let id = UUID()
        let exerciseName: String
        let prTypes: [PRType]

        enum PRType: String {
            case weight = "Highest weight"
            case reps = "Highest reps"
            case volume = "Highest volume"
        }
    }

    func prsAchieved(in workout: Workout) -> [ExercisePRSummary] {
        workout.sortedExercises.compactMap { log in
            let types = prTypesAchieved(for: log)
            guard !types.isEmpty else { return nil }
            return ExercisePRSummary(exerciseName: log.name, prTypes: types)
        }
    }

    func prTypesAchieved(for log: ExerciseLog) -> [ExercisePRSummary.PRType] {
        guard let logs = allLogsByName[log.name], !logs.isEmpty else { return [] }
        let baseline = logs.filter { $0.persistentModelID != log.persistentModelID }

        func maxWeight(in logs: [ExerciseLog]) -> Double { logs.map(\.weight).max() ?? 0 }
        func maxReps(in logs: [ExerciseLog]) -> Int { logs.map(\.reps).max() ?? 0 }
        func maxVolume(in logs: [ExerciseLog]) -> Double {
            logs.map { $0.weight * Double($0.reps) * Double($0.sets) }.max() ?? 0
        }

        let baselineWeight = maxWeight(in: baseline)
        let baselineReps = maxReps(in: baseline)
        let baselineVolume = maxVolume(in: baseline)

        var achieved: [ExercisePRSummary.PRType] = []
        if !baseline.isEmpty, log.weight > baselineWeight { achieved.append(.weight) }
        if !baseline.isEmpty, log.reps > baselineReps { achieved.append(.reps) }
        if !baseline.isEmpty, (log.weight * Double(log.reps) * Double(log.sets)) > baselineVolume { achieved.append(.volume) }
        return achieved
    }

    func exerciseInsights(for workout: Workout) -> [ExerciseInsight] {
        workout.sortedExercises.compactMap { log in
            guard let previous = previousLog(forExerciseName: log.name) else { return nil }

            let currentVolume = log.weight * Double(log.reps) * Double(log.sets)
            let previousVolume = previous.weight * Double(previous.reps) * Double(previous.sets)

            if currentVolume > previousVolume {
                return ExerciseInsight(
                    exerciseName: log.name,
                    message: "Higher volume than last time"
                )
            }
            if log.reps > previous.reps {
                return ExerciseInsight(
                    exerciseName: log.name,
                    message: "More reps than previous workout"
                )
            }
            if log.weight > previous.weight {
                return ExerciseInsight(
                    exerciseName: log.name,
                    message: "Up from last session"
                )
            }
            return nil
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
