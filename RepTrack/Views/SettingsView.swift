//
//  SettingsView.swift
//  RepTrack
//

import SwiftUI
import SwiftData
import os

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notices: ForgeNoticeCenter
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceL) {
                    dataPrivacyCard
                    aboutCard
                    resetCard
                }
                .padding(ForgeTheme.gutter)
            }
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Reset all data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all workouts and exercises from this device. This can’t be undone.")
            }
        }
    }

    private var dataPrivacyCard: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            Text("Data & Privacy")
                .font(.headline)
                .foregroundStyle(ForgeTheme.primaryText)

            Text("Data is stored locally on your device.")
                .font(.body.weight(.semibold))
                .foregroundStyle(ForgeTheme.primaryText)
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .accessibilityElement(children: .combine)
    }

    private var aboutCard: some View {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

        return VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            Text("About")
                .font(.headline)
                .foregroundStyle(ForgeTheme.primaryText)

            HStack {
                Text("Version")
                    .font(.subheadline)
                    .foregroundStyle(ForgeTheme.secondaryText)
                Spacer()
                Text("\(version) (\(build))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ForgeTheme.primaryText)
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .accessibilityElement(children: .combine)
    }

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            Text("Reset")
                .font(.headline)
                .foregroundStyle(ForgeTheme.primaryText)

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                HStack(spacing: ForgeTheme.spaceS) {
                    Image(systemName: "trash")
                    Text("Reset data")
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForgeTheme.spaceM)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
    }

    private func resetAllData() {
        do {
            let all = try modelContext.fetch(FetchDescriptor<Workout>())
            for w in all { modelContext.delete(w) }
            try modelContext.save()
            notices.showInfo("All data reset.")
        } catch {
            AppLog.persistence.error("Reset data failed: \(String(describing: error))")
            notices.showError("Couldn’t reset data. Please try again.")
        }
    }
}

#Preview {
    SettingsView()
}

