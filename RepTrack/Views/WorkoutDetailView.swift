//
//  WorkoutDetailView.swift
//  RepTrack
//

import SwiftUI
import SwiftData
import Charts

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

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var notices: ForgeNoticeCenter
    @Bindable var workout: Workout
    @State private var viewModel = WorkoutDetailViewModel()
    @State private var showingAddExercise = false
    @State private var exerciseToEdit: ExerciseLogSheetItem?
    @State private var exerciseToDelete: ExerciseLogDeleteItem?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: ForgeTheme.spaceM) {
                    workoutPerformanceSection
                    if workout.sortedExercises.isEmpty {
                        emptyExercisesCard
                    }
                    ForEach(workout.sortedExercises, id: \.persistentModelID) { log in
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
                            }
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
                viewModel.onError = { message in
                    notices.showError(message)
                }
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

            ForgeFloatingButton(action: { showingAddExercise = true })
                .padding(.horizontal, ForgeTheme.gutter)
                .padding(.bottom, ForgeTheme.gutter)
        }
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

            Text("Add your first exercise to start tracking sets, reps, and progress insights.")
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

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1fk", v / 1000) }
        return "\(Int(v))"
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: Workout(date: Date()))
            .modelContainer(for: [Workout.self, ExerciseLog.self], inMemory: true)
    }
}
