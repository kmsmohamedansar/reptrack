//
//  WgerExercise.swift
//  RepTrack
//
//  Loads wger exercise list from bundled exercises.json (see scripts/fetch-exercises.js).
//

import Foundation

struct WgerExercise: Codable, Identifiable, Hashable {
    let id: Int
    let uuid: String
    let name: String
    let category: String?
    let muscle: String?
    let equipment: [String]?

    var displayCategory: String { category ?? "Other" }
    var displayMuscle: String { muscle ?? "" }
}

enum ExerciseLoader {
    /// Load exercises from exercises.json in the app bundle. Returns empty array if file missing.
    static func loadFromBundle() -> [WgerExercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode([WgerExercise].self, from: data)
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            return []
        }
    }
}
