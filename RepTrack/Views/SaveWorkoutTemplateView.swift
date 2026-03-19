//
//  SaveWorkoutTemplateView.swift
//  RepTrack
//

import SwiftUI

struct SaveWorkoutTemplateView: View {
    @State private var templateName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    init(defaultName: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _templateName = State(initialValue: defaultName)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var canSave: Bool {
        !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceL) {
                    Text("Template name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("Push Day", text: $templateName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(ForgeTheme.spaceM)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous))

                    Text("This saves the current exercise order and default sets/reps/weight for quick reuse.")
                        .font(.caption)
                        .foregroundStyle(ForgeTheme.tertiaryText)
                }
                .padding(ForgeTheme.gutter)
            }
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(templateName)
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    SaveWorkoutTemplateView(defaultName: "Upper Body") { _ in } onCancel: {}
}
