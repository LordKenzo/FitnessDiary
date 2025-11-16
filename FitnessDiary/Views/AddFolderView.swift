import SwiftUI
import SwiftData

struct AddFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutFolder.order) private var folders: [WorkoutFolder]

    @State private var name = ""
    @State private var selectedColor: Color = .blue

    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple,
        .pink, .cyan, .indigo, .mint, .teal
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni") {
                    TextField("Nome folder", text: $name)
                }

                Section("Colore") {
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
            .navigationTitle("Nuovo Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveFolder()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveFolder() {
        let newFolder = WorkoutFolder(
            name: name,
            colorHex: selectedColor.toHex() ?? "#007AFF",
            order: folders.count
        )
        modelContext.insert(newFolder)
        dismiss()
    }
}

#Preview {
    AddFolderView()
        .modelContainer(for: WorkoutFolder.self)
}
