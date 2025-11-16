import SwiftUI
import SwiftData

struct EditWorkoutExerciseItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Binding var exerciseItemData: WorkoutExerciseItemData
    let exercises: [Exercise]
    let isInMethod: Bool // se true, nasconde il tempo di recupero (gestito dal blocco)
    var methodValidation: LoadProgressionValidation? // validazione da applicare se in un metodo

    @State private var notes: String
    @State private var restMinutes: Int
    @State private var restSeconds: Int
    @State private var showingExercisePicker = false

    private var oneRepMax: Double? {
        guard let profile = profiles.first,
              let big5 = exerciseItemData.exercise.big5Exercise else {
            return nil
        }
        return profile.getOneRepMax(for: big5)
    }

    private var validationError: String? {
        guard let validation = methodValidation else { return nil }
        return exerciseItemData.validateLoadProgression(for: validation)
    }

    init(exerciseItemData: Binding<WorkoutExerciseItemData>, exercises: [Exercise], isInMethod: Bool = false, methodValidation: LoadProgressionValidation? = nil) {
        self._exerciseItemData = exerciseItemData
        self.exercises = exercises
        self.isInMethod = isInMethod
        self.methodValidation = methodValidation
        _notes = State(initialValue: exerciseItemData.wrappedValue.notes ?? "")

        let restTime = exerciseItemData.wrappedValue.restTime ?? 60
        _restMinutes = State(initialValue: Int(restTime) / 60)
        _restSeconds = State(initialValue: Int(restTime) % 60)
    }

    var body: some View {
        Form {
            Section("Esercizio") {
                Button {
                    showingExercisePicker = true
                } label: {
                    HStack {
                        Text("Esercizio")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(exerciseItemData.exercise.name)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if !isInMethod {
                Section("Tempo di Recupero") {
                    HStack {
                        Picker("Minuti", selection: $restMinutes) {
                            ForEach(0..<10, id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .pickerStyle(.wheel)

                        Picker("Secondi", selection: $restSeconds) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { sec in
                                Text("\(sec) sec").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 120)
                }
            }

            Section("Note") {
                TextField("Note (opzionale)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            // Warning di validazione
            if let error = validationError {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                ForEach($exerciseItemData.sets) { $set in
                    SetRow(set: $set, exercise: exerciseItemData.exercise, oneRepMax: oneRepMax)
                }
                // Permetti modifica ordine e cancellazione solo se NON in un metodo
                .onMove(perform: isInMethod ? nil : moveSets)
                .onDelete(perform: isInMethod ? nil : deleteSets)

                // Mostra pulsante aggiungi solo se NON in un metodo
                if !isInMethod {
                    Button {
                        addSet()
                    } label: {
                        Label("Aggiungi Serie", systemImage: "plus.circle.fill")
                    }
                }
            } header: {
                HStack {
                    Text(isInMethod ? "Ripetizioni per Serie" : "Serie")
                    Spacer()
                    // EditButton solo se NON in un metodo
                    if !isInMethod {
                        EditButton()
                    }
                }
            } footer: {
                if isInMethod {
                    Text("Il numero di serie è gestito dal blocco metodologia")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Configura Esercizio")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(exercises: exercises) { exercise in
                exerciseItemData.exercise = exercise
            }
        }
        .toolbar(content: toolbarContent)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Fatto") {
                saveChanges()
            }
        }
    }

    private func saveChanges() {
        exerciseItemData.notes = notes.isEmpty ? nil : notes
        if !isInMethod {
            exerciseItemData.restTime = TimeInterval(restMinutes * 60 + restSeconds)
        }
        dismiss()
    }

    private func addSet() {
        let newSet = WorkoutSetData(
            order: exerciseItemData.sets.count,
            setType: .reps,
            reps: 10,
            weight: nil,
            loadType: .absolute,
            percentageOfMax: nil
        )
        exerciseItemData.sets.append(newSet)
    }

    private func moveSets(from source: IndexSet, to destination: Int) {
        exerciseItemData.sets.move(fromOffsets: source, toOffset: destination)
        for (index, _) in exerciseItemData.sets.enumerated() {
            exerciseItemData.sets[index].order = index
        }
    }

    private func deleteSets(at offsets: IndexSet) {
        exerciseItemData.sets.remove(atOffsets: offsets)
        for (index, _) in exerciseItemData.sets.enumerated() {
            exerciseItemData.sets[index].order = index
        }
    }
}

#Preview {
    let exerciseItemData = WorkoutExerciseItemData(
        exercise: Exercise(
            name: "Panca Piana",
            biomechanicalStructure: .multiJoint,
            trainingRole: .fundamental,
            primaryMetabolism: .anaerobic,
            category: .training
        ),
        order: 0,
        sets: [
            WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: 60, loadType: .absolute, percentageOfMax: nil),
            WorkoutSetData(order: 1, setType: .reps, reps: 8, weight: 70, loadType: .absolute, percentageOfMax: nil)
        ]
    )

    return NavigationStack {
        EditWorkoutExerciseItemView(
            exerciseItemData: .constant(exerciseItemData),
            exercises: [],
            isInMethod: true
        )
    }
}
