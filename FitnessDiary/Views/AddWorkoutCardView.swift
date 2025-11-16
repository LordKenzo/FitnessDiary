import SwiftUI
import SwiftData

struct AddWorkoutCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    let folders: [WorkoutFolder]
    let clients: [Client]

    @State private var name = ""
    @State private var description = ""
    @State private var selectedFolders: [WorkoutFolder] = []
    @State private var isAssignedToMe = true
    @State private var selectedClients: [Client] = []
    @State private var workoutBlocks: [WorkoutBlockData] = []
    @State private var showingExercisePicker = false
    @State private var showingMethodSelection = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni") {
                    TextField("Nome scheda", text: $name)
                    TextField("Descrizione (opzionale)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Organizzazione") {
                    NavigationLink {
                        FolderSelectionView(
                            selectedFolders: $selectedFolders,
                            folders: folders
                        )
                    } label: {
                        HStack {
                            Text("Folder")
                            Spacer()
                            if selectedFolders.isEmpty {
                                Text("Nessuno")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("(\(selectedFolders.count))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Toggle("Mia", isOn: $isAssignedToMe)

                    NavigationLink {
                        ClientSelectionView(
                            selectedClients: $selectedClients,
                            clients: clients
                        )
                    } label: {
                        HStack {
                            Text("Assegnata a clienti")
                            Spacer()
                            if selectedClients.isEmpty {
                                Text("Nessuno")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("(\(selectedClients.count))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    ForEach(workoutBlocks.indices, id: \.self) { index in
                        NavigationLink {
                            EditWorkoutBlockView(
                                blockData: $workoutBlocks[index]
                            )
                        } label: {
                            WorkoutBlockRow(
                                block: workoutBlockToModel(workoutBlocks[index]),
                                order: index + 1
                            )
                        }
                    }
                    .onMove(perform: moveBlock)
                    .onDelete(perform: deleteBlock)

                    Menu {
                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Esercizio Singolo", systemImage: "figure.strengthtraining.traditional")
                        }

                        Button {
                            showingMethodSelection = true
                        } label: {
                            Label("Con Metodo", systemImage: "bolt.horizontal.fill")
                        }
                    } label: {
                        Label("Aggiungi Blocco", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Blocchi (\(workoutBlocks.count))")
                        Spacer()
                        if !workoutBlocks.isEmpty {
                            EditButton()
                        }
                    }
                }
            }
            .navigationTitle("Nuova Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveCard()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(
                    exercises: exercises,
                    onSelect: { exercise in
                        addSimpleBlock(exercise)
                    }
                )
            }
            .sheet(isPresented: $showingMethodSelection) {
                MethodSelectionView { method in
                    addMethodBlock(method)
                }
            }
        }
    }

    private func addSimpleBlock(_ exercise: Exercise) {
        let exerciseItem = WorkoutExerciseItemData(
            exercise: exercise,
            order: 0,
            sets: [WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: nil)]
        )

        let newBlock = WorkoutBlockData(
            blockType: .simple,
            methodType: nil,
            order: workoutBlocks.count,
            globalSets: 3,
            globalRestTime: 90,
            notes: nil,
            exerciseItems: [exerciseItem]
        )
        workoutBlocks.append(newBlock)
    }

    private func addMethodBlock(_ method: MethodType) {
        let newBlock = WorkoutBlockData(
            blockType: .method,
            methodType: method,
            order: workoutBlocks.count,
            globalSets: 3,
            globalRestTime: 120,
            notes: nil,
            exerciseItems: []
        )
        workoutBlocks.append(newBlock)
    }

    private func moveBlock(from source: IndexSet, to destination: Int) {
        workoutBlocks.move(fromOffsets: source, toOffset: destination)
        for (index, _) in workoutBlocks.enumerated() {
            workoutBlocks[index].order = index
        }
    }

    private func deleteBlock(at offsets: IndexSet) {
        workoutBlocks.remove(atOffsets: offsets)
        for (index, _) in workoutBlocks.enumerated() {
            workoutBlocks[index].order = index
        }
    }

    // Helper to convert WorkoutBlockData to WorkoutBlock for preview
    private func workoutBlockToModel(_ blockData: WorkoutBlockData) -> WorkoutBlock {
        let block = WorkoutBlock(
            order: blockData.order,
            blockType: blockData.blockType,
            methodType: blockData.methodType,
            globalSets: blockData.globalSets,
            globalRestTime: blockData.globalRestTime,
            notes: blockData.notes,
            exerciseItems: []
        )

        for itemData in blockData.exerciseItems {
            let exerciseItem = WorkoutExerciseItem(
                order: itemData.order,
                exercise: itemData.exercise,
                notes: itemData.notes,
                restTime: itemData.restTime
            )

            for setData in itemData.sets {
                let workoutSet = WorkoutSet(
                    order: setData.order,
                    setType: setData.setType,
                    reps: setData.reps,
                    weight: setData.weight,
                    duration: setData.duration,
                    notes: setData.notes
                )
                exerciseItem.sets.append(workoutSet)
            }

            block.exerciseItems.append(exerciseItem)
        }

        return block
    }

    private func saveCard() {
        let newCard = WorkoutCard(
            name: name,
            description: description.isEmpty ? nil : description,
            folders: selectedFolders,
            isAssignedToMe: isAssignedToMe,
            assignedTo: selectedClients
        )

        // Crea i blocchi
        for blockData in workoutBlocks {
            let block = WorkoutBlock(
                order: blockData.order,
                blockType: blockData.blockType,
                methodType: blockData.methodType,
                globalSets: blockData.globalSets,
                globalRestTime: blockData.globalRestTime,
                notes: blockData.notes
            )

            // Crea gli esercizi del blocco
            for exerciseItemData in blockData.exerciseItems {
                let exerciseItem = WorkoutExerciseItem(
                    order: exerciseItemData.order,
                    exercise: exerciseItemData.exercise,
                    notes: exerciseItemData.notes,
                    restTime: exerciseItemData.restTime
                )

                // Crea le serie
                for setData in exerciseItemData.sets {
                    let workoutSet = WorkoutSet(
                        order: setData.order,
                        setType: setData.setType,
                        reps: setData.reps,
                        weight: setData.weight,
                        duration: setData.duration,
                        notes: setData.notes
                    )
                    exerciseItem.sets.append(workoutSet)
                }

                block.exerciseItems.append(exerciseItem)
            }

            newCard.blocks.append(block)
        }

        modelContext.insert(newCard)
        dismiss()
    }
}

// Row component for legacy exercise display (still used by EditWorkoutExerciseView)
struct WorkoutExerciseRow: View {
    let exerciseData: WorkoutExerciseData
    let order: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(order).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
                Text(exerciseData.exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                Label("\(exerciseData.sets.count) serie", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let restTime = exerciseData.restTime {
                    let minutes = Int(restTime) / 60
                    let seconds = Int(restTime) % 60
                    if minutes > 0 {
                        Label("\(minutes)m \(seconds)s", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("\(seconds)s", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 24)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AddWorkoutCardView(folders: [], clients: [])
        .modelContainer(for: [WorkoutCard.self, Exercise.self])
}
