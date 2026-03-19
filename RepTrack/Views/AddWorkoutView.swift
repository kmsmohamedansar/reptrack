//
//  AddWorkoutView.swift
//  RepTrack
//

import SwiftUI

struct AddWorkoutView: View {
    @State private var selectedDate = Date()
    var onSave: (Date) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ForgeTheme.spaceL) {
                    Text("Workout date")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(ForgeTheme.cardPadding)
                    .forgeCard()
                }
                .padding(ForgeTheme.gutter)
            }
            .background(ForgeTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(selectedDate)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AddWorkoutView(onSave: { _ in }, onCancel: { })
}
