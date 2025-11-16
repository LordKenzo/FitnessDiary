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
    @State private var selectedFolder: WorkoutFolder?
    @State private var selectedClients: [Client] = []
    @State private var workoutExercises: [WorkoutExerciseData] = []
    @State private var showingExercisePicker = false
    @State private var showingClientSelection = false

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
        // Riordina gli esercizi
        for (index, _) in workoutExercises.enumerated() {
            workoutExercises[index].order = index
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        workoutExercises.remove(atOffsets: offsets)
        // Riordina gli esercizi
        for (index, _) in workoutExercises.enumerated() {
            workoutExercises[index].order = index
        }
    }

    private func saveCard() {
        let newCard = WorkoutCard(
            name: name,
            description: description.isEmpty ? nil : description,
            folder: selectedFolder,
            assignedTo: selectedClients
        )

        // Crea gli esercizi
        for exerciseData in workoutExercises {
            let workoutExercise = WorkoutExercise(
                order: exerciseData.order,
                exercise: exerciseData.exercise,
                notes: exerciseData.notes,
                restTime: exerciseData.restTime
            )

            // Crea le serie
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

            newCard.exercises.append(workoutExercise)
        }

        modelContext.insert(newCard)
        dismiss()
    }
}

// Struttura temporanea per gestire i dati prima del salvataggio
struct WorkoutExerciseData: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var order: Int
    var sets: [WorkoutSetData]
    var notes: String?
    var restTime: TimeInterval?
}

struct WorkoutSetData: Identifiable {
    let id = UUID()
    var order: Int
    var setType: SetType
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var notes: String?
}

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
