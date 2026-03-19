//
//  RepTrackApp.swift
//  RepTrack
//
//  Created by ANSAR on 2026-03-13.
//

import SwiftUI
import SwiftData
import os

@main
struct RepTrackApp: App {
    @State private var showSplash = true
    @StateObject private var notices = ForgeNoticeCenter()

    private let sharedModelContainer: ModelContainer? = {
        let schema = Schema([Workout.self, ExerciseLog.self])

        do {
            let disk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [disk])
        } catch {
            AppLog.persistence.error("ModelContainer init failed (disk). Error: \(String(describing: error))")
        }

        do {
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [memory])
        } catch {
            AppLog.persistence.critical("ModelContainer init failed (in-memory). Error: \(String(describing: error))")
            return nil
        }
    }()

    var body: some Scene {
        WindowGroup {
            if let sharedModelContainer {
                ZStack {
                    WorkoutListView()
                        .environmentObject(notices)

                    if showSplash {
                        NorthstarForgeSplashView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.88)),
                                removal: .opacity.combined(with: .scale(scale: 1.06))
                            ))
                            .zIndex(1)
                    }
                }
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light)
                .animation(.easeOut(duration: 0.5), value: showSplash)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        showSplash = false
                    }
                }
                .forgeNotices(notices)
            } else {
                ZStack {
                    ForgeTheme.backgroundGradient.ignoresSafeArea()
                    VStack(spacing: ForgeTheme.spaceM) {
                        Image(systemName: "externaldrive.badge.exclamationmark")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(ForgeTheme.gold)
                        Text("Storage unavailable")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ForgeTheme.primaryText)
                        Text("RepTrack couldn’t initialize local storage. Please restart the app or reinstall.")
                            .font(.body)
                            .foregroundStyle(ForgeTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(ForgeTheme.gutter)
                }
                .preferredColorScheme(.light)
            }
        }
    }
}
