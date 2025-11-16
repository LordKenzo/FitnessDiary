import SwiftUI
import SwiftData

struct EditWorkoutExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var exerciseData: WorkoutExerciseItemData
    let exercises: [Exercise]

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
                    SetRow(set: $set, exercise: exerciseData.exercise, oneRepMax: oneRepMax)
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
            Button("Fatto") {
                saveChanges()
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
    var isTabataSet: Bool = false
    var setTypeSupport: SetTypeSupport = .repsOnly
    var targetParameters: StrengthExpressionParameters? = nil

    // Validazione del carico rispetto all'obiettivo
    private var loadPercentage: Double? {
        guard let oneRepMax = oneRepMax else { return nil }
        if let weight = set.weight, set.loadType == .absolute, oneRepMax > 0 {
            return (weight / oneRepMax) * 100.0
        } else if let percentage = set.percentageOfMax, set.loadType == .percentage {
            return percentage
        }
        return nil
    }

    private var isLoadOutOfRange: Bool {
        guard let params = targetParameters, let loadPct = loadPercentage else { return false }
        return !params.isLoadInRange(loadPct)
    }

    private var areRepsOutOfRange: Bool {
        guard let params = targetParameters, let reps = set.reps else { return false }
        return !params.areRepsInRange(reps)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Text("Serie \(set.order + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                // Mostra tipo fisso (i metodi ora supportano solo un tipo)
                Text(set.setType.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if set.setType == .reps {
                VStack(spacing: 4) {
                    // Prima riga: Rip + Toggle Kg/%
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

                            if areRepsOutOfRange {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }

                        Picker("", selection: $set.loadType) {
                            Text("Kg").tag(LoadType.absolute)
                            Text("% 1RM").tag(LoadType.percentage)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }

                    // Seconda riga: Campo input + valore calcolato
                    HStack(spacing: 16) {
                        Spacer()
                            .frame(width: 60)

                        Spacer()
                            .frame(width: 54) // Allinea con campo Rip

                        if set.loadType == .absolute {
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

                            // Mostra percentuale calcolata se disponibile 1RM
                            if let oneRepMax = oneRepMax, let weight = set.weight, oneRepMax > 0 {
                                let percentage = (weight / oneRepMax) * 100.0
                                HStack(spacing: 4) {
                                    Text("→ \(Int(percentage))%")
                                        .font(.caption)
                                        .foregroundStyle(isLoadOutOfRange ? .yellow : .blue)

                                    if isLoadOutOfRange {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.yellow)
                                    }
                                }
                            }
                        } else {
                            HStack(spacing: 4) {
                                TextField("%", value: $set.percentageOfMax, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                                    .textFieldStyle(.roundedBorder)
                                Text("%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            // Mostra kg calcolati se disponibile 1RM
                            if let oneRepMax = oneRepMax, let percentage = set.percentageOfMax {
                                let weight = (percentage / 100.0) * oneRepMax
                                HStack(spacing: 4) {
                                    Text("→ \(String(format: "%.1f", weight)) kg")
                                        .font(.caption)
                                        .foregroundStyle(isLoadOutOfRange ? .yellow : .blue)

                                    if isLoadOutOfRange {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.yellow)
                                    }
                                }
                            } else if set.percentageOfMax != nil {
                                Text("⚠️ 1RM non impostato")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                // Campi Cluster Set
                if isClusterSet {
                    Divider()
                    clusterFields
                }

                // Campi Rest-Pause
                if isRestPauseSet {
                    Divider()
                    restPauseFields
                }

                // Campi Tabata
                if isTabataSet {
                    Divider()
                    tabataFields
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

    @ViewBuilder
    private var clusterFields: some View {
        VStack(spacing: 8) {
            // Cluster Size
            HStack(spacing: 16) {
                Text("Cluster")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Reps", value: $set.clusterSize, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("reps/cluster")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Cluster Rest Time
            HStack(spacing: 16) {
                Text("Pausa")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Sec", value: Binding(
                        get: {
                            if let rest = set.clusterRestTime {
                                return Int(rest)
                            }
                            return 15
                        },
                        set: { newValue in
                            set.clusterRestTime = TimeInterval(min(60, max(15, newValue)))
                        }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("sec (15-60)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Progressione carico
            HStack(spacing: 16) {
                Text("Tipo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Picker("", selection: Binding(
                    get: { set.clusterProgression ?? .constant },
                    set: { set.clusterProgression = $0 }
                )) {
                    ForEach(ClusterLoadProgression.allCases, id: \.self) { progression in
                        Label(progression.rawValue, systemImage: progression.icon).tag(progression)
                    }
                }
                .pickerStyle(.menu)

                Spacer()
            }

            // Percentuale minima
            HStack(spacing: 16) {
                Text("Min %")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("%", value: Binding(
                        get: { set.clusterMinPercentage ?? 80 },
                        set: { set.clusterMinPercentage = min(100, max(50, $0)) }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("% 1RM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Percentuale massima
            HStack(spacing: 16) {
                Text("Max %")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("%", value: Binding(
                        get: { set.clusterMaxPercentage ?? 95 },
                        set: { set.clusterMaxPercentage = min(100, max(50, $0)) }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("% 1RM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Visualizzazione percentuali calcolate
            if let percentages = set.clusterLoadPercentages() {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carichi:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            ForEach(Array(percentages.enumerated()), id: \.offset) { index, pct in
                                Text("\(Int(pct))%")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                if index < percentages.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }

            // Descrizione cluster se valida
            if let description = set.clusterDescription {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Spacer()
                }
            }

            // Validazione: cluster non può essere > ripetizioni
            if let totalReps = set.reps, let clusterSize = set.clusterSize, clusterSize > totalReps {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Il cluster non può essere maggiore delle ripetizioni")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Rest-Pause Fields

    private var restPauseFields: some View {
        VStack(spacing: 8) {
            // Numero di pause
            HStack(spacing: 16) {
                Text("Pause")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Stepper {
                    HStack(spacing: 4) {
                        Text("\(set.restPauseCount ?? 2)")
                            .font(.subheadline)
                        Text("pause")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } onIncrement: {
                    set.restPauseCount = min(5, (set.restPauseCount ?? 2) + 1)
                } onDecrement: {
                    set.restPauseCount = max(1, (set.restPauseCount ?? 2) - 1)
                }
                .frame(width: 120)

                Spacer()
            }

            // Durata pause
            HStack(spacing: 16) {
                Text("Durata")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Sec", value: Binding(
                        get: {
                            if let duration = set.restPauseDuration {
                                return Int(duration)
                            }
                            return 15
                        },
                        set: { newValue in
                            set.restPauseDuration = TimeInterval(min(30, max(5, newValue)))
                        }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("sec (5-30)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Descrizione rest-pause se valida
            if let description = set.restPauseDescription {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Tabata Fields

    private var tabataFields: some View {
        VStack(spacing: 8) {
            // Numero di round
            HStack(spacing: 16) {
                Text("Round")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Stepper {
                    HStack(spacing: 4) {
                        Text("\(set.tabataRounds ?? 8)")
                            .font(.subheadline)
                        Text("round")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } onIncrement: {
                    set.tabataRounds = min(12, (set.tabataRounds ?? 8) + 1)
                } onDecrement: {
                    set.tabataRounds = max(4, (set.tabataRounds ?? 8) - 1)
                }
                .frame(width: 120)

                Spacer()
            }

            // Durata lavoro
            HStack(spacing: 16) {
                Text("Lavoro")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Sec", value: Binding(
                        get: {
                            if let work = set.tabataWorkDuration {
                                return Int(work)
                            }
                            return 20
                        },
                        set: { newValue in
                            set.tabataWorkDuration = TimeInterval(min(60, max(10, newValue)))
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

                Spacer()
            }

            // Durata recupero
            HStack(spacing: 16) {
                Text("Recupero")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Sec", value: Binding(
                        get: {
                            if let rest = set.tabataRestDuration {
                                return Int(rest)
                            }
                            return 10
                        },
                        set: { newValue in
                            set.tabataRestDuration = TimeInterval(min(30, max(5, newValue)))
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

                Spacer()
            }

            // Descrizione Tabata e durata totale
            if let description = set.tabataDescription {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.blue)
                        if let totalDuration = set.tabataTotalDuration {
                            let minutes = Int(totalDuration) / 60
                            let seconds = Int(totalDuration) % 60
                            Text("Durata totale: \(minutes)'\(seconds)\"")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
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
