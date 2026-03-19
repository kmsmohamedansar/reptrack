//
//  ForgeHighlightsCardView.swift
//  RepTrack
//

import SwiftUI

struct ForgeHighlightsCardView: View {
    let highlights: [WorkoutsViewModel.Highlight]

    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeTypography.section("Progress highlights")

            VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
                ForEach(highlights.prefix(3)) { h in
                    HStack(alignment: .firstTextBaseline, spacing: ForgeTheme.spaceS) {
                        Image(systemName: h.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ForgeTheme.gold.opacity(0.9))
                            .frame(width: 20, alignment: .leading)

                        Text(h.title)
                            .font(.subheadline)
                            .foregroundStyle(ForgeTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress highlights")
        .accessibilityValue(highlights.map(\.title).joined(separator: ". "))
    }
}

#Preview {
    ZStack {
        ForgeTheme.backgroundGradient.ignoresSafeArea()
        ForgeHighlightsCardView(highlights: [
            .init(title: "New PR on Bench Press", systemImage: "sparkles"),
            .init(title: "Best volume this week", systemImage: "crown.fill"),
            .init(title: "2 workouts completed this week", systemImage: "flame.fill")
        ])
        .padding()
    }
    .preferredColorScheme(.light)
}

