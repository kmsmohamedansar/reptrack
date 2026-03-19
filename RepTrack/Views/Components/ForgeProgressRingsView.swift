//
//  ForgeProgressRingsView.swift
//  RepTrack
//
//  Three circular progress rings: workouts this week, total sets, total volume.
//  Forge theme: gold stroke, inner glow, dark navy. Animates on appear.
//

import SwiftUI

struct ForgeProgressRingsView: View {
    let workoutsProgress: Double
    let setsProgress: Double
    let volumeProgress: Double
    let workoutsValue: Int
    let setsValue: Int
    let volumeValue: Double
    var embedded: Bool = false

    @State private var animatedWorkouts: Double = 0
    @State private var animatedSets: Double = 0
    @State private var animatedVolume: Double = 0

    private let ringLineWidth: CGFloat = 10
    private let ringSpacing: CGFloat = 14
    private let ringSize: CGFloat = 72

    var body: some View {
        let content = HStack(spacing: 0) {
            ringView(progress: animatedWorkouts, label: "Workouts", value: "\(workoutsValue)")
            ringView(progress: animatedSets, label: "Sets", value: "\(setsValue)")
            ringView(progress: animatedVolume, label: "Volume", value: formatVolume(volumeValue))
        }
        .padding(embedded ? 0 : ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity)

        return Group {
            if embedded {
                content
            } else {
                content
                    .forgeCard()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedWorkouts = workoutsProgress
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.15)) {
                animatedSets = setsProgress
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedVolume = volumeProgress
            }
        }
        .onChange(of: workoutsProgress) { _, new in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedWorkouts = new
                animatedSets = setsProgress
                animatedVolume = volumeProgress
            }
        }
    }

    private func ringView(progress: Double, label: String, value: String) -> some View {
        VStack(spacing: ForgeTheme.spaceXS) {
            ZStack {
                Circle()
                    .stroke(ForgeTheme.ringTrackLight, lineWidth: ringLineWidth)
                    .frame(width: ringSize, height: ringSize)
                Circle()
                    .trim(from: 0, to: min(1, progress))
                    .stroke(
                        LinearGradient(
                            colors: [ForgeTheme.goldLight, ForgeTheme.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ForgeTheme.primaryText)
                    .minimumScaleFactor(0.75)
            }
            ForgeTypography.caption(label)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value)")
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1fk", v / 1000) }
        return "\(Int(v))"
    }
}

#Preview {
    ZStack {
        ForgeTheme.backgroundGradient.ignoresSafeArea()
        ForgeProgressRingsView(
            workoutsProgress: 0.6,
            setsProgress: 0.8,
            volumeProgress: 0.4,
            workoutsValue: 3,
            setsValue: 24,
            volumeValue: 12500
        )
        .padding()
    }
    .preferredColorScheme(.light)
}
