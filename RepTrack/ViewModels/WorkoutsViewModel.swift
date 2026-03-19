//
//  WorkoutsViewModel.swift
//  RepTrack
//

import Foundation
import SwiftData
import os

@Observable
final class WorkoutsViewModel {
    private var modelContext: ModelContext?
    private let calendar = Calendar.current

    var workouts: [Workout] = []
    var onError: ((String) -> Void)?
    var isLoading: Bool = false
    var hasLoaded: Bool = false

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    func fetchWorkouts() {
        guard let modelContext else { return }
        isLoading = true
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            workouts = try modelContext.fetch(descriptor)
            hasLoaded = true
        } catch {
            AppLog.persistence.error("Fetch workouts failed: \(String(describing: error))")
            onError?("Couldn’t load workouts. Please try again.")
            workouts = []
            hasLoaded = true
        }
        isLoading = false
    }

    // MARK: - Analytics (computed from workouts, no heavy work in views)

    func workoutsThisWeek() -> Int {
        workouts.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    func setsThisWeek() -> Int {
        workouts
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.exercises.reduce(0) { a, e in a + e.sets } }
    }

    func volumeThisWeek() -> Double {
        workouts
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { acc, w in
                acc + w.exercises.reduce(0) { a, e in
                    a + (e.weight * Double(e.reps) * Double(e.sets))
                }
            }
    }

    /// Max values for ring scaling (reasonable defaults if no data).
    func maxWorkoutsPerWeek() -> Int { max(workoutsThisWeek(), 5) }
    func maxSetsPerWeek() -> Int { max(setsThisWeek(), 20) }
    func maxVolumePerWeek() -> Double { max(volumeThisWeek(), 5000) }

    /// Lightweight motivational summary across latest exercise logs.
    func improvementSummaryMessage() -> String? {
        var latestByName: [String: [ExerciseLog]] = [:]
        for workout in workouts {
            for log in workout.exercises {
                latestByName[log.name, default: []].append(log)
            }
        }

        var improvingCount = 0
        for logs in latestByName.values {
            let sorted = logs.sorted { $0.createdAt > $1.createdAt }
            guard sorted.count >= 2 else { continue }
            let current = sorted[0]
            let previous = sorted[1]
            let currentVolume = current.weight * Double(current.reps) * Double(current.sets)
            let previousVolume = previous.weight * Double(previous.reps) * Double(previous.sets)
            if currentVolume > previousVolume || current.reps > previous.reps || current.weight > previous.weight {
                improvingCount += 1
            }
        }

        guard improvingCount > 0 else { return nil }
        if improvingCount == 1 { return "1 exercise is up from last session" }
        return "\(improvingCount) exercises are up from last session"
    }

    struct Highlight: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
    }

    struct ProgressTrend: Identifiable {
        let id = UUID()
        let message: String
        let systemImage: String
        let isPositive: Bool
    }

    struct ExerciseTrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let reps: Int
        let volume: Double
    }

    func recentHighlights(maxCount: Int = 3) -> [Highlight] {
        var highlights: [Highlight] = []
        let cap = max(1, maxCount)

        // Highlight: workouts completed this week.
        let weeklyCount = workoutsThisWeek()
        if weeklyCount >= 1 {
            highlights.append(
                Highlight(
                    title: "\(weeklyCount) workout\(weeklyCount == 1 ? "" : "s") completed this week",
                    systemImage: "flame.fill"
                )
            )
        }

        // Highlight: best volume this week (if we have 2+ workouts to compare).
        if let week = calendar.dateInterval(of: .weekOfYear, for: Date()) {
            let weekWorkouts = workouts.filter { $0.date >= week.start && $0.date < week.end }
            if weekWorkouts.count >= 2 {
                func workoutVolume(_ w: Workout) -> Double {
                    w.exercises.reduce(0) { $0 + ($1.weight * Double($1.reps) * Double($1.sets)) }
                }
                if let best = weekWorkouts.max(by: { workoutVolume($0) < workoutVolume($1) }),
                   let mostRecent = weekWorkouts.sorted(by: { $0.date > $1.date }).first,
                   best.persistentModelID == mostRecent.persistentModelID {
                    highlights.append(
                        Highlight(
                            title: "Best volume this week",
                            systemImage: "crown.fill"
                        )
                    )
                }
            }
        }

        // Highlight: New PR in most recent workout (simple, meaningful).
        if let mostRecentWorkout = workouts.sorted(by: { $0.date > $1.date }).first {
            let allLogs = workouts.flatMap(\.exercises)
            var byName: [String: [ExerciseLog]] = [:]
            for log in allLogs { byName[log.name, default: []].append(log) }

            func isNewPR(_ log: ExerciseLog) -> Bool {
                guard let logs = byName[log.name] else { return false }
                let baseline = logs.filter { $0.persistentModelID != log.persistentModelID }
                guard !baseline.isEmpty else { return false }

                let baselineWeight = baseline.map(\.weight).max() ?? 0
                let baselineReps = baseline.map(\.reps).max() ?? 0
                let baselineVolume = baseline.map { $0.weight * Double($0.reps) * Double($0.sets) }.max() ?? 0
                let volume = log.weight * Double(log.reps) * Double(log.sets)
                return log.weight > baselineWeight || log.reps > baselineReps || volume > baselineVolume
            }

            if let prLog = mostRecentWorkout.sortedExercises.first(where: isNewPR) {
                highlights.append(
                    Highlight(
                        title: "New PR on \(prLog.name)",
                        systemImage: "sparkles"
                    )
                )
            }
        }

        // Keep output compact and stable.
        return Array(highlights.prefix(cap))
    }

    func recentProgressTrends(maxCount: Int = 3) -> [ProgressTrend] {
        let stats = weeklyStats(weeks: 3)
        guard stats.count >= 2 else { return [] }

        let latest = stats[stats.count - 1]
        let previous = stats[stats.count - 2]
        var trends: [ProgressTrend] = []

        let workoutsDelta = latest.workoutCount - previous.workoutCount
        if workoutsDelta > 0 {
            trends.append(.init(
                message: "\(workoutsDelta) more workout\(workoutsDelta == 1 ? "" : "s") than last week",
                systemImage: "arrow.up.right",
                isPositive: true
            ))
        } else if workoutsDelta < 0 {
            let v = abs(workoutsDelta)
            trends.append(.init(
                message: "\(v) fewer workout\(v == 1 ? "" : "s") than last week",
                systemImage: "arrow.down.right",
                isPositive: false
            ))
        }

        let setsDelta = latest.totalSets - previous.totalSets
        if setsDelta > 0 {
            trends.append(.init(
                message: "\(setsDelta) more sets than last week",
                systemImage: "chart.line.uptrend.xyaxis",
                isPositive: true
            ))
        } else if setsDelta < 0 {
            trends.append(.init(
                message: "\(abs(setsDelta)) fewer sets than last week",
                systemImage: "chart.line.downtrend.xyaxis",
                isPositive: false
            ))
        }

        let volumeDelta = latest.totalVolume - previous.totalVolume
        if volumeDelta > 0 {
            trends.append(.init(
                message: "Higher volume than last week",
                systemImage: "bolt.fill",
                isPositive: true
            ))
        } else if volumeDelta < 0 {
            trends.append(.init(
                message: "Lower volume than last week",
                systemImage: "bolt.slash.fill",
                isPositive: false
            ))
        }

        if trends.isEmpty, latest.workoutCount > 0 || latest.totalSets > 0 || latest.totalVolume > 0 {
            trends.append(.init(
                message: "Steady training compared to last week",
                systemImage: "equal.circle",
                isPositive: true
            ))
        }

        return Array(trends.prefix(max(1, maxCount)))
    }

    func trackedExerciseNames() -> [String] {
        let names = Set(workouts.flatMap { $0.exercises.map(\.name) })
        return names.sorted()
    }

    func exerciseTrend(for exerciseName: String, limit: Int = 20) -> [ExerciseTrendPoint] {
        let logs = workouts
            .flatMap(\.exercises)
            .filter { $0.name == exerciseName }
            .sorted { $0.createdAt < $1.createdAt }

        guard !logs.isEmpty else { return [] }
        let points = logs.map { log in
            ExerciseTrendPoint(
                date: log.createdAt,
                weight: log.weight,
                reps: log.reps,
                volume: log.weight * Double(log.reps) * Double(log.sets)
            )
        }
        return Array(points.suffix(max(1, limit)))
    }

    /// Last N weeks: (weekStart, workoutCount, totalSets, totalVolume).
    struct WeekStat: Identifiable {
        let id: Date
        let weekStart: Date
        let workoutCount: Int
        let totalSets: Int
        let totalVolume: Double
    }

    func weeklyStats(weeks: Int = 6) -> [WeekStat] {
        var result: [WeekStat] = []
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return result }
        for i in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: thisWeekStart) else { continue }
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let weekWorkouts = workouts.filter { $0.date >= weekStart && $0.date < weekEnd }
            let count = weekWorkouts.count
            let sets = weekWorkouts.reduce(0) { $0 + $1.exercises.reduce(0) { a, e in a + e.sets } }
            let vol = weekWorkouts.reduce(0.0) { a, w in a + w.exercises.reduce(0) { b, e in b + e.weight * Double(e.reps) * Double(e.sets) } }
            result.append(WeekStat(id: weekStart, weekStart: weekStart, workoutCount: count, totalSets: sets, totalVolume: vol))
        }
        return result.reversed()
    }

    /// Current and longest streak (consecutive days with at least one workout).
    func currentStreak() -> Int {
        let sortedDays = Set(workouts.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var current = today
        for day in sortedDays {
            if day == current {
                streak += 1
                current = calendar.date(byAdding: .day, value: -1, to: current) ?? current
            } else if day < current {
                break
            }
        }
        return streak
    }

    func longestStreak() -> Int {
        let sortedDays = Set(workouts.map { calendar.startOfDay(for: $0.date) }).sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i - 1]
            let day = sortedDays[i]
            if let expected = calendar.date(byAdding: .day, value: 1, to: prev), expected == day {
                current += 1
            } else {
                best = max(best, current)
                current = 1
            }
        }
        return max(best, current)
    }

    /// Returns an existing workout for the given calendar day, if any (most recent by date for that day).
    /// Use to avoid duplicate same-day workouts when adding.
    func workout(for date: Date) -> Workout? {
        workouts
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted(by: { $0.date > $1.date })
            .first
    }

    /// Returns today's active (unfinished) workout if present.
    func activeWorkoutForToday() -> Workout? {
        let today = calendar.startOfDay(for: Date())
        return workouts
            .filter { calendar.isDate($0.date, inSameDayAs: today) && !$0.isFinished }
            .sorted(by: { $0.date > $1.date })
            .first
    }

    @discardableResult
    func startOrContinueWorkoutForToday() -> Workout? {
        if let active = activeWorkoutForToday() {
            return active
        }
        let today = calendar.startOfDay(for: Date())
        return addWorkout(date: today)
    }

    @discardableResult
    func addWorkout(date: Date = Date()) -> Workout? {
        guard let modelContext else { return nil }
        let workout = Workout(date: date)
        modelContext.insert(workout)
        do {
            try modelContext.save()
            fetchWorkouts()
            return workout
        } catch {
            AppLog.persistence.error("Save new workout failed: \(String(describing: error))")
            onError?("Couldn’t save workout. Please try again.")
            return nil
        }
    }

    @discardableResult
    func addWorkout(from template: WorkoutTemplate, date: Date = Date()) -> Workout? {
        guard let modelContext else { return nil }

        let workout = Workout(date: date)
        modelContext.insert(workout)

        addTemplateExercises(template, into: workout, using: modelContext)

        do {
            template.updatedAt = Date()
            try modelContext.save()
            fetchWorkouts()
            return workout
        } catch {
            AppLog.persistence.error("Create workout from template failed: \(String(describing: error))")
            onError?("Couldn’t create workout from template. Please try again.")
            return nil
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
            fetchWorkouts()
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
            fetchWorkouts()
            return true
        } catch {
            AppLog.persistence.error("Merge workout failed: \(String(describing: error))")
            onError?("Couldn’t merge workout. Please try again.")
            return false
        }
    }

    @discardableResult
    func addTemplate(_ template: WorkoutTemplate, to workout: Workout) -> Bool {
        guard let modelContext else { return false }
        addTemplateExercises(template, into: workout, using: modelContext)
        do {
            template.updatedAt = Date()
            try modelContext.save()
            fetchWorkouts()
            return true
        } catch {
            AppLog.persistence.error("Add template to existing workout failed: \(String(describing: error))")
            onError?("Couldn’t add template to workout. Please try again.")
            return false
        }
    }

    private func addTemplateExercises(_ template: WorkoutTemplate, into workout: Workout, using modelContext: ModelContext) {
        let start = (workout.exercises.map(\.orderIndex).max() ?? -1) + 1
        for (offset, item) in template.sortedExercises.enumerated() {
            let log = ExerciseLog(
                orderIndex: start + offset,
                name: item.name,
                weight: item.defaultWeight,
                reps: max(0, item.defaultReps),
                sets: max(0, item.defaultSets),
                workout: workout
            )
            modelContext.insert(log)
            workout.exercises.append(log)
        }
    }

    private func copyExercises(from source: Workout, to target: Workout, using modelContext: ModelContext) {
        let start = (target.exercises.map(\.orderIndex).max() ?? -1) + 1
        for (offset, log) in source.sortedExercises.enumerated() {
            let copied = ExerciseLog(
                orderIndex: start + offset,
                name: log.name,
                weight: log.weight,
                reps: log.reps,
                sets: log.sets,
                notes: log.notes,
                workout: target
            )
            modelContext.insert(copied)
            target.exercises.append(copied)
        }
    }

    func deleteWorkout(_ workout: Workout) {
        guard let modelContext else { return }
        modelContext.delete(workout)
        do {
            try modelContext.save()
        } catch {
            AppLog.persistence.error("Delete workout save failed: \(String(describing: error))")
            onError?("Couldn’t delete workout. Please try again.")
        }
        fetchWorkouts()
    }

    @discardableResult
    func finishWorkout(_ workout: Workout) -> Bool {
        guard let modelContext else { return false }
        workout.isFinished = true
        workout.finishedAt = Date()
        do {
            try modelContext.save()
            fetchWorkouts()
            return true
        } catch {
            AppLog.persistence.error("Finish workout save failed: \(String(describing: error))")
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
            fetchWorkouts()
            return true
        } catch {
            AppLog.persistence.error("Reopen workout save failed: \(String(describing: error))")
            onError?("Couldn’t continue workout. Please try again.")
            return false
        }
    }
}
