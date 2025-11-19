import SwiftUI
import SwiftData

struct EditWorkoutBlockView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @Binding var blockData: WorkoutBlockData
    let cardTargetExpression: StrengthExpressionType?

    @State private var globalSets: Int
    @State private var globalRestMinutes: Int
    @State private var globalRestSeconds: Int
    @State private var notes: String
    @State private var showingExercisePicker = false

    // Tabata parameters
    @State private var tabataWorkSeconds: Int
    @State private var tabataRestSeconds: Int
    @State private var tabataRounds: Int
    @State private var tabataRecoveryMinutes: Int
    @State private var tabataRecoverySeconds: Int

    init(blockData: Binding<WorkoutBlockData>, cardTargetExpression: StrengthExpressionType? = nil) {
        self._blockData = blockData
        self.cardTargetExpression = cardTargetExpression
        _globalSets = State(initialValue: blockData.wrappedValue.globalSets)
        let restTime = blockData.wrappedValue.globalRestTime ?? 60
        _globalRestMinutes = State(initialValue: Int(restTime) / 60)
        _globalRestSeconds = State(initialValue: Int(restTime) % 60)
        _notes = State(initialValue: blockData.wrappedValue.notes ?? "")

        // Initialize Tabata parameters
        _tabataWorkSeconds = State(initialValue: Int(blockData.wrappedValue.tabataWorkDuration ?? 20))
        _tabataRestSeconds = State(initialValue: Int(blockData.wrappedValue.tabataRestDuration ?? 10))
        _tabataRounds = State(initialValue: blockData.wrappedValue.tabataRounds ?? 5)
        let recoveryTime = blockData.wrappedValue.tabataRecoveryBetweenRounds ?? 60
        _tabataRecoveryMinutes = State(initialValue: Int(recoveryTime) / 60)
        _tabataRecoverySeconds = State(initialValue: Int(recoveryTime) % 60)
    }

    var body: some View {
        Form {
            // Block info section
            Section {
                HStack {
                    Image(systemName: blockIconName)
                        .font(.title2)
                        .foregroundStyle(blockAccentColor)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(blockTitle)
                            .font(.headline)
                        if let description = blockDescription {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Global parameters section - solo per metodi
            if blockData.blockType == .method {
                Section("Parametri Blocco") {
                    Stepper("Serie: \(globalSets)", value: $globalSets, in: 1...20)
                        .onChange(of: globalSets) { _, _ in
                            syncExerciseSetsInRealTime()
                        }

                    // Recupero tra serie - nascosto per Drop Set
                    if blockData.methodType?.allowsRestBetweenSets ?? true {
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
                    } else {
                        Text("Questo metodo non prevede recupero tra le serie")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    TextField("Note (opzionale)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }

            if blockData.blockType == .rest {
                Section("Durata Riposo") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Imposta la durata della pausa tra i blocchi")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            Picker("Minuti", selection: $globalRestMinutes) {
                                ForEach(0..<20, id: \.self) { min in
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
                }
            }

            // Tabata parameters section - solo per Tabata
            if blockData.methodType == .tabata {
                Section {
                    // Tempo di lavoro
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tempo Lavoro")
                            .font(.subheadline)

                        HStack(spacing: 8) {
                            TextField("Secondi", value: $tabataWorkSeconds, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("secondi (10-60s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Tempo di recupero tra esercizi
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recupero tra Esercizi")
                            .font(.subheadline)

                        HStack(spacing: 8) {
                            TextField("Secondi", value: $tabataRestSeconds, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("secondi (5-30s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Numero di giri
                    Stepper("Giri: \(tabataRounds)", value: $tabataRounds, in: 1...10)

                    // Recupero tra i giri
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recupero tra Giri")
                            .font(.subheadline)

                        HStack(spacing: 16) {
                            Picker("Minuti", selection: $tabataRecoveryMinutes) {
                                ForEach(0..<5, id: \.self) { min in
                                    Text("\(min)m").tag(min)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)

                            Picker("Secondi", selection: $tabataRecoverySeconds) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { sec in
                                    Text("\(sec)s").tag(sec)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                        }
                    }
                } header: {
                    Text("Parametri Tabata")
                } footer: {
                    let totalTime = calculateTabataTotalDuration()
                    let minutes = totalTime / 60
                    let seconds = totalTime % 60
                    Text("Durata totale: \(minutes) min \(seconds) sec (\(tabataRounds) giri × 8 esercizi)")
                        .font(.caption)
                }
            }

            // Exercises section
            if blockData.blockType != .rest {
                Section {
                    ForEach(blockData.exerciseItems.indices, id: \.self) { index in
                        NavigationLink {
                            EditWorkoutExerciseItemView(
                                exerciseItemData: $blockData.exerciseItems[index],
                                exercises: exercises,
                                isInMethod: blockData.blockType == .method,
                                methodValidation: blockData.methodType?.loadProgressionValidation,
                                methodType: blockData.methodType,
                                cardTargetExpression: cardTargetExpression
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
                    .disabled(cannotAddMoreExercises)
                } header: {
                    HStack {
                        Text("Esercizi (\(blockData.exerciseItems.count))")
                        if blockData.blockType == .method, let method = blockData.methodType {
                            if let max = method.maxExercises {
                                Text("• \(method.minExercises)-\(max)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("• min \(method.minExercises)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if !blockData.exerciseItems.isEmpty {
                            TitleCaseEditButton()
                        }
                    }
                } footer: {
                    if blockData.blockType == .simple && !blockData.exerciseItems.isEmpty {
                        Text("Un blocco semplice può contenere solo un esercizio")
                            .font(.caption)
                    } else if blockData.blockType == .method, let method = blockData.methodType {
                        if method.maxExercises != nil {
                            Text("Questo metodo richiede esattamente \(method.minExercises) esercizi")
                                .font(.caption)
                        } else {
                            Text("Questo metodo richiede almeno \(method.minExercises) esercizi")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
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
        if blockData.blockType == .rest {
            return restDurationInSeconds > 0
        }
        if blockData.exerciseItems.isEmpty {
            return false
        }
        if blockData.blockType == .method, let method = blockData.methodType {
            let count = blockData.exerciseItems.count
            // Controlla il minimo
            if count < method.minExercises {
                return false
            }
            // Controlla il massimo se presente
            if let max = method.maxExercises, count > max {
                return false
            }
        }
        return true
    }

    private var cannotAddMoreExercises: Bool {
        if blockData.blockType == .rest {
            return true
        }
        // Blocco semplice può avere solo 1 esercizio
        if blockData.blockType == .simple && !blockData.exerciseItems.isEmpty {
            return true
        }
        // Controlla se il metodo ha un limite massimo
        if blockData.blockType == .method, let method = blockData.methodType {
            if let max = method.maxExercises {
                return blockData.exerciseItems.count >= max
            }
        }
        return false
    }

    private func addExercise(_ exercise: Exercise) {
        // Se è un metodo, crea le serie in base a globalSets
        let setsCount = blockData.blockType == .method ? globalSets : 1
        let isCluster = blockData.methodType?.requiresClusterManagement ?? false
        let isRestPause = blockData.methodType?.requiresRestPauseManagement ?? false

        // Determina il tipo di serie corretto per il metodo
        let setTypeSupport = blockData.methodType?.supportedSetType
        let defaultSetType: SetType
        if let support = setTypeSupport {
            switch support {
            case .repsOnly:
                defaultSetType = .reps
            case .durationOnly:
                defaultSetType = .duration
            }
        } else {
            // Default per esercizi singoli
            defaultSetType = .reps
        }

        var sets: [WorkoutSetData] = []
        for i in 0..<setsCount {
            sets.append(WorkoutSetData(
                order: i,
                setType: defaultSetType,
                reps: defaultSetType == .reps ? 10 : nil,
                weight: nil,
                duration: defaultSetType == .duration ? 30 : nil,
                loadType: .absolute,
                percentageOfMax: nil,
                clusterSize: isCluster ? 2 : nil,
                clusterRestTime: isCluster ? 30 : nil,
                clusterProgression: isCluster ? .constant : nil,
                clusterMinPercentage: isCluster ? 80 : nil,
                clusterMaxPercentage: isCluster ? 95 : nil,
                restPauseCount: isRestPause ? 2 : nil,
                restPauseDuration: isRestPause ? 15 : nil
            ))
        }

        let newExerciseItem = WorkoutExerciseItemData(
            exercise: exercise,
            order: blockData.exerciseItems.count,
            sets: sets
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

        let restTimeValue = TimeInterval(restDurationInSeconds)

        switch blockData.blockType {
        case .method:
            if blockData.methodType?.allowsRestBetweenSets ?? true {
                blockData.globalRestTime = restTimeValue
            } else {
                blockData.globalRestTime = nil // Dropset non deve avere rest time
            }
        case .rest:
            blockData.globalRestTime = restTimeValue
        case .simple:
            break
        }

        blockData.notes = notes.isEmpty ? nil : notes

        // Salva parametri Tabata se è un metodo Tabata
        if blockData.methodType == .tabata {
            blockData.tabataWorkDuration = TimeInterval(tabataWorkSeconds)
            blockData.tabataRestDuration = TimeInterval(tabataRestSeconds)
            blockData.tabataRounds = tabataRounds
            blockData.tabataRecoveryBetweenRounds = TimeInterval(tabataRecoveryMinutes * 60 + tabataRecoverySeconds)
        }

        // Se è un metodo, sincronizza il numero di serie di tutti gli esercizi
        if blockData.blockType == .method {
            syncExerciseSets()
        }
    }

    private func calculateTabataTotalDuration() -> Int {
        // Durata di un giro: 8 esercizi × (tempo lavoro + tempo recupero) - ultimo recupero
        let roundDuration = 8 * (tabataWorkSeconds + tabataRestSeconds) - tabataRestSeconds
        // Durata totale: giri × durata giro + recuperi tra giri
        let totalTime = tabataRounds * roundDuration + (tabataRounds - 1) * (tabataRecoveryMinutes * 60 + tabataRecoverySeconds)
        return totalTime
    }

    /// Sincronizza il numero di serie di tutti gli esercizi con globalSets (per onSave)
    private func syncExerciseSets() {
        syncSetsForCount(globalSets)
    }

    /// Sincronizza in tempo reale quando l'utente cambia globalSets
    private func syncExerciseSetsInRealTime() {
        syncSetsForCount(globalSets)
    }

    /// Logica comune di sincronizzazione
    private func syncSetsForCount(_ targetSetsCount: Int) {
        let isCluster = blockData.methodType?.requiresClusterManagement ?? false
        let isRestPause = blockData.methodType?.requiresRestPauseManagement ?? false

        // Determina il tipo di serie corretto per il metodo
        let setTypeSupport = blockData.methodType?.supportedSetType
        let defaultSetType: SetType
        if let support = setTypeSupport {
            switch support {
            case .repsOnly:
                defaultSetType = .reps
            case .durationOnly:
                defaultSetType = .duration
            }
        } else {
            // Default per esercizi singoli
            defaultSetType = .reps
        }

        for index in blockData.exerciseItems.indices {
            let currentSetsCount = blockData.exerciseItems[index].sets.count

            if currentSetsCount < targetSetsCount {
                // Aggiungi serie mancanti
                for setOrder in currentSetsCount..<targetSetsCount {
                    let newSet = WorkoutSetData(
                        order: setOrder,
                        setType: defaultSetType,
                        reps: defaultSetType == .reps ? 10 : nil,
                        weight: nil,
                        duration: defaultSetType == .duration ? 30 : nil,
                        loadType: .absolute,
                        percentageOfMax: nil,
                        clusterSize: isCluster ? 2 : nil,
                        clusterRestTime: isCluster ? 30 : nil,
                        clusterProgression: isCluster ? .constant : nil,
                        clusterMinPercentage: isCluster ? 80 : nil,
                        clusterMaxPercentage: isCluster ? 95 : nil,
                        restPauseCount: isRestPause ? 2 : nil,
                        restPauseDuration: isRestPause ? 15 : nil
                    )
                    blockData.exerciseItems[index].sets.append(newSet)
                }
            } else if currentSetsCount > targetSetsCount {
                // Rimuovi serie in eccesso
                blockData.exerciseItems[index].sets = Array(blockData.exerciseItems[index].sets.prefix(targetSetsCount))
            }

            // Riordina gli indici
            for setIndex in blockData.exerciseItems[index].sets.indices {
                blockData.exerciseItems[index].sets[setIndex].order = setIndex
            }
        }
    }

    private var navigationTitle: String {
        switch blockData.blockType {
        case .method:
            return "Modifica Metodo"
        case .rest:
            return "Modifica Riposo"
        case .simple:
            return "Modifica Esercizio"
        }
    }

    private var blockIconName: String {
        switch blockData.blockType {
        case .method:
            return blockData.methodType?.icon ?? "bolt.horizontal.fill"
        case .rest:
            return "moon.zzz.fill"
        case .simple:
            return "figure.strengthtraining.traditional"
        }
    }

    private var blockAccentColor: Color {
        switch blockData.blockType {
        case .method:
            return blockData.methodType?.color ?? .blue
        case .rest:
            return .orange
        case .simple:
            return .blue
        }
    }

    private var blockTitle: String {
        switch blockData.blockType {
        case .method:
            return blockData.methodType?.rawValue ?? BlockType.method.rawValue
        case .rest:
            return BlockType.rest.rawValue
        case .simple:
            return BlockType.simple.rawValue
        }
    }

    private var blockDescription: String? {
        switch blockData.blockType {
        case .method:
            return blockData.methodType?.description
        case .rest:
            return "Aggiungi una pausa temporizzata tra i blocchi"
        case .simple:
            return nil
        }
    }

    private var restDurationInSeconds: Int {
        globalRestMinutes * 60 + globalRestSeconds
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
    @Previewable @State var blockData = WorkoutBlockData(
        blockType: .method,
        methodType: .superset,
        order: 0,
        globalSets: 4,
        globalRestTime: 120,
        notes: "Test superset",
        exerciseItems: [
            WorkoutExerciseItemData(
                exercise: Exercise(
                    name: "Panca Piana",
                    biomechanicalStructure: .multiJoint,
                    trainingRole: .fundamental,
                    primaryMetabolism: .anaerobic,
                    category: .training
                ),
                order: 0,
                sets: [
                    WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: 80, loadType: .absolute, percentageOfMax: nil),
                    WorkoutSetData(order: 1, setType: .reps, reps: 8, weight: 85, loadType: .absolute, percentageOfMax: nil),
                    WorkoutSetData(order: 2, setType: .reps, reps: 6, weight: 90, loadType: .absolute, percentageOfMax: nil)
                ]
            )
        ]
    )

    NavigationStack {
        EditWorkoutBlockView(blockData: $blockData, cardTargetExpression: .hypertrophy)
    }
    .modelContainer(for: [Exercise.self])
}
