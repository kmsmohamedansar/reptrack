//
//  ContentView.swift
//  RepTrack
//
//  Created by ANSAR on 2026-03-13.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.largeTitle)
                        .bold()
                    Text("Track your reps and progress here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                if items.isEmpty {
                    VStack(spacing: 12) {
                        Spacer(minLength: 60)
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No reps yet")
                            .font(.title3)
                            .bold()
                        Text("Tap '+' to add your first rep.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading) {
                                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                                            .font(.headline)
                                        Text("Tap for details")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemGroupedBackground))
        } detail: {
            Text("Select an item")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("RepTrack")
                    .font(.headline)
                    .bold()
            }
            ToolbarItem {
                Button {
                    addItem()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Item")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
