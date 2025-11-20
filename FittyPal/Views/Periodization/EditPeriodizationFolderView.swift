//
//  EditPeriodizationFolderView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

struct EditPeriodizationFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let folder: PeriodizationFolder

    @State private var name = ""
    @State private var selectedColor: Color = .blue

    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple,
        .pink, .cyan, .indigo, .mint, .teal
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(L("folders.section.info")) {
                    TextField(L("folders.name"), text: $name)
                }

                Section(L("folders.section.color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(availableColors, id: \.description) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: selectedColor.description == color.description ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .glassScrollBackground()
            .navigationTitle(L("folders.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.save")) {
                        saveFolder()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .appScreenBackground()
        .onAppear {
            name = folder.name
            selectedColor = folder.color
        }
    }

    private func saveFolder() {
        folder.name = name
        folder.colorHex = selectedColor.toHex() ?? "#007AFF"
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: PeriodizationFolder.self, configurations: config) else {
        return Text("Failed to create preview container")
    }

    let folder = PeriodizationFolder(name: "Strength", colorHex: "#FF0000")
    container.mainContext.insert(folder)

    return EditPeriodizationFolderView(folder: folder)
        .modelContainer(container)
}
