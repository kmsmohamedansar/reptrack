//
//  ForgeAnalyticsCard.swift
//  RepTrack
//
//  Weekly analytics: workouts per week, total weight, sets. Swift Charts, Forge styling.
//

import SwiftUI
import Charts

struct ForgeAnalyticsCard: View {
    let weekStats: [WorkoutsViewModel.WeekStat]
    var embedded: Bool = false

    @State private var appeared = false
    @State private var selectedMetric: Metric = .workouts

    private enum Metric: String, CaseIterable, Identifiable {
        case workouts = "Workouts"
        case sets = "Sets"
        case volume = "Volume"

        var id: String { rawValue }
        var summary: String {
            switch self {
            case .workouts: return "How many workouts you completed each week."
            case .sets: return "Total sets completed each week."
            case .volume: return "Total lifted volume each week."
            }
        }
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.section("Weekly Analytics")

            if weekStats.isEmpty {
                Text("Complete workouts to see analytics")
                    .font(.subheadline)
                    .foregroundStyle(ForgeTheme.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForgeTheme.spaceL)
            } else {
                chartSection
            }
        }
        .padding(embedded ? 0 : ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)

        return Group {
            if embedded {
                content
            } else {
                content
                    .forgeCard()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceL) {
            Picker("Metric", selection: $selectedMetric) {
                ForEach(Metric.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedMetric.summary)
                .font(.caption)
                .foregroundStyle(ForgeTheme.tertiaryText)

            Group {
                switch selectedMetric {
                case .workouts:
                    workoutsChart
                case .sets:
                    setsChart
                case .volume:
                    volumeChart
                }
            }
        }
    }

    private var workoutsChart: some View {
        Chart(weekStats) { stat in
            BarMark(
                x: .value("Week", stat.weekStart, unit: .weekOfYear),
                y: .value("Workouts", stat.workoutCount)
            )
            .foregroundStyle(ForgeTheme.gold.opacity(0.85))
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
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
        .frame(height: 150)
    }

    private var setsChart: some View {
        Chart(weekStats) { stat in
            LineMark(
                x: .value("Week", stat.weekStart, unit: .weekOfYear),
                y: .value("Sets", stat.totalSets)
            )
            .foregroundStyle(ForgeTheme.gold)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
                x: .value("Week", stat.weekStart, unit: .weekOfYear),
                y: .value("Sets", stat.totalSets)
            )
            .foregroundStyle(ForgeTheme.gold)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
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
        .frame(height: 150)
    }

    private var volumeChart: some View {
        Chart(weekStats) { stat in
            LineMark(
                x: .value("Week", stat.weekStart, unit: .weekOfYear),
                y: .value("Volume", stat.totalVolume)
            )
            .foregroundStyle(ForgeTheme.gold)
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("Week", stat.weekStart, unit: .weekOfYear),
                y: .value("Volume", stat.totalVolume)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [ForgeTheme.gold.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
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
        .frame(height: 150)
    }
}
