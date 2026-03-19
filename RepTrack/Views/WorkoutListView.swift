//
//  WorkoutListView.swift
//  RepTrack
//

import SwiftUI
import SwiftData

private struct WorkoutDeleteItem: Identifiable {
    let workout: Workout
    var id: PersistentIdentifier { workout.persistentModelID }
}

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var notices: ForgeNoticeCenter
    @State private var viewModel = WorkoutsViewModel()
    @State private var showingAddWorkout = false
    @State private var selectedWorkout: Workout?
    @State private var showingSettings = false
    @State private var workoutToDelete: WorkoutDeleteItem?

    private var calendar: Calendar { Calendar.current }
    private var today: Date { calendar.startOfDay(for: Date()) }

    private var todayWorkouts: [Workout] {
        viewModel.workouts.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }

    private var todayWorkout: Workout? {
        todayWorkouts.sorted(by: { $0.date > $1.date }).first
    }

    private var isTodayDone: Bool {
        guard let w = todayWorkout else { return false }
        return !w.exercises.isEmpty
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
                        if let newWorkout = viewModel.addWorkout(date: date) {
                            selectedWorkout = newWorkout
                        }
                        showingAddWorkout = false
                    }, onCancel: {
                        showingAddWorkout = false
                    })
                }
                .navigationDestination(item: $selectedWorkout) { workout in
                    WorkoutDetailView(workout: workout)
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

                ForgeFloatingButton(action: { showingAddWorkout = true }, accessibilityLabel: "Add workout")
                    .padding(.horizontal, ForgeTheme.gutter)
                    .padding(.bottom, ForgeTheme.gutter)
            }
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.section(Date().formatted(date: .complete, time: .omitted))

            Text(greetingTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(ForgeTheme.primaryText)

            ForgeTypography.hero("Today's Workouts")

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
                    Text("Start your first workout today")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(ForgeTheme.primaryText)
                        .multilineTextAlignment(.center)

                    Text("Log your first session and start building momentum.")
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
                ForgeHeaderView(title: "Workouts", onOpenSettings: { showingSettings = true })
                if viewModel.isLoading && !viewModel.hasLoaded {
                    loadingDashboard
                } else {
                    todayFocusSection
                    headerSection
                    summaryCardSection
                }

                if !todayWorkouts.isEmpty {
                    sectionHeader("Today")
                    workoutCards(todayWorkouts)
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
        let hasWorkout = todayWorkout != nil
        let primaryTitle = isTodayDone ? "Workout done" : "Today"
        let statusText = isTodayDone ? "Done" : (hasWorkout ? "Not done" : "Not started")
        let message: String = {
            if streak >= 10 { return "Unstoppable 🔥" }
            if streak >= 5 { return "You're building momentum" }
            if streak >= 1 { return "Good start" }
            return "Start today's workout"
        }()
        let ctaTitle = hasWorkout ? "Continue Workout" : "Start Workout"

        return VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(ForgeTheme.primaryText)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(ForgeTheme.secondaryText)
                }
                Spacer(minLength: ForgeTheme.spaceM)
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isTodayDone ? ForgeTheme.gold : ForgeTheme.tertiaryText)
                    .padding(.horizontal, ForgeTheme.spaceM)
                    .padding(.vertical, ForgeTheme.spaceS)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
            }

            Button {
                if let w = todayWorkout {
                    selectedWorkout = w
                } else if let w = viewModel.addWorkout(date: today) {
                    selectedWorkout = w
                } else {
                    showingAddWorkout = true
                }
            } label: {
                HStack(spacing: ForgeTheme.spaceS) {
                    Image(systemName: hasWorkout ? "play.fill" : "plus")
                    Text(ctaTitle)
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForgeTheme.spaceM)
            }
            .buttonStyle(.borderedProminent)
            .tint(ForgeTheme.gold)
            .foregroundStyle(.black)
            .accessibilityLabel(hasWorkout ? "Continue today's workout" : "Start today's workout")
            .accessibilityHint("Opens today's workout")
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .padding(.horizontal, ForgeTheme.gutter)
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
            weekStats: viewModel.weeklyStats(),
            weeklyWorkoutGoal: 3
        )
        .padding(.horizontal, ForgeTheme.gutter)
    }

    private func sectionHeader(_ title: String) -> some View {
        ForgeTypography.section(title)
            .padding(.horizontal, ForgeTheme.gutter)
            .padding(.top, ForgeTheme.spaceS)
    }

    private func workoutCards(_ workouts: [Workout]) -> some View {
        LazyVStack(spacing: ForgeTheme.spaceM) {
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
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: viewModel.workouts.count)
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
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    WorkoutListView()
        .modelContainer(for: [Workout.self, ExerciseLog.self], inMemory: true)
}
