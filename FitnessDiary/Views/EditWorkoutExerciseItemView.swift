import SwiftUI
import SwiftData

struct EditWorkoutExerciseItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var strengthParameters: [StrengthExpressionParameters]
    @Binding var exerciseItemData: WorkoutExerciseItemData
    let exercises: [Exercise]
    let isInMethod: Bool // se true, nasconde il tempo di recupero (gestito dal blocco)
    var methodValidation: LoadProgressionValidation? // validazione da applicare se in un metodo
    var methodType: MethodType? // tipo di metodo (per gestire cluster set)
    let cardTargetExpression: StrengthExpressionType?

    @State private var notes: String
    @State private var restMinutes: Int
    @State private var restSeconds: Int
    @State private var showingExercisePicker = false
    @State private var userProfile: UserProfile?
    @AppStorage("cloneLoadEnabled") private var cloneLoadEnabled = true

    private var oneRepMax: Double? {
        guard let profile = userProfile,
              let big5 = exerciseItemData.exercise.big5Exercise else {
            return nil
        }
        return profile.getOneRepMax(for: big5)
    }

    private var targetParameters: StrengthExpressionParameters? {
        guard let targetType = cardTargetExpression else { return nil }
        return strengthParameters.first(where: { $0.type == targetType })
    }

    private var currentRestTime: TimeInterval {
        TimeInterval(restMinutes * 60 + restSeconds)
    }

    private var isRestTimeOutOfRange: Bool {
        guard let params = targetParameters else { return false }
        return !params.isRestTimeInRange(currentRestTime)
    }

    private var validationError: String? {
        guard let validation = methodValidation else { return nil }
        return exerciseItemData.validateLoadProgression(for: validation)
    }

    init(exerciseItemData: Binding<WorkoutExerciseItemData>, exercises: [Exercise], isInMethod: Bool = false, methodValidation: LoadProgressionValidation? = nil, methodType: MethodType? = nil, cardTargetExpression: StrengthExpressionType? = nil) {
        self._exerciseItemData = exerciseItemData
        self.exercises = exercises
        self.isInMethod = isInMethod
        self.methodValidation = methodValidation
        self.methodType = methodType
        self.cardTargetExpression = cardTargetExpression
        _notes = State(initialValue: exerciseItemData.wrappedValue.notes ?? "")

        let restTime = exerciseItemData.wrappedValue.restTime ?? 60
        _restMinutes = State(initialValue: Int(restTime) / 60)
        _restSeconds = State(initialValue: Int(restTime) % 60)
    }

    var body: some View {
        Form {
            exerciseSection

            // Target expression solo per metodi repsOnly (non per EMOM, AMRAP, Circuit, Tabata)
            if methodType?.supportedSetType != .durationOnly {
                targetInfoSection
            }

            if !isInMethod {
                restTimeSection
            }

            notesSection

            if let error = validationError {
                validationWarningSection(error: error)
            }

            setsSection
        }
        .navigationTitle("Configura Esercizio")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(exercises: exercises) { exercise in
                exerciseItemData.exercise = exercise
            }
        }
        .toolbar(content: toolbarContent)
        .onAppear {
            loadUserProfile()
        }
        .appScreenBackground()
    }

    // MARK: - View Components

    private var exerciseSection: some View {
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
    }

    private var targetInfoSection: some View {
        Section("Obiettivo di scheda") {
            if let params = targetParameters {
                VStack(alignment: .leading, spacing: 8) {
                    Label(params.type.rawValue, systemImage: params.type.icon)
                        .foregroundStyle(params.type.color)
                    HStack {
                        MetricPill(title: "Carico", value: "\(Int(params.loadPercentageMin))%-\(Int(params.loadPercentageMax))%")
                        MetricPill(title: "Rip", value: "\(params.repsMin)-\(params.repsMax)")
                        MetricPill(title: "Serie", value: "\(params.setsMin)-\(params.setsMax)")
                    }
                }
            } else {
                Text("Imposta il target della scheda nella schermata principale per attivare gli alert sui parametri.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var restTimeSection: some View {
        Section {
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
        } header: {
            Text("Tempo di Recupero")
        } footer: {
            if isRestTimeOutOfRange, let params = targetParameters {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Il recupero consigliato per \(params.type.rawValue) è \(params.restTimeMinFormatted)-\(params.restTimeMaxFormatted)")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    private var notesSection: some View {
        Section("Note") {
            TextField("Note (opzionale)", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private func validationWarningSection(error: String) -> some View {
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

    @ViewBuilder
    private var setsSection: some View {
        Section {
            setsList
            addSetButton
        } header: {
            setsHeader
        } footer: {
            setsFooter
        }
    }

    @ViewBuilder
    private var setsList: some View {
        let isCluster = methodType?.requiresClusterManagement ?? false
        let isRestPause = methodType?.requiresRestPauseManagement ?? false
        let setTypeSupport = methodType?.supportedSetType ?? .repsOnly
        if isInMethod {
            ForEach($exerciseItemData.sets) { $set in
                SetRow(
                    set: $set,
                    exercise: exerciseItemData.exercise,
                    oneRepMax: oneRepMax,
                    isClusterSet: isCluster,
                    isRestPauseSet: isRestPause,
                    setTypeSupport: setTypeSupport,
                    targetParameters: targetParameters
                )
            }
        } else {
            ForEach($exerciseItemData.sets) { $set in
                SetRow(
                    set: $set,
                    exercise: exerciseItemData.exercise,
                    oneRepMax: oneRepMax,
                    isClusterSet: isCluster,
                    isRestPauseSet: isRestPause,
                    setTypeSupport: setTypeSupport,
                    targetParameters: targetParameters
                )
            }
            .onMove(perform: moveSets)
            .onDelete(perform: deleteSets)
        }
    }

    @ViewBuilder
    private var addSetButton: some View {
        if !isInMethod {
            Button {
                addSet()
            } label: {
                Label("Aggiungi Serie", systemImage: "plus.circle.fill")
            }
        }
    }

    private var setsHeader: some View {
        HStack {
            Text(isInMethod ? "Ripetizioni per Serie" : "Serie")
            Spacer()
            if !isInMethod {
                TitleCaseEditButton()
            }
        }
    }

    @ViewBuilder
    private var setsFooter: some View {
        if isInMethod {
            Text("Il numero di serie è gestito dal blocco metodologia")
                .font(.caption)
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

private func applyCloneLoadIfNeeded() {
        guard cloneLoadEnabled else { return }
        for set in exerciseItemData.sets where set.weight != nil || set.percentageOfMax != nil {
            exerciseItemData.sets.cloneLoadIfNeeded(from: set)
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.tertiarySystemFill), in: Capsule())
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
