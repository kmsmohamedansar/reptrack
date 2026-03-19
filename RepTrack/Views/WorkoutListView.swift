//
//  WorkoutListView.swift
//  RepTrack
//

import SwiftUI
import SwiftData
import os

private struct WorkoutDeleteItem: Identifiable {
    let workout: Workout
    var id: PersistentIdentifier { workout.persistentModelID }
}

private struct TemplateStartItem: Identifiable {
    let template: WorkoutTemplate
    var id: PersistentIdentifier { template.persistentModelID }
}

private struct WorkoutDuplicateItem: Identifiable {
    let source: Workout
    var id: PersistentIdentifier { source.persistentModelID }
}

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var notices: ForgeNoticeCenter
    @State private var viewModel = WorkoutsViewModel()
    @State private var showingAddWorkout = false
    @State private var showingTemplates = false
    @State private var showingAnalytics = false
    @State private var selectedWorkout: Workout?
    @State private var showingSettings = false
    @State private var workoutToDelete: WorkoutDeleteItem?
    @State private var pendingTemplateStart: TemplateStartItem?
    @State private var pendingDuplicateStart: WorkoutDuplicateItem?
    @State private var successBannerMessage: String?

    private var calendar: Calendar { Calendar.current }
    private var today: Date { calendar.startOfDay(for: Date()) }

    private var todayWorkouts: [Workout] {
        viewModel.workouts.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }

    private var todayActiveWorkout: Workout? {
        todayWorkouts
            .filter { !$0.isFinished }
            .sorted(by: { $0.date > $1.date })
            .first
    }

    private var todayCompletedWorkouts: [Workout] {
        todayWorkouts
            .filter(\.isFinished)
            .sorted(by: { $0.date > $1.date })
    }

    private var todayTargetWorkout: Workout? {
        todayActiveWorkout ?? todayWorkouts.sorted(by: { $0.date > $1.date }).first
    }

    private var isTodayDone: Bool {
        !todayCompletedWorkouts.isEmpty
    }

    private var previousWorkouts: [Workout] {
        viewModel.workouts.filter { !calendar.isDate($0.date, inSameDayAs: today) }
    }

    private var workoutsThisWeek: Int {
        viewModel.workouts.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    private var greetingTitle: String {
        let hour = calendar.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if viewModel.workouts.isEmpty {
                        emptyState
                    } else {
                        workoutList
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .onAppear {
                    viewModel.setModelContext(modelContext)
                    viewModel.onError = { message in
                        notices.showError(message)
                    }
                    // Ensure we show a loading placeholder on first load.
                    DispatchQueue.main.async {
                        viewModel.fetchWorkouts()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    // Best-effort persistence: ensure pending SwiftData changes are flushed.
                    if newPhase == .inactive || newPhase == .background {
                        do {
                            try modelContext.save()
                        } catch {
                            AppLog.persistence.error("Background save failed: \(String(describing: error))")
                            notices.showError("Couldn’t save changes. Please try again.")
                        }
                    }
                }
                .sheet(isPresented: $showingAddWorkout) {
                    AddWorkoutView(onSave: { date in
                        if let existing = viewModel.workout(for: date) {
                            selectedWorkout = existing
                            notices.showInfo("Opened existing workout for that day.")
                        } else if let newWorkout = viewModel.addWorkout(date: date) {
                            selectedWorkout = newWorkout
                        }
                        showingAddWorkout = false
                    }, onCancel: {
                        showingAddWorkout = false
                    })
                }
                .sheet(isPresented: $showingTemplates) {
                    TemplatesView { template in
                        if todayTargetWorkout != nil {
                            pendingTemplateStart = TemplateStartItem(template: template)
                        } else if let newWorkout = viewModel.addWorkout(from: template, date: today) {
                            selectedWorkout = newWorkout
                            notices.showInfo("Workout created from template.")
                        }
                    }
                }
                .navigationDestination(item: $selectedWorkout) { workout in
                    WorkoutDetailView(workout: workout)
                }
                .navigationDestination(isPresented: $showingAnalytics) {
                    AnalyticsView()
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                .alert("Delete workout?", isPresented: Binding(
                    get: { workoutToDelete != nil },
                    set: { if !$0 { workoutToDelete = nil } }
                )) {
                    Button("Cancel", role: .cancel) {
                        workoutToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        guard let item = workoutToDelete else { return }
                        viewModel.deleteWorkout(item.workout)
                        workoutToDelete = nil
                        notices.showInfo("Workout deleted.")
                    }
                } message: {
                    Text("This can’t be undone.")
                }
                .alert(
                    "Start from template",
                    isPresented: Binding(
                        get: { pendingTemplateStart != nil },
                        set: { if !$0 { pendingTemplateStart = nil } }
                    )
                ) {
                    Button("Add template to today’s workout") {
                        guard let item = pendingTemplateStart, let target = todayTargetWorkout else { return }
                        if viewModel.addTemplate(item.template, to: target) {
                            selectedWorkout = target
                            ForgeHaptics.impactLight()
                            successBannerMessage = "Template saved"
                        }
                        pendingTemplateStart = nil
                    }
                    Button("Create separate workout") {
                        guard let item = pendingTemplateStart else { return }
                        if let newWorkout = viewModel.addWorkout(from: item.template, date: today) {
                            selectedWorkout = newWorkout
                            ForgeHaptics.impactLight()
                            successBannerMessage = "Template saved"
                        }
                        pendingTemplateStart = nil
                    }
                    Button("Cancel", role: .cancel) {
                        pendingTemplateStart = nil
                    }
                } message: {
                    Text("A workout already exists for today.")
                }
                .alert(
                    "Duplicate workout",
                    isPresented: Binding(
                        get: { pendingDuplicateStart != nil },
                        set: { if !$0 { pendingDuplicateStart = nil } }
                    )
                ) {
                    Button("Add duplicate to today’s workout") {
                        guard let item = pendingDuplicateStart, let target = todayTargetWorkout else { return }
                        if viewModel.mergeWorkout(item.source, into: target) {
                            selectedWorkout = target
                            notices.showInfo("Workout duplicated into today.")
                        }
                        pendingDuplicateStart = nil
                    }
                    Button("Create separate workout") {
                        guard let item = pendingDuplicateStart else { return }
                        if let newWorkout = viewModel.duplicateWorkout(item.source, date: today) {
                            selectedWorkout = newWorkout
                            notices.showInfo("Workout duplicated.")
                        }
                        pendingDuplicateStart = nil
                    }
                    Button("Cancel", role: .cancel) {
                        pendingDuplicateStart = nil
                    }
                } message: {
                    Text("A workout already exists for today.")
                }

                ForgeFloatingButton(action: { showingAddWorkout = true }, accessibilityLabel: "Add workout")
                    .padding(.horizontal, ForgeTheme.gutter)
                    .padding(.bottom, ForgeTheme.gutter)
            }
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
        }
        .successBanner(message: $successBannerMessage)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.hero("Today's Workouts")

            Text("\(greetingTitle) · \(Date().formatted(date: .complete, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(ForgeTheme.tertiaryText)

            if workoutsThisWeek > 0 {
                HStack(spacing: ForgeTheme.spaceXS) {
                    Image(systemName: "flame.fill")
                        .font(.body)
                        .foregroundStyle(ForgeTheme.gold)
                    Text("\(workoutsThisWeek) workout\(workoutsThisWeek == 1 ? "" : "s") this week")
                        .font(.body)
                        .foregroundStyle(ForgeTheme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ForgeTheme.gutter)
        .padding(.top, ForgeTheme.spaceM)
        .padding(.bottom, ForgeTheme.spaceS)
    }

    private var emptyState: some View {
        VStack(spacing: ForgeTheme.spaceL) {
            Spacer()

            VStack(spacing: ForgeTheme.spaceL) {
                // Subtle illustration/icon
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: 92, height: 92)
                    Circle()
                        .stroke(ForgeTheme.gold.opacity(0.25), lineWidth: 1)
                        .frame(width: 92, height: 92)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(ForgeTheme.gold.opacity(0.9))
                }

                VStack(spacing: ForgeTheme.spaceS) {
                    Text("No workouts yet")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(ForgeTheme.primaryText)
                        .multilineTextAlignment(.center)

                    Text("Start your first session. Tap Add Workout to begin.")
                        .font(.body)
                        .foregroundStyle(ForgeTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    showingAddWorkout = true
                } label: {
                    HStack(spacing: ForgeTheme.spaceS) {
                        Image(systemName: "plus")
                        Text("Add Workout")
                    }
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForgeTheme.spaceM)
                }
                .buttonStyle(.borderedProminent)
                .tint(ForgeTheme.gold)
                .foregroundStyle(.black)

                Button {
                    showingTemplates = true
                } label: {
                    HStack(spacing: ForgeTheme.spaceS) {
                        Image(systemName: "square.stack.3d.up")
                        Text("Templates")
                    }
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForgeTheme.spaceM)
                }
                .buttonStyle(.bordered)
                .tint(ForgeTheme.secondaryText)
            }
            .padding(ForgeTheme.cardPadding)
            .frame(maxWidth: 520)
            .forgeCard()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ForgeTheme.gutter)
    }

    private var workoutList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForgeTheme.spaceXL) {
                ForgeHeaderView(
                    title: "Workouts",
                    onOpenTemplates: { showingTemplates = true },
                    onOpenSettings: { showingSettings = true }
                )
                if viewModel.isLoading && !viewModel.hasLoaded {
                    loadingDashboard
                } else {
                    todayFocusSection
                    headerSection
                    highlightsSection
                    summaryCardSection
                    analyticsEntrySection
                }

                if let active = todayActiveWorkout {
                    sectionHeader("Active Workout")
                    workoutCards([active])
                }

                if !todayCompletedWorkouts.isEmpty {
                    sectionHeader("Completed Today")
                    workoutCards(todayCompletedWorkouts)
                }

                if !previousWorkouts.isEmpty {
                    sectionHeader("Previous Workouts")
                    workoutCards(previousWorkouts)
                }
            }
            .padding(.bottom, ForgeTheme.fabClearance)
        }
        .scrollIndicators(.hidden, axes: .vertical)
    }

    private var loadingDashboard: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            // Today focus skeleton
            ForgeSkeletonCard()
                .padding(.horizontal, ForgeTheme.gutter)

            // Summary skeleton
            ForgeSkeletonCard()
                .padding(.horizontal, ForgeTheme.gutter)

            // A few workout rows
            VStack(spacing: ForgeTheme.spaceM) {
                ForgeSkeletonCard()
                ForgeSkeletonCard()
                ForgeSkeletonCard()
            }
            .padding(.horizontal, ForgeTheme.gutter)
        }
        .padding(.top, ForgeTheme.spaceS)
    }

    private var todayFocusSection: some View {
        let streak = viewModel.currentStreak()
        let mostRecentPrevious = previousWorkouts.first
        let message: String = {
            if streak >= 10 { return "Unstoppable 🔥" }
            if streak >= 5 { return "You're building momentum" }
            if streak >= 1 { return "Good start" }
            return "Start today's workout"
        }()
        let primaryTitle: String = {
            if let active = todayActiveWorkout {
                return active.exercises.isEmpty ? "Start workout" : "Continue workout"
            }
            if isTodayDone { return "Workout done" }
            return "Today"
        }()
        let ctaTitle: String = {
            if let active = todayActiveWorkout {
                return active.exercises.isEmpty ? "Add your first exercise" : "Continue Workout"
            }
            if isTodayDone {
                return "Start another workout"
            }
            return "Start Workout"
        }()
        let ctaAccessibilityLabel: String = {
            if ctaTitle == "Continue Workout" {
                return "Continue today's workout"
            }
            if ctaTitle == "Add your first exercise" {
                return "Open workout and add your first exercise"
            }
            if ctaTitle == "Start another workout" {
                return "Start another workout today"
            }
            return "Start today's workout"
        }()
        let guidanceText: String = {
            if let active = todayActiveWorkout {
                return active.exercises.isEmpty
                    ? "Add exercises to start your live session."
                    : "Continue your active workout and finish when done."
            }
            if isTodayDone {
                return "Today's workout is finished. Start another session if needed."
            }
            return message
        }()
        let sessionStatusText: String = {
            if todayActiveWorkout != nil { return "Active" }
            if isTodayDone { return "Done" }
            return "Not started"
        }()
        let hasActiveWorkout = todayActiveWorkout != nil
        let activeExerciseCount = todayActiveWorkout?.exercises.count ?? 0
        let activeSets = todayActiveWorkout?.exercises.reduce(0) { $0 + $1.sets } ?? 0
        let activeVolume = todayActiveWorkout?.exercises.reduce(0.0) { $0 + ($1.weight * Double($1.reps) * Double($1.sets)) } ?? 0

        return VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(ForgeTheme.primaryText)
                    Text(guidanceText)
                        .font(.body)
                        .foregroundStyle(ForgeTheme.secondaryText)
                }
                Spacer(minLength: ForgeTheme.spaceM)
                Text(sessionStatusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(todayActiveWorkout != nil ? ForgeTheme.gold : ForgeTheme.tertiaryText)
                    .padding(.horizontal, ForgeTheme.spaceM)
                    .padding(.vertical, ForgeTheme.spaceS)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
            }

            Button {
                if let w = viewModel.startOrContinueWorkoutForToday() {
                    selectedWorkout = w
                } else {
                    showingAddWorkout = true
                }
            } label: {
                HStack(spacing: ForgeTheme.spaceS) {
                    Image(systemName: hasActiveWorkout ? "play.fill" : "plus")
                    Text(ctaTitle)
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForgeTheme.spaceM)
            }
            .buttonStyle(.borderedProminent)
            .tint(ForgeTheme.gold)
            .foregroundStyle(.black)
            .accessibilityLabel(ctaAccessibilityLabel)
            .accessibilityHint("Opens today's workout")

            if let _ = todayActiveWorkout, activeExerciseCount > 0 {
                HStack(spacing: ForgeTheme.spaceM) {
                    sessionStatPill(value: "\(activeExerciseCount)", label: "Exercises")
                    sessionStatPill(value: "\(activeSets)", label: "Sets")
                    sessionStatPill(value: formatVolumeCompact(activeVolume), label: "Volume")
                }
            }

            if let active = todayActiveWorkout, !active.exercises.isEmpty {
                Button {
                    if viewModel.finishWorkout(active) {
                        ForgeHaptics.success()
                        successBannerMessage = completionMessage(for: active)
                    }
                } label: {
                    HStack(spacing: ForgeTheme.spaceS) {
                        Image(systemName: "checkmark.circle")
                        Text("Finish Workout")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForgeTheme.spaceS)
                }
                .buttonStyle(.bordered)
                .tint(ForgeTheme.secondaryText)
            }

            if let source = mostRecentPrevious {
                Button {
                    if todayTargetWorkout != nil {
                        pendingDuplicateStart = WorkoutDuplicateItem(source: source)
                    } else if let newWorkout = viewModel.duplicateWorkout(source, date: today) {
                        selectedWorkout = newWorkout
                        notices.showInfo("Workout duplicated.")
                    }
                } label: {
                    HStack(spacing: ForgeTheme.spaceS) {
                        Image(systemName: "doc.on.doc")
                        Text("Duplicate Previous Workout")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForgeTheme.spaceS)
                }
                .buttonStyle(.bordered)
                .tint(ForgeTheme.secondaryText)
            }

            if !todayCompletedWorkouts.isEmpty {
                Text("Finished today: \(todayCompletedWorkouts.count) workout\(todayCompletedWorkouts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(ForgeTheme.tertiaryText)
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .padding(.horizontal, ForgeTheme.gutter)
    }

    private func sessionStatPill(value: String, label: String) -> some View {
        return VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ForgeTheme.primaryText)
            Text(label)
                .font(.caption2)
                .foregroundStyle(ForgeTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ForgeTheme.spaceS)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
    }

    private func formatVolumeCompact(_ volume: Double) -> String {
        if volume >= 1000 { return String(format: "%.1fk", volume / 1000) }
        return "\(Int(volume))"
    }

    private func completionMessage(for workout: Workout) -> String {
        let messages = [
            "Strong session.",
            "Momentum building.",
            "Great consistency.",
            "Nice work.",
            "Another step forward."
        ]
        let index = abs(Int(workout.persistentModelID.hashValue)) % messages.count
        return messages[index]
    }

    private var summaryCardSection: some View {
        ForgeSummaryCardView(
            workoutsProgress: viewModel.maxWorkoutsPerWeek() > 0 ? Double(viewModel.workoutsThisWeek()) / Double(viewModel.maxWorkoutsPerWeek()) : 0,
            setsProgress: viewModel.maxSetsPerWeek() > 0 ? Double(viewModel.setsThisWeek()) / Double(viewModel.maxSetsPerWeek()) : 0,
            volumeProgress: viewModel.maxVolumePerWeek() > 0 ? viewModel.volumeThisWeek() / viewModel.maxVolumePerWeek() : 0,
            workoutsValue: viewModel.workoutsThisWeek(),
            setsValue: viewModel.setsThisWeek(),
            volumeValue: viewModel.volumeThisWeek(),
            currentStreak: viewModel.currentStreak(),
            longestStreak: viewModel.longestStreak(),
            weeklyWorkoutGoal: 3,
            improvementHint: viewModel.improvementSummaryMessage()
        )
        .padding(.horizontal, ForgeTheme.gutter)
    }

    private var analyticsEntrySection: some View {
        Button {
            showingAnalytics = true
        } label: {
            HStack(spacing: ForgeTheme.spaceS) {
                Image(systemName: "chart.xyaxis.line")
                Text("View Full Analytics")
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ForgeTheme.secondaryText)
            .padding(ForgeTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ForgeTheme.gutter)
    }

    @ViewBuilder
    private var highlightsSection: some View {
        let highlights = viewModel.recentHighlights()
        if !highlights.isEmpty {
            ForgeHighlightsCardView(highlights: highlights)
                .padding(.horizontal, ForgeTheme.gutter)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        return ForgeTypography.section(title)
            .padding(.horizontal, ForgeTheme.gutter)
            .padding(.top, ForgeTheme.spaceS)
    }

    private func workoutCards(_ workouts: [Workout]) -> some View {
        return LazyVStack(spacing: ForgeTheme.spaceM) {
            ForEach(Array(workouts.enumerated()), id: \.element.persistentModelID) { index, workout in
                Button {
                    selectedWorkout = workout
                } label: {
                    WorkoutCardView(workout: workout)
                }
                .buttonStyle(ForgeCardButtonStyle())
                .contextMenu {
                    Button(role: .destructive) {
                        workoutToDelete = WorkoutDeleteItem(workout: workout)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity
                ))
                .animation(.easeOut(duration: ForgeTheme.standard).delay(Double(index) * 0.05), value: viewModel.workouts.count)
            }
        }
        .padding(.horizontal, ForgeTheme.gutter)
        .padding(.bottom, ForgeTheme.spaceM)
    }
}

private struct ForgeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: ForgeTheme.quick), value: configuration.isPressed)
    }
}

#Preview {
    WorkoutListView()
        .modelContainer(for: [Workout.self, ExerciseLog.self], inMemory: true)
}
