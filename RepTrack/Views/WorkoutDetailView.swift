//
//  WorkoutDetailView.swift
//  RepTrack
//

import SwiftUI
import SwiftData
import Charts
import os

private struct ExerciseLogSheetItem: Identifiable {
    let log: ExerciseLog
    var id: PersistentIdentifier { log.persistentModelID }
}

private struct ExerciseLogDeleteItem: Identifiable {
    let log: ExerciseLog
    var id: PersistentIdentifier { log.persistentModelID }
}

private struct WeightPoint: Identifiable {
    let id = UUID()
    let name: String
    let weight: Double
}

private struct DetailDuplicateItem: Identifiable {
    let source: Workout
    var id: PersistentIdentifier { source.persistentModelID }
}

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var notices: ForgeNoticeCenter
    @Query(sort: [SortDescriptor(\Workout.date, order: .reverse)])
    private var allWorkouts: [Workout]
    @Bindable var workout: Workout
    @State private var viewModel = WorkoutDetailViewModel()
    @State private var showingAddExercise = false
    @State private var showingSaveTemplate = false
    @State private var exerciseToEdit: ExerciseLogSheetItem?
    @State private var exerciseToDelete: ExerciseLogDeleteItem?
    @State private var pendingDuplicate: DetailDuplicateItem?
    @State private var duplicatedWorkout: Workout?
    @State private var showFinishConfirm = false
    @State private var showingReorderExercises = false
    @State private var workoutNotes: String = ""
    @State private var notesSaveTask: Task<Void, Never>?
    @State private var isSyncingWorkoutNotes = false
    @State private var isEditingWorkoutNotes = false
    @State private var successBannerMessage: String?
    @State private var showNotesSavedCue = false
    @State private var notesSavedCueTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: ForgeTheme.spaceM) {
                    workoutPerformanceSection
                    workoutNotesSection
                    if workout.sortedExercises.isEmpty {
                        emptyExercisesCard
                    }
                    ForEach(workout.sortedExercises, id: \.persistentModelID) { log in
                        let prTypes = viewModel.prTypesAchieved(for: log)
                        let prBadgeText = prTypes.isEmpty ? nil : "New PR"
                        ExerciseCardView(
                            log: log,
                            progression: viewModel.previousLog(forExerciseName: log.name),
                            onUpdate: { weight, reps, sets in
                                viewModel.updateExercise(log, name: log.name, weight: weight, reps: reps, sets: sets, notes: log.notes)
                            },
                            onEdit: {
                                exerciseToEdit = ExerciseLogSheetItem(log: log)
                            },
                            onDelete: {
                                exerciseToDelete = ExerciseLogDeleteItem(log: log)
                            },
                            onAutosaveError: { message in
                                notices.showError(message)
                            },
                            prBadgeText: prBadgeText
                        )
                    }
                }
                .padding(ForgeTheme.gutter)
                .padding(.bottom, ForgeTheme.fabClearance)
            }
            .scrollIndicators(.hidden, axes: .vertical)
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(workout.date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.setModelContext(modelContext)
                viewModel.setWorkout(workout)
                syncNotesFromModel()
                viewModel.onError = { message in
                    notices.showError(message)
                }
            }
            .onChange(of: workout.notes) { _, _ in
                syncNotesFromModel()
            }
            .onChange(of: workoutNotes) { _, _ in
                autosaveWorkoutNotes()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
                    do {
                        try modelContext.save()
                    } catch {
                        AppLog.persistence.error("Background save (detail) failed: \(String(describing: error))")
                        notices.showError("Couldn’t save changes. Please try again.")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingSaveTemplate = true
                        } label: {
                            Label("Save template", systemImage: "square.on.square")
                        }
                        Button {
                            startDuplicateFlow(from: workout)
                        } label: {
                            Label("Duplicate Workout", systemImage: "doc.on.doc")
                        }
                        if workout.sortedExercises.count > 1 {
                            Button {
                                showingReorderExercises = true
                            } label: {
                                Label("Reorder exercises", systemImage: "line.3.horizontal")
                            }
                        }
                        if workout.isFinished {
                            Button {
                                if viewModel.reopenWorkout(workout) {
                                    notices.showInfo("Workout is active again.")
                                }
                            } label: {
                                Label("Continue workout", systemImage: "play.fill")
                            }
                        } else {
                            Button {
                                showFinishConfirm = true
                            } label: {
                                Label("Finish workout", systemImage: "checkmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView(workout: workout) { name, weight, reps, sets, notes in
                    viewModel.addExercise(name: name, weight: weight, reps: reps, sets: sets, notes: notes)
                    showingAddExercise = false
                } onCancel: {
                    showingAddExercise = false
                }
            }
            .sheet(item: $exerciseToEdit) { item in
                EditExerciseView(log: item.log) { name, weight, reps, sets, notes in
                    viewModel.updateExercise(item.log, name: name, weight: weight, reps: reps, sets: sets, notes: notes)
                    exerciseToEdit = nil
                } onCancel: {
                    exerciseToEdit = nil
                }
            }
            .sheet(isPresented: $showingSaveTemplate) {
                SaveWorkoutTemplateView(defaultName: defaultTemplateName) { name in
                    if viewModel.saveWorkoutAsTemplate(workout, templateName: name) {
                        ForgeHaptics.impactLight()
                        successBannerMessage = "Template saved"
                    }
                    showingSaveTemplate = false
                } onCancel: {
                    showingSaveTemplate = false
                }
            }
            .sheet(isPresented: $showingReorderExercises) {
                NavigationStack {
                    List {
                        ForEach(workout.sortedExercises, id: \.persistentModelID) { log in
                            HStack(spacing: ForgeTheme.spaceS) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(ForgeTheme.tertiaryText)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(ForgeTheme.primaryText)
                                    Text("\(log.sets)x\(log.reps) · \(Int(log.weight)) lb")
                                        .font(.caption)
                                        .foregroundStyle(ForgeTheme.secondaryText)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onMove { indices, newOffset in
                            if viewModel.reorderExercises(in: workout, from: indices, to: newOffset) {
                                ForgeHaptics.impactLight()
                                successBannerMessage = "Exercise order updated"
                            }
                        }
                    }
                    .environment(\.editMode, .constant(.active))
                    .scrollContentBackground(.hidden)
                    .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
                    .navigationTitle("Reorder exercises")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingReorderExercises = false }
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationDestination(item: $duplicatedWorkout) { duplicated in
                WorkoutDetailView(workout: duplicated)
            }
            .alert("Delete exercise?", isPresented: Binding(
                get: { exerciseToDelete != nil },
                set: { if !$0 { exerciseToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    exerciseToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    guard let item = exerciseToDelete else { return }
                    viewModel.deleteExercise(item.log)
                    exerciseToDelete = nil
                    notices.showInfo("Exercise deleted.")
                }
            } message: {
                Text("This can’t be undone.")
            }
            .alert("Finish workout?", isPresented: $showFinishConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Finish", role: .destructive) {
                    if viewModel.finishWorkout(workout) {
                        ForgeHaptics.success()
                        successBannerMessage = completionMessage()
                    }
                }
            } message: {
                Text("You can still reopen it later from the menu.")
            }
            .alert(
                "Duplicate workout",
                isPresented: Binding(
                    get: { pendingDuplicate != nil },
                    set: { if !$0 { pendingDuplicate = nil } }
                )
            ) {
                Button("Add duplicate to today’s workout") {
                    guard let item = pendingDuplicate, let today = todayWorkout else { return }
                    if viewModel.mergeWorkout(item.source, into: today) {
                        notices.showInfo("Workout duplicated into today.")
                        if today.persistentModelID != workout.persistentModelID {
                            duplicatedWorkout = today
                        }
                    }
                    pendingDuplicate = nil
                }
                Button("Create separate workout") {
                    guard let item = pendingDuplicate else { return }
                    if let duplicated = viewModel.duplicateWorkout(item.source, date: startOfToday) {
                        duplicatedWorkout = duplicated
                        notices.showInfo("Workout duplicated.")
                    }
                    pendingDuplicate = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDuplicate = nil
                }
            } message: {
                Text("A workout already exists for today.")
            }

            ForgeFloatingButton(
                action: { showingAddExercise = true },
                accessibilityLabel: "Add exercise",
                accessibilityHint: "Opens add exercise screen"
            )
                .padding(.horizontal, ForgeTheme.gutter)
                .padding(.bottom, ForgeTheme.gutter)
        }
        .onDisappear {
            notesSaveTask?.cancel()
            saveWorkoutNotes()
        }
        .successBanner(message: $successBannerMessage)
    }

    private var emptyExercisesCard: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            HStack(spacing: ForgeTheme.spaceS) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ForgeTheme.gold)
                Text("No exercises yet")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(ForgeTheme.primaryText)
                Spacer(minLength: 0)
            }

            Text("Start this session by adding your first exercise.")
                .font(.body)
                .foregroundStyle(ForgeTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showingAddExercise = true
            } label: {
                HStack(spacing: ForgeTheme.spaceS) {
                    Image(systemName: "plus")
                    Text("Add Exercise")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
    }

    @ViewBuilder
    private var workoutPerformanceSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.section("Workout Performance")

            HStack(spacing: ForgeTheme.spaceS) {
                Image(systemName: workout.isFinished ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(workout.isFinished ? ForgeTheme.tertiaryText : ForgeTheme.gold)
                Text(workout.isFinished ? "Finished workout" : "Active workout")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(workout.isFinished ? ForgeTheme.tertiaryText : ForgeTheme.secondaryText)
            }
            .padding(.horizontal, ForgeTheme.spaceM)
            .padding(.vertical, ForgeTheme.spaceS)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())

            if let insight = viewModel.progressInsight(for: workout) {
                HStack(alignment: .top, spacing: ForgeTheme.spaceS) {
                    Image(systemName: insight.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(insight.tone == .positive ? ForgeTheme.gold : ForgeTheme.tertiaryText)
                        .frame(width: 24, height: 24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ForgeTheme.primaryText)
                        Text(insight.message)
                            .font(.caption)
                            .foregroundStyle(ForgeTheme.secondaryText)
                    }

                    Spacer(minLength: 0)
                }
                .padding(ForgeTheme.spaceM)
                .background(
                    RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous)
                        .fill(insight.tone == .positive ? ForgeTheme.gold.opacity(0.06) : Color(.secondarySystemGroupedBackground))
                )
            }

            HStack(spacing: ForgeTheme.spaceL) {
                statPill(value: "\(viewModel.totalSets(for: workout))", label: "Sets")
                statPill(value: "\(viewModel.totalReps(for: workout))", label: "Reps")
                statPill(value: formatVolume(viewModel.totalVolume(for: workout)), label: "Volume")
                statPill(value: "~\(viewModel.estimatedCalories(for: workout))", label: "Cal")
            }

            let exerciseInsights = viewModel.exerciseInsights(for: workout)
            if !exerciseInsights.isEmpty {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
                    ForEach(exerciseInsights.prefix(3)) { insight in
                        HStack(alignment: .firstTextBaseline, spacing: ForgeTheme.spaceS) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.caption)
                                .foregroundStyle(ForgeTheme.gold)
                            Text("\(insight.exerciseName): \(insight.message)")
                                .font(.caption)
                                .foregroundStyle(ForgeTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(ForgeTheme.spaceM)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
            }

            let prs = viewModel.prsAchieved(in: workout)
            if !prs.isEmpty {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
                    ForgeTypography.section("Personal records")
                    ForEach(prs.prefix(4)) { pr in
                        Text("• \(pr.exerciseName): \(pr.prTypes.map(\.rawValue).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(ForgeTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(ForgeTheme.spaceM)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
            }

            let progression = viewModel.weightProgression(for: workout)
            if !progression.isEmpty {
                Chart(progression.map { WeightPoint(name: $0.name, weight: $0.points.last?.1 ?? 0) }) { point in
                    BarMark(
                        x: .value("Exercise", point.name),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(ForgeTheme.gold.opacity(0.7))
                    .cornerRadius(4)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weight progression")
                .accessibilityValue(chartAccessibilitySummary(from: progression))
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(ForgeTheme.tertiaryText)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(ForgeTheme.tertiaryText)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
    }

    private func chartAccessibilitySummary(from progression: [(name: String, points: [(Date, Double)])]) -> String {
        let lastPoints = progression.compactMap { item -> (String, Double)? in
            guard let last = item.points.last?.1, last > 0 else { return nil }
            return (item.name, last)
        }
        guard !lastPoints.isEmpty else { return "No data." }
        let top = lastPoints.max(by: { $0.1 < $1.1 })
        if let top {
            return "\(lastPoints.count) exercises. Highest: \(top.0) at \(Int(top.1)) pounds."
        }
        return "\(lastPoints.count) exercises."
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            ForgeTypography.statValue(value)
            ForgeTypography.statLabel(label)
        }
        .frame(maxWidth: .infinity)
    }

    private var workoutNotesSection: some View {
        let trimmedNotes = workoutNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasNotes = !trimmedNotes.isEmpty

        return VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            HStack {
                ForgeTypography.section("Notes")
                Spacer(minLength: 0)
                if hasNotes && !isEditingWorkoutNotes {
                    Button {
                        isEditingWorkoutNotes = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ForgeTheme.secondaryText)
                }
            }

            if isEditingWorkoutNotes || !hasNotes {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $workoutNotes)
                        .font(.body)
                        .foregroundStyle(ForgeTheme.primaryText)
                        .frame(minHeight: 96)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .textInputAutocapitalization(.sentences)

                    if trimmedNotes.isEmpty {
                        Text("Add a note about this session")
                            .font(.body)
                            .foregroundStyle(ForgeTheme.tertiaryText)
                            .padding(.top, 8)
                            .padding(.leading, 6)
                            .allowsHitTesting(false)
                    }
                }
                .padding(ForgeTheme.spaceS)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))

                if hasNotes {
                    HStack {
                        Spacer(minLength: 0)
                        Button("Done") {
                            saveWorkoutNotes()
                            isEditingWorkoutNotes = false
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ForgeTheme.secondaryText)
                    }
                }
            } else {
                Button {
                    isEditingWorkoutNotes = true
                } label: {
                    Text(trimmedNotes)
                        .font(.body)
                        .foregroundStyle(ForgeTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(ForgeTheme.spaceM)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text("Saved just now")
                .font(.caption2)
                .foregroundStyle(ForgeTheme.tertiaryText)
                .opacity(showNotesSavedCue ? 1 : 0)
                .animation(.easeInOut(duration: ForgeTheme.quick), value: showNotesSavedCue)
                .frame(height: 14, alignment: .leading)
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
    }

    private func syncNotesFromModel() {
        guard workoutNotes != workout.notes else { return }
        isSyncingWorkoutNotes = true
        workoutNotes = workout.notes
        DispatchQueue.main.async {
            isSyncingWorkoutNotes = false
        }
    }

    private func autosaveWorkoutNotes() {
        guard !isSyncingWorkoutNotes else { return }
        notesSaveTask?.cancel()
        notesSaveTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
            } catch {
                return
            }
            saveWorkoutNotes()
        }
    }

    @MainActor
    private func saveWorkoutNotes() {
        workout.notes = workoutNotes
        do {
            try modelContext.save()
            showNotesSavedConfidenceCue()
        } catch {
            AppLog.persistence.error("Save workout notes failed: \(String(describing: error))")
            notices.showError("Couldn’t save notes. Please try again.")
        }
    }

    private func showNotesSavedConfidenceCue() {
        notesSavedCueTask?.cancel()
        showNotesSavedCue = true
        notesSavedCueTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_600_000_000)
            } catch {
                return
            }
            showNotesSavedCue = false
        }
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1fk", v / 1000) }
        return "\(Int(v))"
    }

    private var defaultTemplateName: String {
        let weekday = workout.date.formatted(.dateTime.weekday(.wide))
        return "\(weekday) Template"
    }

    private var calendar: Calendar { Calendar.current }
    private var startOfToday: Date { calendar.startOfDay(for: Date()) }
    private var todayWorkout: Workout? {
        allWorkouts.first { calendar.isDate($0.date, inSameDayAs: startOfToday) }
    }

    private func startDuplicateFlow(from source: Workout) {
        if todayWorkout != nil {
            pendingDuplicate = DetailDuplicateItem(source: source)
        } else if let duplicated = viewModel.duplicateWorkout(source, date: startOfToday) {
            duplicatedWorkout = duplicated
            notices.showInfo("Workout duplicated.")
        }
    }

    private func completionMessage() -> String {
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
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: Workout(date: Date()))
            .modelContainer(for: [Workout.self, ExerciseLog.self], inMemory: true)
    }
}
