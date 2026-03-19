//
//  ForgeHeaderView.swift
//  RepTrack
//
//  Guild crest–style header: logo, title, glowing star.
//

import SwiftUI

struct ForgeHeaderView: View {
    let title: String
    var onOpenTemplates: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: ForgeTheme.spaceS) {
            logoBadge
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ForgeTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailingIcon
        }
        .padding(.horizontal, ForgeTheme.gutter)
        .padding(.vertical, ForgeTheme.spaceM)
    }

    private var logoBadge: some View {
        ZStack {
            Circle()
                .fill(ForgeTheme.backgroundLight)
                .frame(width: 44, height: 44)
            Circle()
                .stroke(ForgeTheme.gold.opacity(0.6), lineWidth: 1.5)
                .frame(width: 44, height: 44)
            Image(systemName: "star.fill")
                .font(.system(size: 20))
                .foregroundStyle(ForgeTheme.gold)
        }
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if onOpenTemplates != nil || onOpenSettings != nil {
            HStack(spacing: ForgeTheme.spaceM) {
                if let onOpenTemplates {
                    Button(action: onOpenTemplates) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ForgeTheme.gold)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Templates")
                }
                if let onOpenSettings {
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(ForgeTheme.gold)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                }
            }
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ForgeTheme.gold)
        }
    }
}

#Preview {
    ZStack {
        ForgeTheme.backgroundGradient.ignoresSafeArea()
        VStack {
            ForgeHeaderView(title: "Workouts")
            Spacer()
        }
    }
    .preferredColorScheme(.light)
}
