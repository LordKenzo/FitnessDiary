import SwiftUI
import SwiftData

struct AddWorkoutCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false

    let folders: [WorkoutFolder]
    let clients: [Client]

    @State private var name = ""
    @State private var description = ""
    @State private var targetExpression: StrengthExpressionType? = nil
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

                Section("Obiettivo della scheda") {
                    Picker("Focus", selection: $targetExpression) {
                        Text("Nessuno").tag(nil as StrengthExpressionType?)
                        ForEach(StrengthExpressionType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type as StrengthExpressionType?)
                        }
                    }
                    
                    // Footer simulato
                    Text("Il target definisce i range consigliati per carichi, ripetizioni e recuperi su tutta la scheda.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
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
                                blockData: $workoutBlocks[index],
                                cardTargetExpression: targetExpression
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

                        Button {
                            addRestBlock()
                        } label: {
                            Label("Riposo", systemImage: "moon.zzz.fill")
                        }
                    } label: {
                        Label("Aggiungi Blocco", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Blocchi (\(workoutBlocks.count))")
                        Spacer()
                        if !workoutBlocks.isEmpty {
                            TitleCaseEditButton()
                        }
                    }
                }

                if debugWorkoutLogEnabled && !workoutBlocks.isEmpty {
                    Section("Debug") {
                        NavigationLink {
                            WorkoutDebugLogView(blockData: workoutBlocks)
                        } label: {
                            Label("Anteprima sequenza esercizi", systemImage: "list.bullet.rectangle")
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
        WorkoutBlockHelper.addSimpleBlock(to: &workoutBlocks, exercise: exercise)
    }

    private func addMethodBlock(_ method: MethodType) {
        WorkoutBlockHelper.addMethodBlock(to: &workoutBlocks, method: method)
    }

    private func addRestBlock() {
        WorkoutBlockHelper.addRestBlock(to: &workoutBlocks)
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

    private func saveCard() {
        let newCard = WorkoutCard(
            name: name,
            description: description.isEmpty ? nil : description,
            targetExpression: targetExpression,
            folders: selectedFolders,
            isAssignedToMe: isAssignedToMe,
            assignedTo: selectedClients
        )

        // Crea i blocchi usando WorkoutBlockHelper
        // Questo elimina la duplicazione di codice e centralizza la logica di conversione
        for blockData in workoutBlocks {
            let block = WorkoutBlockHelper.workoutBlockToModel(blockData)
            newCard.blocks.append(block)
        }

        modelContext.insert(newCard)
        dismiss()
    }
}

// Row component for exercise display
struct WorkoutExerciseRow: View {
    let exerciseData: WorkoutExerciseItemData
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
