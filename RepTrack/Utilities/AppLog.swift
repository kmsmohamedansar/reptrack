import Foundation
import os

enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "RepTrack"
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let general = Logger(subsystem: subsystem, category: "general")
}

