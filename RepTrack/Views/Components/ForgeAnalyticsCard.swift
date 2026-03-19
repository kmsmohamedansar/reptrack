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
            Chart(weekStats) { stat in
                BarMark(
                    x: .value("Week", stat.weekStart, unit: .weekOfYear),
                    y: .value("Workouts", stat.workoutCount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ForgeTheme.gold.opacity(0.6), ForgeTheme.gold],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(ForgeTheme.tertiaryText)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(ForgeTheme.gold.opacity(0.15))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .foregroundStyle(ForgeTheme.tertiaryText)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(ForgeTheme.gold.opacity(0.15))
                }
            }
            .frame(height: 140)

            HStack(spacing: ForgeTheme.spaceL) {
                legendItem(title: "Volume", value: formatTotalVolume(weekStats))
                legendItem(title: "Sets", value: "\(weekStats.reduce(0) { $0 + $1.totalSets })")
            }
            .font(.caption)
            .foregroundStyle(ForgeTheme.secondaryText)
        }
    }

    private func legendItem(title: String, value: String) -> some View {
        HStack(spacing: ForgeTheme.spaceXS) {
            Circle()
                .fill(ForgeTheme.gold.opacity(0.6))
                .frame(width: 6, height: 6)
            Text("\(title): \(value)")
        }
    }

    private func formatTotalVolume(_ stats: [WorkoutsViewModel.WeekStat]) -> String {
        let total = stats.reduce(0.0) { $0 + $1.totalVolume }
        if total >= 1000 { return String(format: "%.1fk lb", total / 1000) }
        return "\(Int(total)) lb"
    }
}
