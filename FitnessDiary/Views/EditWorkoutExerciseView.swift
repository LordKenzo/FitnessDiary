import SwiftUI
import SwiftData

struct EditWorkoutExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var exerciseData: WorkoutExerciseItemData
    let exercises: [Exercise]
    @AppStorage("cloneLoadEnabled") private var cloneLoadEnabled = true

    @State private var notes: String
    @State private var restMinutes: Int
    @State private var restSeconds: Int
    @State private var showingExercisePicker = false
    @State private var userProfile: UserProfile?

    private var oneRepMax: Double? {
        guard let profile = userProfile,
              let big5 = exerciseData.exercise.big5Exercise else {
            return nil
        }
        return profile.getOneRepMax(for: big5)
    }

    init(exerciseData: Binding<WorkoutExerciseItemData>, exercises: [Exercise]) {
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
                    SetRow(
                        set: $set,
                        exercise: exerciseData.exercise,
                        oneRepMax: oneRepMax
                    )
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
                    TitleCaseEditButton()
                }
            }
        }
        .navigationTitle("Configura Esercizio")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(exercises: exercises) { exercise in
                exerciseData.exercise = exercise
            }
        }
        .toolbar(content: toolbarContent)
        .onAppear {
            loadUserProfile()
        }
    }

    private func loadUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        userProfile = try? modelContext.fetch(descriptor).first
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Conferma") {
                saveChanges()
            }
        }
    }

    private func saveChanges() {
        applyCloneLoadIfNeeded()
        exerciseData.notes = notes.isEmpty ? nil : notes
        exerciseData.restTime = TimeInterval(restMinutes * 60 + restSeconds)
        dismiss()
    }

    private func applyCloneLoadIfNeeded() {
        guard cloneLoadEnabled else { return }
        for set in exerciseData.sets where set.weight != nil || set.percentageOfMax != nil {
            exerciseData.sets.cloneLoadIfNeeded(from: set)
        }
    }

    private func addSet() {
        let newSet = WorkoutSetData(
            order: exerciseData.sets.count,
            setType: .reps,
            reps: 10,
            weight: nil,
            loadType: .absolute,
            percentageOfMax: nil
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
    let exercise: Exercise?
    let oneRepMax: Double?
    var isClusterSet: Bool = false
    var isRestPauseSet: Bool = false
    var setTypeSupport: SetTypeSupport = .repsOnly
    var targetParameters: StrengthExpressionParameters? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Header con numero serie e tipo
            HStack(spacing: 16) {
                Text("Serie \(set.order + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Text(set.setType.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Campi principali in base al tipo di serie
            if set.setType == .reps {
                RepsAndLoadFields(
                    set: $set,
                    oneRepMax: oneRepMax,
                    targetParameters: targetParameters
                )

                // Campi Cluster Set
                if isClusterSet {
                    Divider()
                    ClusterFields(set: $set)
                }

                // Campi Rest-Pause
                if isRestPauseSet {
                    Divider()
                    RestPauseFields(set: $set)
                }
            } else {
                DurationFields(set: $set)
            }
        }
    }
}

#Preview {
    let exerciseData = WorkoutExerciseItemData(
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
        EditWorkoutExerciseView(
            exerciseData: .constant(exerciseData),
            exercises: []
        )
    }
}
