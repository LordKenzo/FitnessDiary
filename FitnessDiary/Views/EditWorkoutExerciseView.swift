import SwiftUI
import SwiftData

struct EditWorkoutExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exerciseData: WorkoutExerciseData
    let exercises: [Exercise]

    @State private var notes: String
    @State private var restMinutes: Int
    @State private var restSeconds: Int
    @State private var showingExercisePicker = false

    init(exerciseData: Binding<WorkoutExerciseData>, exercises: [Exercise]) {
        self._exerciseData = exerciseData
        self.exercises = exercises
        _notes = State(initialValue: exerciseData.wrappedValue.notes ?? "")

        let restTime = exerciseData.wrappedValue.restTime ?? 60
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
                        Text(exerciseData.exercise.name)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section("Tempo di Recupero") {
                HStack {
                    Picker("Minuti", selection: $restMinutes) {
                        ForEach(0..<10) { min in
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

            Section("Note") {
                TextField("Note (opzionale)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                ForEach($exerciseData.sets) { $set in
                    SetRow(set: $set)
                }
                .onMove(perform: moveSets)
                .onDelete(perform: deleteSets)

                Button {
                    addSet()
                } label: {
                    Label("Aggiungi Serie", systemImage: "plus.circle.fill")
                }
            } header: {
                HStack {
                    Text("Serie")
                    Spacer()
                    EditButton()
                }
            }
        }
        .navigationTitle("Configura Esercizio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fatto") {
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(exercises: exercises) { exercise in
                exerciseData.exercise = exercise
            }
        }
    }

    private func saveChanges() {
        exerciseData.notes = notes.isEmpty ? nil : notes
        exerciseData.restTime = TimeInterval(restMinutes * 60 + restSeconds)
        dismiss()
    }

    private func addSet() {
        let newSet = WorkoutSetData(
            order: exerciseData.sets.count,
            setType: .reps,
            reps: 10,
            weight: nil
        )
        exerciseData.sets.append(newSet)
    }

    private func moveSets(from source: IndexSet, to destination: Int) {
        exerciseData.sets.move(fromOffsets: source, toOffset: destination)
        for (index, _) in exerciseData.sets.enumerated() {
            exerciseData.sets[index].order = index
        }
    }

    private func deleteSets(at offsets: IndexSet) {
        exerciseData.sets.remove(atOffsets: offsets)
        for (index, _) in exerciseData.sets.enumerated() {
            exerciseData.sets[index].order = index
        }
    }
}

struct SetRow: View {
    @Binding var set: WorkoutSetData

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Text("Serie \(set.order + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Picker("Tipo", selection: $set.setType) {
                    ForEach([SetType.reps, SetType.duration], id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            if set.setType == .reps {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)

                    HStack(spacing: 4) {
                        TextField("Rip", value: $set.reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                        Text("rip")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        TextField("Kg", value: $set.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)

                    HStack(spacing: 4) {
                        TextField("Minuti", value: Binding(
                            get: {
                                if let duration = set.duration {
                                    return Int(duration) / 60
                                }
                                return 0
                            },
                            set: { newMinutes in
                                let seconds = set.duration.map { Int($0) % 60 } ?? 0
                                set.duration = TimeInterval(newMinutes * 60 + seconds)
                            }
                        ), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                        Text("min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        TextField("Secondi", value: Binding(
                            get: {
                                if let duration = set.duration {
                                    return Int(duration) % 60
                                }
                                return 0
                            },
                            set: { newSeconds in
                                let minutes = set.duration.map { Int($0) / 60 } ?? 0
                                set.duration = TimeInterval(minutes * 60 + newSeconds)
                            }
                        ), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                        Text("sec")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    let exerciseData = WorkoutExerciseData(
        exercise: Exercise(
            name: "Panca Piana",
            biomechanicalStructure: .multiJoint,
            trainingRole: .fundamental,
            primaryMetabolism: .anaerobic,
            category: .training
        ),
        order: 0,
        sets: [
            WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: 60),
            WorkoutSetData(order: 1, setType: .reps, reps: 8, weight: 70)
        ]
    )

    return NavigationStack {
        EditWorkoutExerciseView(
            exerciseData: .constant(exerciseData),
            exercises: []
        )
    }
}
