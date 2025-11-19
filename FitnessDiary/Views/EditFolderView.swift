import SwiftUI
import SwiftData

struct EditFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var folder: WorkoutFolder

    @State private var name: String
    @State private var selectedColor: Color

    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple,
        .pink, .cyan, .indigo, .mint, .teal
    ]

    init(folder: WorkoutFolder) {
        self.folder = folder
        _name = State(initialValue: folder.name)
        _selectedColor = State(initialValue: folder.color)
    }

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

                Section {
                    Button(role: .destructive) {
                        deleteFolder()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Elimina Folder", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Modifica Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .appScreenBackground()
    }

    private func saveChanges() {
        folder.name = name
        folder.colorHex = selectedColor.toHex() ?? "#007AFF"
        dismiss()
    }

    private func deleteFolder() {
        // Le schede nel folder non vengono eliminate, solo il folder
        modelContext.delete(folder)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutFolder.self, configurations: config)
    let folder = WorkoutFolder(name: "Forza", colorHex: "#FF0000")
    container.mainContext.insert(folder)

    return EditFolderView(folder: folder)
        .modelContainer(container)
}
