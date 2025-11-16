import SwiftUI
import SwiftData

struct EditWorkoutCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @Bindable var card: WorkoutCard
    let folders: [WorkoutFolder]
    let clients: [Client]

    @State private var name: String
    @State private var description: String
    @State private var selectedFolders: [WorkoutFolder]
    @State private var isAssignedToMe: Bool
    @State private var selectedClients: [Client]
    @State private var workoutBlocks: [WorkoutBlockData] = []
    @State private var showingExercisePicker = false
    @State private var showingMethodSelection = false

    init(card: WorkoutCard, folders: [WorkoutFolder], clients: [Client]) {
        self.card = card
        self.folders = folders
        self.clients = clients
        _name = State(initialValue: card.name)
        _description = State(initialValue: card.cardDescription ?? "")
        _selectedFolders = State(initialValue: card.folders)
        _isAssignedToMe = State(initialValue: card.isAssignedToMe)
        _selectedClients = State(initialValue: card.assignedTo)

        // Converti i blocchi esistenti in WorkoutBlockData
        _workoutBlocks = State(initialValue: card.blocks.sorted(by: { $0.order < $1.order }).map { block in
            WorkoutBlockData(
                blockType: block.blockType,
                methodType: block.methodType,
                order: block.order,
                globalSets: block.globalSets,
                globalRestTime: block.globalRestTime,
                notes: block.notes,
                tabataWorkDuration: block.tabataWorkDuration,
                tabataRestDuration: block.tabataRestDuration,
                tabataRounds: block.tabataRounds,
                tabataRecoveryBetweenRounds: block.tabataRecoveryBetweenRounds,
                exerciseItems: block.exerciseItems.sorted(by: { $0.order < $1.order }).map { exerciseItem in
                    WorkoutExerciseItemData(
                        exercise: exerciseItem.exercise ?? Exercise(
                            name: "Esercizio Eliminato",
                            biomechanicalStructure: .multiJoint,
                            trainingRole: .base,
                            primaryMetabolism: .mixed,
                            category: .training
                        ),
                        order: exerciseItem.order,
                        sets: exerciseItem.sets.sorted(by: { $0.order < $1.order }).map { set in
                            WorkoutSetData(
                                order: set.order,
                                setType: set.setType,
                                reps: set.reps,
                                weight: set.weight,
                                duration: set.duration,
                                notes: set.notes,
                                loadType: set.loadType ?? .absolute,
                                percentageOfMax: set.percentageOfMax,
                                clusterSize: set.clusterSize,
                                clusterRestTime: set.clusterRestTime,
                                clusterProgression: set.clusterProgression,
                                clusterMinPercentage: set.clusterMinPercentage,
                                clusterMaxPercentage: set.clusterMaxPercentage,
                                restPauseCount: set.restPauseCount,
                                restPauseDuration: set.restPauseDuration
                            )
                        },
                        notes: exerciseItem.notes,
                        restTime: exerciseItem.restTime,
                        targetExpression: exerciseItem.targetExpression
                    )
                }
            )
        })
    }

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

                Section {
                    Button(role: .destructive) {
                        deleteCard()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Elimina Scheda", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Modifica Scheda")
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
        WorkoutBlockHelper.addSimpleBlock(to: &workoutBlocks, exercise: exercise)
    }

    private func addMethodBlock(_ method: MethodType) {
        WorkoutBlockHelper.addMethodBlock(to: &workoutBlocks, method: method)
    }

    private func moveBlock(from source: IndexSet, to destination: Int) {
        WorkoutBlockHelper.moveBlock(in: &workoutBlocks, from: source, to: destination)
    }

    private func deleteBlock(at offsets: IndexSet) {
        WorkoutBlockHelper.deleteBlock(in: &workoutBlocks, at: offsets)
    }

    // Helper to convert WorkoutBlockData to WorkoutBlock for preview
    private func workoutBlockToModel(_ blockData: WorkoutBlockData) -> WorkoutBlock {
        return WorkoutBlockHelper.workoutBlockToModel(blockData)
    }

    private func saveChanges() {
        card.name = name
        card.cardDescription = description.isEmpty ? nil : description
        card.folders = selectedFolders
        card.isAssignedToMe = isAssignedToMe
        card.assignedTo = selectedClients

        // Elimina esplicitamente tutti i blocchi esistenti dal database
        // (anche se @Relationship(deleteRule: .cascade) dovrebbe gestirlo automaticamente)
        for block in card.blocks {
            modelContext.delete(block)
        }
        card.blocks.removeAll()

        // Ricrea i blocchi dalla lista modificata
        for blockData in workoutBlocks {
            let block = WorkoutBlock(
                order: blockData.order,
                blockType: blockData.blockType,
                methodType: blockData.methodType,
                globalSets: blockData.globalSets,
                globalRestTime: blockData.globalRestTime,
                notes: blockData.notes,
                tabataWorkDuration: blockData.tabataWorkDuration,
                tabataRestDuration: blockData.tabataRestDuration,
                tabataRounds: blockData.tabataRounds,
                tabataRecoveryBetweenRounds: blockData.tabataRecoveryBetweenRounds
            )

            // Crea gli esercizi del blocco
            for exerciseItemData in blockData.exerciseItems {
                let exerciseItem = WorkoutExerciseItem(
                    order: exerciseItemData.order,
                    exercise: exerciseItemData.exercise,
                    notes: exerciseItemData.notes,
                    restTime: exerciseItemData.restTime,
                    targetExpression: exerciseItemData.targetExpression
                )

                // Crea le serie
                for setData in exerciseItemData.sets {
                    let workoutSet = WorkoutSet(
                        order: setData.order,
                        setType: setData.setType,
                        reps: setData.reps,
                        weight: setData.weight,
                        duration: setData.duration,
                        notes: setData.notes,
                        loadType: setData.loadType,
                        percentageOfMax: setData.percentageOfMax,
                        clusterSize: setData.clusterSize,
                        clusterRestTime: setData.clusterRestTime,
                        clusterProgression: setData.clusterProgression,
                        clusterMinPercentage: setData.clusterMinPercentage,
                        clusterMaxPercentage: setData.clusterMaxPercentage,
                        restPauseCount: setData.restPauseCount,
                        restPauseDuration: setData.restPauseDuration
                    )
                    exerciseItem.sets.append(workoutSet)
                }

                block.exerciseItems.append(exerciseItem)
            }

            card.blocks.append(block)
        }

        dismiss()
    }

    private func deleteCard() {
        modelContext.delete(card)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutCard.self, Exercise.self, configurations: config)

    let exercise = Exercise(
        name: "Panca Piana",
        biomechanicalStructure: .multiJoint,
        trainingRole: .fundamental,
        primaryMetabolism: .anaerobic,
        category: .training
    )

    let card = WorkoutCard(name: "Forza A")
    container.mainContext.insert(card)
    container.mainContext.insert(exercise)

    return EditWorkoutCardView(card: card, folders: [], clients: [])
        .modelContainer(container)
}
