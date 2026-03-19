//
//  ExerciseCardView.swift
//  RepTrack
//
//  Card for a single exercise: name, sets/reps/weight, optional inline edit, progression.
//

import SwiftUI
import SwiftData
import os

struct ExerciseCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var log: ExerciseLog
    let previous: ExerciseLog?
    var onUpdate: ((Double, Int, Int) -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onAutosaveError: ((String) -> Void)?

    init(
        log: ExerciseLog,
        progression previous: ExerciseLog?,
        onUpdate: ((Double, Int, Int) -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onAutosaveError: ((String) -> Void)? = nil
    ) {
        self.log = log
        self.previous = previous
        self.onUpdate = onUpdate
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onAutosaveError = onAutosaveError
    }

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var setsText: String = ""
    @FocusState private var focusedField: Field?
    @State private var isSyncingFromModel = false
    @State private var autosaveTask: Task<Void, Never>?

    private enum Field {
        case weight, reps, sets
    }

    private var progressionDisplay: ProgressionDisplay {
        let progression = ProgressionHelper.progression(current: log, previous: previous)
        return ProgressionHelper.displayText(for: progression)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            headerRow

            if let onUpdate = onUpdate {
                inlineEditSection(onUpdate: onUpdate)
            } else {
                readOnlyPills
            }

            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            progressionBadge
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .onAppear {
            syncFromLog()
        }
        .onChange(of: log.weight) { _, _ in syncFromLog() }
        .onChange(of: log.reps) { _, _ in syncFromLog() }
        .onChange(of: log.sets) { _, _ in syncFromLog() }
        .onChange(of: weightText) { _, _ in autosaveFromTextFields() }
        .onChange(of: repsText) { _, _ in autosaveFromTextFields() }
        .onChange(of: setsText) { _, _ in autosaveFromTextFields() }
        .onChange(of: focusedField) { _, newValue in
            if newValue == nil, let o = onUpdate {
                o(parsedWeight, parsedReps, parsedSets)
            }
        }
        .onDisappear {
            // Best-effort commit if user navigates away mid-edit.
            commitToModelAndSave()
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: ForgeTheme.spaceS) {
            Text(log.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: ForgeTheme.spaceS)

            if onEdit != nil || onDelete != nil {
                HStack(spacing: ForgeTheme.spaceS) {
                    if let onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ForgeTheme.secondaryText)
                                .frame(width: 32, height: 32)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit exercise")
                    }

                    if let onDelete {
                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.red)
                                .frame(width: 32, height: 32)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete exercise")
                    }
                }
            }
        }
    }

    private var parsedWeight: Double {
        Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var parsedReps: Int { Int(repsText) ?? 0 }
    private var parsedSets: Int { Int(setsText) ?? 0 }

    private func syncFromLog() {
        isSyncingFromModel = true
        weightText = log.weight > 0 ? "\(Int(log.weight))" : ""
        repsText = log.reps > 0 ? "\(log.reps)" : ""
        setsText = log.sets > 0 ? "\(log.sets)" : ""
        // Avoid autosave triggering from programmatic sync.
        DispatchQueue.main.async {
            isSyncingFromModel = false
        }
    }

    private func autosaveFromTextFields() {
        guard !isSyncingFromModel else { return }
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            } catch {
                return
            }
            commitToModelAndSave()
        }
    }

    @MainActor
    private func commitToModelAndSave() {
        // Update the model live so backgrounding doesn't lose in-progress edits.
        log.weight = parsedWeight
        log.reps = max(0, parsedReps)
        log.sets = max(0, parsedSets)
        do {
            try modelContext.save()
        } catch {
            AppLog.persistence.error("Autosave exercise failed: \(String(describing: error))")
            onAutosaveError?("Couldn’t save. Try again.")
        }
        if let o = onUpdate {
            o(log.weight, log.reps, log.sets)
        }
    }

    private var readOnlyPills: some View {
        HStack(spacing: ForgeTheme.spaceM) {
            DetailPill(icon: "scalemass.fill", text: "\(Int(log.weight)) lb")
            DetailPill(icon: "repeat", text: "\(log.reps) reps")
            DetailPill(icon: "square.stack", text: "\(log.sets) sets")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func inlineEditSection(onUpdate: @escaping (Double, Int, Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            ForgeTypography.caption("Weight, reps & sets — tap to edit")
            HStack(spacing: ForgeTheme.spaceM) {
                inlineField(
                    label: "Weight (lb)",
                    text: $weightText,
                    field: .weight
                ) {
                    commitEdit(onUpdate: onUpdate)
                }
                inlineField(
                    label: "Reps",
                    text: $repsText,
                    field: .reps
                ) {
                    commitEdit(onUpdate: onUpdate)
                }
                inlineField(
                    label: "Sets",
                    text: $setsText,
                    field: .sets
                ) {
                    commitEdit(onUpdate: onUpdate)
                }
            }
        }
    }

    private func inlineField(
        label: String,
        text: Binding<String>,
        field: Field,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(ForgeTheme.tertiaryText)
            TextField("0", text: text)
                .keyboardType(field == .weight ? .decimalPad : .numberPad)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: field)
                .onSubmit { onSubmit() }
        }
    }

    private func commitEdit(onUpdate: @escaping (Double, Int, Int) -> Void) {
        onUpdate(parsedWeight, parsedReps, parsedSets)
    }

    @ViewBuilder
    private var progressionBadge: some View {
        switch progressionDisplay {
        case .noPrevious:
            EmptyView()
        case .same:
            Label("Same as last session", systemImage: "minus.circle")
                .font(.caption)
                .foregroundStyle(ForgeTheme.tertiaryText)
        case .improved(let text):
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ForgeTheme.gold)
                Text(compactProgressionText(text))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ForgeTheme.primaryText)
            }
        case .regressed(let text):
            Label(text, systemImage: "arrow.down.circle")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    private func compactProgressionText(_ full: String) -> String {
        let cleaned = full
            .replacingOccurrences(of: " from last session", with: "")
            .replacingOccurrences(of: " · ", with: "  ▲ ")
        if cleaned == full { return full }
        return "▲ \(cleaned)"
    }
}

private struct DetailPill: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
    }
}

#Preview {
    ScrollView {
        ExerciseCardView(
            log: ExerciseLog(name: "Bench Press", weight: 135, reps: 10, sets: 3),
            progression: ExerciseLog(name: "Bench Press", weight: 130, reps: 10, sets: 3)
        )
        .padding(.horizontal)
    }
    .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
}
