import SwiftUI

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolders: [WorkoutFolder]
    let folders: [WorkoutFolder]

    @State private var localSelection: Set<UUID>

    init(selectedFolders: Binding<[WorkoutFolder]>, folders: [WorkoutFolder]) {
        self._selectedFolders = selectedFolders
        self.folders = folders
        _localSelection = State(initialValue: Set(selectedFolders.wrappedValue.map { $0.id }))
    }

    var body: some View {
        List {
            ForEach(folders.sorted(by: { $0.order < $1.order })) { folder in
                Button {
                    if localSelection.contains(folder.id) {
                        localSelection.remove(folder.id)
                    } else {
                        localSelection.insert(folder.id)
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(folder.color)
                            .frame(width: 12, height: 12)

                        Text(folder.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        if localSelection.contains(folder.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            if !localSelection.isEmpty {
                Section {
                    Button {
                        localSelection.removeAll()
                    } label: {
                        HStack {
                            Spacer()
                            Text(L("folders.deselect.all"))
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(L("folders.select"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L("common.done")) {
                    // Aggiorna selectedFolders con la selezione
                    selectedFolders = folders.filter { localSelection.contains($0.id) }
                    dismiss()
                }
            }
        }
        .appScreenBackground()
    }
}

#Preview {
    let folder1 = WorkoutFolder(name: "Forza", colorHex: "#FF0000", order: 0)
    let folder2 = WorkoutFolder(name: "Ipertrofia", colorHex: "#00FF00", order: 1)
    let folder3 = WorkoutFolder(name: "Condizionamento", colorHex: "#0000FF", order: 2)

    return NavigationStack {
        FolderSelectionView(
            selectedFolders: .constant([folder1]),
            folders: [folder1, folder2, folder3]
        )
    }
}
