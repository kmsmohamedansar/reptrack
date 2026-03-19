//
//  EditExerciseView.swift
//  RepTrack
//

import SwiftUI
import SwiftData

struct EditExerciseView: View {
    @Bindable var log: ExerciseLog
    @State private var wgerExercises: [WgerExercise] = []
    @State private var isLoadingExercises = false
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedWgerId: Int?
    @State private var selectedTemplate: ExerciseTemplate?
    @State private var name: String = ""
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var sets: String = ""
    @State private var notes: String = ""

    var onSave: (String, Double, Int, Int, String) -> Void
    var onCancel: () -> Void

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var categories: [String] {
        let all = Set(wgerExercises.compactMap(\.category).filter { !$0.isEmpty })
        return ["All"] + all.sorted()
    }

    private var filteredWger: [WgerExercise] {
        var list = wgerExercises
        if selectedCategory != "All" {
            list = list.filter { $0.displayCategory == selectedCategory }
        }
        let t = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if t.isEmpty { return list }
        return list.filter {
            $0.name.lowercased().contains(t)
            || ($0.category?.lowercased().contains(t) ?? false)
            || ($0.muscle?.lowercased().contains(t) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceL) {
                    switchExerciseSection
                    detailsSection
                    notesSection
                }
                .padding(ForgeTheme.gutter)
            }
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                name = log.name
                weight = log.weight > 0 ? "\(Int(log.weight))" : ""
                reps = log.reps > 0 ? "\(log.reps)" : ""
                sets = log.sets > 0 ? "\(log.sets)" : ""
                notes = log.notes
                guard wgerExercises.isEmpty else { return }
                isLoadingExercises = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let loaded = ExerciseLoader.loadFromBundle()
                    DispatchQueue.main.async {
                        wgerExercises = loaded
                        isLoadingExercises = false
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }

    private var categorySegments: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ForgeTheme.spaceS) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, ForgeTheme.spaceM)
                            .padding(.vertical, ForgeTheme.spaceS)
                            .background(selectedCategory == category ? Color.accentColor : Color(.tertiarySystemFill))
                            .foregroundStyle(selectedCategory == category ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, ForgeTheme.spaceXS)
        }
    }

    @ViewBuilder
    private var switchExerciseSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            Text("Switch exercise")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search by name or muscle", text: $searchText)
                .textFieldStyle(.plain)
                .padding(ForgeTheme.spaceM)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
                .autocorrectionDisabled()

            if isLoadingExercises {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
                    HStack(spacing: ForgeTheme.spaceS) {
                        ProgressView()
                            .tint(ForgeTheme.gold)
                        Text("Loading exercises…")
                            .font(.subheadline)
                            .foregroundStyle(ForgeTheme.secondaryText)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: ForgeTheme.spaceM),
                        GridItem(.flexible(), spacing: ForgeTheme.spaceM)
                    ], spacing: ForgeTheme.spaceM) {
                        ForEach(0..<6, id: \.self) { _ in
                            ForgeSkeletonCard()
                        }
                    }
                }
            } else if !wgerExercises.isEmpty {
                categorySegments
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: ForgeTheme.spaceM),
                    GridItem(.flexible(), spacing: ForgeTheme.spaceM)
                ], spacing: ForgeTheme.spaceM) {
                    ForEach(filteredWger.prefix(100)) { exercise in
                        WgerExerciseCard(
                            exercise: exercise,
                            isSelected: selectedWgerId == exercise.id || name == exercise.name
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedWgerId = exercise.id
                                selectedTemplate = nil
                                name = exercise.name
                            }
                        }
                    }
                }
                .frame(minHeight: 180)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ForgeTheme.spaceM) {
                        ForEach(ExerciseTemplates.popular) { template in
                            ExerciseTemplateCard(
                                template: template,
                                isSelected: selectedTemplate == template || name == template.name
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedTemplate = template
                                    selectedWgerId = nil
                                    name = template.name
                                }
                            }
                        }
                    }
                    .padding(.vertical, ForgeTheme.spaceXS)
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            Text("Details")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: ForgeTheme.spaceM) {
                TextField("Exercise name", text: $name)
                    .textInputAutocapitalization(.words)
                    .padding(ForgeTheme.spaceM)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))

                TextField("Weight (lb)", text: $weight)
                    .keyboardType(.decimalPad)
                    .padding(ForgeTheme.spaceM)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
                    .placeholder(when: weight.isEmpty) {
                        Text("e.g. 135").foregroundStyle(.tertiary).padding(.leading, ForgeTheme.spaceM)
                    }

                HStack(spacing: ForgeTheme.spaceM) {
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                        .padding(ForgeTheme.spaceM)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
                        .placeholder(when: reps.isEmpty) {
                            Text("10").foregroundStyle(.tertiary).padding(.leading, ForgeTheme.spaceM)
                        }
                    TextField("Sets", text: $sets)
                        .keyboardType(.numberPad)
                        .padding(ForgeTheme.spaceM)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
                        .placeholder(when: sets.isEmpty) {
                            Text("3").foregroundStyle(.tertiary).padding(.leading, ForgeTheme.spaceM)
                        }
                }
            }
            .padding(ForgeTheme.cardPadding)
            .forgeCard()
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
            Text("Notes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(ForgeTheme.spaceM)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))
        }
    }

    private func save() {
        let w = Double(weight) ?? 0
        let r = Int(reps) ?? 0
        let s = Int(sets) ?? 0
        onSave(
            name.trimmingCharacters(in: .whitespaces),
            w,
            r,
            s,
            notes.trimmingCharacters(in: .whitespaces)
        )
    }
}

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow { content() }
            self
        }
    }
}
