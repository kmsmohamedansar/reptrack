//
//  AnalyticsView.swift
//  RepTrack
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WorkoutsViewModel()
    @State private var selectedExerciseName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForgeTheme.spaceL) {
                ForgeHeaderView(title: "Analytics")

                if !viewModel.recentProgressTrends().isEmpty {
                    trendsCard
                }

                summaryMetricsCard

                ForgeStreakView(
                    currentStreak: viewModel.currentStreak(),
                    longestStreak: viewModel.longestStreak(),
                    embedded: false
                )

                ForgeAnalyticsCard(weekStats: viewModel.weeklyStats(), embedded: false)

                exerciseTrendsSection
            }
            .padding(.bottom, ForgeTheme.gutter)
        }
        .scrollIndicators(.hidden, axes: .vertical)
        .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Reuse current view model architecture: fetch once for this screen.
            viewModel.setModelContext(modelContext)
            viewModel.fetchWorkouts()
            if selectedExerciseName.isEmpty {
                selectedExerciseName = viewModel.trackedExerciseNames().first ?? ""
            }
        }
    }

    private var summaryMetricsCard: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.section("Overview")
            Text("This week at a glance.")
                .font(.caption)
                .foregroundStyle(ForgeTheme.tertiaryText)

            HStack(spacing: ForgeTheme.spaceM) {
                metricPill(value: "\(viewModel.workoutsThisWeek())", label: "Workouts")
                metricPill(value: "\(viewModel.setsThisWeek())", label: "Sets")
                metricPill(value: formatVolume(viewModel.volumeThisWeek()), label: "Volume")
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .padding(.horizontal, ForgeTheme.gutter)
    }

    private var trendsCard: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.section("Recent Progress Trends")
            Text("Most meaningful changes versus last week.")
                .font(.caption)
                .foregroundStyle(ForgeTheme.tertiaryText)
            ForEach(viewModel.recentProgressTrends().prefix(3)) { trend in
                HStack(alignment: .firstTextBaseline, spacing: ForgeTheme.spaceS) {
                    Image(systemName: trend.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(trend.isPositive ? ForgeTheme.gold : ForgeTheme.tertiaryText)
                        .frame(width: 20)
                    Text(trend.message)
                        .font(.subheadline)
                        .foregroundStyle(ForgeTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .padding(.horizontal, ForgeTheme.gutter)
    }

    private func metricPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            ForgeTypography.statValue(value)
            ForgeTypography.statLabel(label)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ForgeTheme.spaceS)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1fk", v / 1000) }
        return "\(Int(v))"
    }

    private var exerciseTrendsSection: some View {
        let names = viewModel.trackedExerciseNames()
        let hasExercises = !names.isEmpty
        let selected = names.contains(selectedExerciseName) ? selectedExerciseName : (names.first ?? "")
        let points = viewModel.exerciseTrend(for: selected)

        return VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.section("Exercise Trends")
            Text("Select one exercise to track progress over time.")
                .font(.caption)
                .foregroundStyle(ForgeTheme.tertiaryText)

            if hasExercises {
                Picker("Exercise", selection: Binding(
                    get: { selected },
                    set: { selectedExerciseName = $0 }
                )) {
                    ForEach(names, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)

                if points.count < 2 {
                    Text("Log this exercise at least twice to see trends.")
                        .font(.subheadline)
                        .foregroundStyle(ForgeTheme.secondaryText)
                        .padding(.vertical, ForgeTheme.spaceS)
                } else {
                    trendChart(
                        title: "Weight trend",
                        points: points,
                        value: { $0.weight },
                        yLabel: "Weight"
                    )
                    trendChart(
                        title: "Reps trend",
                        points: points,
                        value: { Double($0.reps) },
                        yLabel: "Reps"
                    )
                    trendChart(
                        title: "Volume trend",
                        points: points,
                        value: { $0.volume },
                        yLabel: "Volume"
                    )
                }
            } else {
                Text("Add exercises to start viewing lift-specific trends.")
                    .font(.subheadline)
                    .foregroundStyle(ForgeTheme.secondaryText)
                    .padding(.vertical, ForgeTheme.spaceS)
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .padding(.horizontal, ForgeTheme.gutter)
    }

    private func trendChart(
        title: String,
        points: [WorkoutsViewModel.ExerciseTrendPoint],
        value: @escaping (WorkoutsViewModel.ExerciseTrendPoint) -> Double,
        yLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ForgeTheme.primaryText)

            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(yLabel, value(point))
                )
                .foregroundStyle(ForgeTheme.gold)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value(yLabel, value(point))
                )
                .foregroundStyle(ForgeTheme.gold)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(ForgeTheme.tertiaryText)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .foregroundStyle(ForgeTheme.tertiaryText)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(ForgeTheme.gold.opacity(0.12))
                }
            }
            .frame(height: 130)
        }
    }
}

