//
//  AddPeriodizationFolderView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

struct AddPeriodizationFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PeriodizationFolder.order) private var folders: [PeriodizationFolder]

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
            .navigationTitle(L("folders.create"))
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
    }

    private func saveFolder() {
        let newFolder = PeriodizationFolder(
            name: name,
            colorHex: selectedColor.toHex() ?? "#007AFF",
            order: folders.count
        )
        modelContext.insert(newFolder)
        dismiss()
    }
}

#Preview {
    AddPeriodizationFolderView()
        .modelContainer(for: PeriodizationFolder.self)
}
