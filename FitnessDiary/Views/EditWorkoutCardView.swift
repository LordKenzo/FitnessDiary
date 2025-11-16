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
    @State private var selectedFolder: WorkoutFolder?
    @State private var selectedClients: [Client]
    @State private var workoutExercises: [WorkoutExerciseData] = []
    @State private var showingExercisePicker = false

    init(card: WorkoutCard, folders: [WorkoutFolder], clients: [Client]) {
        self.card = card
        self.folders = folders
        self.clients = clients
        _name = State(initialValue: card.name)
        _description = State(initialValue: card.cardDescription ?? "")
        _selectedFolder = State(initialValue: card.folder)
        _selectedClients = State(initialValue: card.assignedTo)

        // Converti gli esercizi esistenti in WorkoutExerciseData
        _workoutExercises = State(initialValue: card.exercises.sorted(by: { $0.order < $1.order }).map { workoutExercise in
            WorkoutExerciseData(
                exercise: workoutExercise.exercise ?? Exercise(
                    name: "Esercizio Eliminato",
                    biomechanicalStructure: .multiJoint,
                    trainingRole: .base,
                    primaryMetabolism: .mixed,
                    category: .training
                ),
                order: workoutExercise.order,
                sets: workoutExercise.sets.sorted(by: { $0.order < $1.order }).map { set in
                    WorkoutSetData(
                        order: set.order,
                        setType: set.setType,
                        reps: set.reps,
                        weight: set.weight,
                        duration: set.duration,
                        notes: set.notes
                    )
                },
                notes: workoutExercise.notes,
                restTime: workoutExercise.restTime
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
                    Picker("Folder", selection: $selectedFolder) {
                        Text("Nessuno").tag(nil as WorkoutFolder?)
                        ForEach(folders) { folder in
                            HStack {
                                Circle()
                                    .fill(folder.color)
                                    .frame(width: 10, height: 10)
                                Text(folder.name)
                            }
                            .tag(folder as WorkoutFolder?)
                        }
                    }

                    NavigationLink {
                        ClientSelectionView(
                            selectedClients: $selectedClients,
                            clients: clients
                        )
                    } label: {
                        HStack {
                            Text("Assegnata a")
                            Spacer()
                            if selectedClients.isEmpty {
                                Text("Mio")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("(\(selectedClients.count))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    ForEach(workoutExercises.indices, id: \.self) { index in
                        NavigationLink {
                            EditWorkoutExerciseView(
                                exerciseData: $workoutExercises[index],
                                exercises: exercises
                            )
                        } label: {
                            WorkoutExerciseRow(
                                exerciseData: workoutExercises[index],
                                order: index + 1
                            )
                        }
                    }
                    .onMove(perform: moveExercise)
                    .onDelete(perform: deleteExercise)

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Aggiungi Esercizio", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Esercizi")
                        Spacer()
                        if !workoutExercises.isEmpty {
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
                        addExercise(exercise)
                    }
                )
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let newExercise = WorkoutExerciseData(
            exercise: exercise,
            order: workoutExercises.count,
            sets: [WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: nil)]
        )
        workoutExercises.append(newExercise)
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        workoutExercises.move(fromOffsets: source, toOffset: destination)
        for (index, _) in workoutExercises.enumerated() {
            workoutExercises[index].order = index
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        workoutExercises.remove(atOffsets: offsets)
        for (index, _) in workoutExercises.enumerated() {
            workoutExercises[index].order = index
        }
    }

    private func saveChanges() {
        card.name = name
        card.cardDescription = description.isEmpty ? nil : description
        card.folder = selectedFolder
        card.assignedTo = selectedClients

        // Rimuovi tutti gli esercizi esistenti
        card.exercises.removeAll()

        // Ricrea gli esercizi dalla lista modificata
        for exerciseData in workoutExercises {
            let workoutExercise = WorkoutExercise(
                order: exerciseData.order,
                exercise: exerciseData.exercise,
                notes: exerciseData.notes,
                restTime: exerciseData.restTime
            )

            for setData in exerciseData.sets {
                let workoutSet = WorkoutSet(
                    order: setData.order,
                    setType: setData.setType,
                    reps: setData.reps,
                    weight: setData.weight,
                    duration: setData.duration,
                    notes: setData.notes
                )
                workoutExercise.sets.append(workoutSet)
            }

            card.exercises.append(workoutExercise)
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
