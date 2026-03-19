//
//  TemplatesView.swift
//  RepTrack
//

import SwiftUI
import SwiftData
import os

struct TemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutTemplate.updatedAt, order: .reverse)])
    private var templates: [WorkoutTemplate]

    let onUseTemplate: (WorkoutTemplate) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: ForgeTheme.spaceL) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(ForgeTheme.gold.opacity(0.9))
            Text("No templates yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(ForgeTheme.primaryText)
            Text("Open any workout and use Save as Template to reuse your structure later.")
                .font(.body)
                .foregroundStyle(ForgeTheme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ForgeTheme.gutter)
    }

    private var templateList: some View {
        ScrollView {
            LazyVStack(spacing: ForgeTheme.spaceM) {
                ForEach(templates, id: \.persistentModelID) { template in
                    VStack(alignment: .leading, spacing: ForgeTheme.spaceS) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundStyle(ForgeTheme.primaryText)
                            Spacer(minLength: 0)
                            Text("\(template.sortedExercises.count) exercises")
                                .font(.caption)
                                .foregroundStyle(ForgeTheme.tertiaryText)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(template.sortedExercises.prefix(4), id: \.persistentModelID) { item in
                                Text("• \(item.name) · \(item.defaultSets)x\(item.defaultReps) @ \(Int(item.defaultWeight)) lb")
                                    .font(.caption)
                                    .foregroundStyle(ForgeTheme.secondaryText)
                            }
                            if template.sortedExercises.count > 4 {
                                Text("+ \(template.sortedExercises.count - 4) more")
                                    .font(.caption2)
                                    .foregroundStyle(ForgeTheme.tertiaryText)
                            }
                        }

                        HStack(spacing: ForgeTheme.spaceS) {
                            Button {
                                onUseTemplate(template)
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Start from Template")
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(ForgeTheme.gold)
                            .foregroundStyle(.black)

                            Spacer(minLength: 0)

                            Button(role: .destructive) {
                                deleteTemplate(template)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(ForgeTheme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .forgeCard()
                }
            }
            .padding(ForgeTheme.gutter)
            .padding(.bottom, ForgeTheme.gutter)
        }
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        do {
            try modelContext.save()
        } catch {
            AppLog.persistence.error("Delete template failed: \(String(describing: error))")
        }
    }
}

#Preview {
    TemplatesView(onUseTemplate: { _ in })
        .modelContainer(for: [WorkoutTemplate.self, WorkoutTemplateExercise.self], inMemory: true)
}
