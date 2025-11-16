import SwiftUI
import SwiftData

struct EditWorkoutBlockView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @Binding var blockData: WorkoutBlockData

    @State private var globalSets: Int
    @State private var globalRestMinutes: Int
    @State private var globalRestSeconds: Int
    @State private var notes: String
    @State private var showingExercisePicker = false

    init(blockData: Binding<WorkoutBlockData>) {
        self._blockData = blockData
        _globalSets = State(initialValue: blockData.wrappedValue.globalSets)
        let restTime = blockData.wrappedValue.globalRestTime ?? 60
        _globalRestMinutes = State(initialValue: Int(restTime) / 60)
        _globalRestSeconds = State(initialValue: Int(restTime) % 60)
        _notes = State(initialValue: blockData.wrappedValue.notes ?? "")
    }

    var body: some View {
        Form {
            // Block info section
            Section {
                HStack {
                    Image(systemName: blockData.blockType == .method && blockData.methodType != nil ? blockData.methodType!.icon : "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(blockData.blockType == .method && blockData.methodType != nil ? blockData.methodType!.color : .blue)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(blockData.blockType == .method && blockData.methodType != nil ? blockData.methodType!.rawValue : "Esercizio Singolo")
                            .font(.headline)
                        if blockData.blockType == .method, let method = blockData.methodType {
                            Text(method.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Global parameters section
            Section("Parametri Blocco") {
                Stepper("Serie: \(globalSets)", value: $globalSets, in: 1...20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recupero tra serie")
                        .font(.subheadline)

                    HStack(spacing: 16) {
                        Picker("Minuti", selection: $globalRestMinutes) {
                            ForEach(0..<10, id: \.self) { min in
                                Text("\(min)m").tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)

                        Picker("Secondi", selection: $globalRestSeconds) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { sec in
                                Text("\(sec)s").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                    }
                }

                TextField("Note (opzionale)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            // Exercises section
            Section {
                ForEach(blockData.exerciseItems.indices, id: \.self) { index in
                    NavigationLink {
                        EditWorkoutExerciseItemView(
                            exerciseItemData: $blockData.exerciseItems[index],
                            exercises: exercises,
                            isInMethod: blockData.blockType == .method
                        )
                    } label: {
                        WorkoutExerciseItemRow(
                            exerciseItemData: blockData.exerciseItems[index],
                            order: index + 1,
                            showSets: blockData.blockType == .simple
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
                .disabled(blockData.blockType == .simple && !blockData.exerciseItems.isEmpty)
            } header: {
                HStack {
                    Text("Esercizi (\(blockData.exerciseItems.count))")
                    if blockData.blockType == .method, let method = blockData.methodType {
                        Text("• min \(method.minExercises)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !blockData.exerciseItems.isEmpty {
                        EditButton()
                    }
                }
            } footer: {
                if blockData.blockType == .simple && !blockData.exerciseItems.isEmpty {
                    Text("Un blocco semplice può contenere solo un esercizio")
                        .font(.caption)
                } else if blockData.blockType == .method, let method = blockData.methodType {
                    Text("Questo metodo richiede almeno \(method.minExercises) esercizi")
                        .font(.caption)
                }
            }
        }
        .navigationTitle(blockData.blockType == .method ? "Modifica Metodo" : "Modifica Esercizio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fine") {
                    saveChanges()
                    dismiss()
                }
                .disabled(!isValid)
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

    private var isValid: Bool {
        if blockData.exerciseItems.isEmpty {
            return false
        }
        if blockData.blockType == .method, let method = blockData.methodType {
            return blockData.exerciseItems.count >= method.minExercises
        }
        return true
    }

    private func addExercise(_ exercise: Exercise) {
        let newExerciseItem = WorkoutExerciseItemData(
            exercise: exercise,
            order: blockData.exerciseItems.count,
            sets: [WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: nil)]
        )
        blockData.exerciseItems.append(newExerciseItem)
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        blockData.exerciseItems.move(fromOffsets: source, toOffset: destination)
        for (index, _) in blockData.exerciseItems.enumerated() {
            blockData.exerciseItems[index].order = index
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        blockData.exerciseItems.remove(atOffsets: offsets)
        for (index, _) in blockData.exerciseItems.enumerated() {
            blockData.exerciseItems[index].order = index
        }
    }

    private func saveChanges() {
        blockData.globalSets = globalSets
        blockData.globalRestTime = TimeInterval(globalRestMinutes * 60 + globalRestSeconds)
        blockData.notes = notes.isEmpty ? nil : notes
    }
}

// Row component for exercise items in blocks
struct WorkoutExerciseItemRow: View {
    let exerciseItemData: WorkoutExerciseItemData
    let order: Int
    let showSets: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(order).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
                Text(exerciseItemData.exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            if showSets {
                HStack(spacing: 12) {
                    Label("\(exerciseItemData.sets.count) serie", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let restTime = exerciseItemData.restTime {
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
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let exercise = Exercise(
        name: "Panca Piana",
        biomechanicalStructure: .multiJoint,
        trainingRole: .fundamental,
        primaryMetabolism: .anaerobic,
        category: .training
    )

    let exerciseItem = WorkoutExerciseItemData(
        exercise: exercise,
        order: 0,
        sets: [
            WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: 80),
            WorkoutSetData(order: 1, setType: .reps, reps: 8, weight: 85),
            WorkoutSetData(order: 2, setType: .reps, reps: 6, weight: 90)
        ]
    )

    @Previewable @State var blockData = WorkoutBlockData(
        blockType: .method,
        methodType: .superset,
        order: 0,
        globalSets: 4,
        globalRestTime: 120,
        notes: "Test superset",
        exerciseItems: [exerciseItem]
    )

    NavigationStack {
        EditWorkoutBlockView(blockData: $blockData)
    }
    .modelContainer(for: [Exercise.self])
}
