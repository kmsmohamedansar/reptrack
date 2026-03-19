//
//  WorkoutsViewModel.swift
//  RepTrack
//

import Foundation
import SwiftData

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
}
