import SwiftUI
import SwiftData
import Observation

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutSessionViewModel
    @State private var heartRateManager = BluetoothHeartRateManager()
    @Query private var profiles: [UserProfile]
    var onFinish: (WorkoutCard) -> Void

    init(viewModel: WorkoutSessionViewModel, onFinish: @escaping (WorkoutCard) -> Void = { _ in }) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    private var userProfile: UserProfile? { profiles.first }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    sessionOverview
                    if let block = viewModel.currentBlock {
                        blockSummary(block)
                    }
                    if let exercise = viewModel.currentExerciseItem {
                        exerciseSummary(exercise)
                        if let set = viewModel.currentWorkoutSet {
                            if set.setType == .reps {
                                repsEditor(for: set)
                            } else {
                                durationEditor(for: set)
                            }
                        }
                        exerciseRPESection(for: exercise)
                    }
                    timersSection
                    if userProfile != nil {
                        cardioSection
                    }
                }
                .padding()
            }

            sessionControls
                .padding()
                .background(.thinMaterial)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Chiudi") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Salva") {
                    if viewModel.isCompleted {
                        viewModel.showSummarySheet = true
                    } else {
                        viewModel.finishSession()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showSummarySheet) {
            SessionSummarySheet(summary: $viewModel.summary) {
                viewModel.saveSummary()
                onFinish(viewModel.card)
                dismiss()
            } onCancel: {
                viewModel.showSummarySheet = false
            }
        }
        .alert("Sessione salvata", isPresented: $viewModel.showCompletionAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text("Allenamento registrato con successo")
        }
        .alert("Abbandonare l'allenamento?", isPresented: $viewModel.showAbandonAlert) {
            Button("Continua", role: .cancel) {}
            Button("Abbandona", role: .destructive) {
                dismiss()
            }
        }
    }

    private var sessionOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blocco \(viewModel.currentBlockIndex + 1) di \(viewModel.totalBlocks)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: viewModel.progressValue)
                .progressViewStyle(.linear)

            HStack {
                Label(viewModel.elapsedTime.formattedTime, systemImage: "clock.fill")
                Spacer()
                if !viewModel.nextExercisePreview.isEmpty {
                    Label(viewModel.nextExercisePreview, systemImage: "arrow.right")
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func blockSummary(_ block: WorkoutBlock) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(block.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                if block.blockType == .method, let method = block.methodType {
                    Label(method.rawValue, systemImage: method.icon)
                        .padding(6)
                        .background(method.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if block.blockType == .method {
                Text(methodDescription(block: block))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let notes = block.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func methodDescription(block: WorkoutBlock) -> String {
        guard let method = block.methodType else { return "" }
        switch method {
        case .superset:
            return "Completa \(block.globalSets) superset senza pausa tra gli esercizi"
        case .triset:
            return "Triset da \(block.globalSets) giri consecutivi"
        case .giantSet:
            return "Giant set con \(block.exerciseItems.count) esercizi"
        case .dropset:
            return "Dropset: riduci il carico rapidamente, pausa solo a fine serie"
        case .rest_pause:
            return "Rest-Pause: micro pause impostate nella serie"
        case .cluster:
            return "Cluster set con pause programmate"
        case .emom:
            return "Every Minute On the Minute per \(block.globalSets) minuti"
        case .amrap:
            return "AMRAP fino al termine del timer"
        case .circuit:
            return "Circuito da \(block.globalSets) giri"
        case .tabata:
            return "Protocollo Tabata classico (20\" / 10\")"
        case .pyramidAscending:
            return "Piramide crescente: aumenta i carichi ogni serie"
        case .pyramidDescending:
            return "Piramide decrescente: scarica gradualmente"
        case .contrastTraining:
            return "Contrast Training: alterna forza e potenza"
        case .complexTraining:
            return "Complex Training combinato"
        default:
            return method.description
        }
    }

    private func exerciseSummary(_ exerciseItem: WorkoutExerciseItem) -> some View {
        let totalSets = max(exerciseItem.sets.count, viewModel.currentBlock?.globalSets ?? 1)
        return ExerciseSummaryCard(
            exerciseItem: exerciseItem,
            totalSets: totalSets,
            currentSetIndex: viewModel.currentSetIndex
        )
    }

    private func repsEditor(for set: WorkoutSet) -> some View {
        let binding = Binding(
            get: {
                if let saved = viewModel.setResults[set.id] {
                    return saved
                }
                var result = WorkoutSessionViewModel.SetExecutionResult(setID: set.id)
                result.confirmedWeight = set.weight
                result.confirmedPercentage = set.percentageOfMax
                viewModel.setResults[set.id] = result
                return result
            },
            set: { viewModel.setResults[set.id] = $0 }
        )

        return VStack(alignment: .leading, spacing: 16) {
            Text("Dettagli Serie")
                .font(.headline)
            VStack(spacing: 12) {
                if let reps = set.reps {
                    LabeledContent("Ripetizioni") {
                        Text("\(reps)")
                    }
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: Binding(
                            get: { binding.wrappedValue.confirmedWeight ?? set.weight ?? 0 },
                            set: { value in
                                var updated = binding.wrappedValue
                                updated.confirmedWeight = value
                                updated.confirmedPercentage = nil
                                binding.wrappedValue = updated
                            }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading) {
                        Text("% 1RM")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: Binding(
                            get: { binding.wrappedValue.confirmedPercentage ?? set.percentageOfMax ?? 0 },
                            set: { value in
                                var updated = binding.wrappedValue
                                updated.confirmedPercentage = value
                                updated.confirmedWeight = nil
                                binding.wrappedValue = updated
                            }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    }
                }

                VStack(alignment: .leading) {
                    Text("RPE Serie (1-10)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: Binding(
                        get: { Double(binding.wrappedValue.perceivedEffort) },
                        set: { newValue in
                            var updated = binding.wrappedValue
                            updated.perceivedEffort = Int(newValue.rounded())
                            binding.wrappedValue = updated
                        }
                    ), in: 1...10, step: 1)
                    Text("\(binding.wrappedValue.perceivedEffort)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Feedback carico")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Feedback", selection: Binding(
                        get: { binding.wrappedValue.feedback },
                        set: { binding.wrappedValue.feedback = $0 }
                    )) {
                        ForEach(WorkoutSessionViewModel.SetExecutionResult.LoadFeedback.allCases) { feedback in
                            Label(feedback.rawValue, systemImage: feedback.symbol)
                                .tag(feedback)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
    }

    private func durationEditor(for set: WorkoutSet) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timer di lavoro")
                .font(.headline)
            ProtocolTimerView(engine: viewModel.protocolTimer)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private func exerciseRPESection(for exercise: WorkoutExerciseItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RPE esercizio")
                .font(.headline)
            Slider(value: Binding(
                get: { Double(viewModel.exerciseRPE[exercise.id] ?? 6) },
                set: { viewModel.exerciseRPE[exercise.id] = Int($0.rounded()) }
            ), in: 1...10, step: 1)
            Text("\(viewModel.exerciseRPE[exercise.id] ?? 6)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var timersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer di recupero")
                .font(.headline)
            CountdownTimerControl(title: "Pausa intra-serie", engine: viewModel.intraSetTimer, defaultDuration: viewModel.recommendedIntraRest)
            CountdownTimerControl(title: "Pausa inter-serie", engine: viewModel.interSetTimer, defaultDuration: viewModel.recommendedInterRest)
            if showProtocolTimerInRecoveryCard {
                ProtocolTimerView(engine: viewModel.protocolTimer)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private var cardioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zona Cardio")
                .font(.headline)
            if heartRateManager.isConnected, let profile = userProfile {
                CardioStatusView(currentHeartRate: heartRateManager.currentHeartRate, profile: profile)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collega un cardiofrequenzimetro dalla schermata Heart Rate Monitor per visualizzare la zona in tempo reale.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        heartRateManager.startScanning()
                    } label: {
                        Label("Scansiona dispositivi", systemImage: "wave.3.right")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var sessionControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    viewModel.previousStep()
                } label: {
                    Label("Indietro", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canGoBack)

                Button {
                    viewModel.completeCurrentStep()
                } label: {
                    Label("Completa", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 16) {
                Button(role: .destructive) {
                    viewModel.showAbandonAlert = true
                } label: {
                    Label("Abbandona", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.togglePause()
                } label: {
                    Label(viewModel.isPaused ? "Riprendi" : "Pausa", systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct ExerciseSummaryCard: View {
    let exerciseItem: WorkoutExerciseItem
    let totalSets: Int
    let currentSetIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            notesSection
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var notesSection: some View {
        if let notes = exerciseItem.notes, !notes.isEmpty {
            Label(notes, systemImage: "note.text")
                .font(.callout)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseItem.exercise?.name ?? "Esercizio")
                    .font(.title2)
                    .fontWeight(.bold)
                if let muscleName = exerciseItem.exercise?.primaryMuscles.first?.name {
                    Text(muscleName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("Serie \(currentSetIndex + 1)/\(totalSets)")
                .font(.callout)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

extension WorkoutSessionView {
    private var showProtocolTimerInRecoveryCard: Bool {
        guard viewModel.protocolTimerMode != nil else { return false }
        if let set = viewModel.currentWorkoutSet, set.setType == .duration {
            return false
        }
        return true
    }
}

private struct CountdownTimerControl: View {
    let title: String
    @Bindable var engine: TrainingTimerEngine
    var defaultDuration: TimeInterval

    @State private var customDuration: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(engine.remainingTime.formattedTime)
                    .font(.headline)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)

            HStack {
                Button(engine.state == .running ? "Pausa" : "Avvia") {
                    toggleTimer()
                }
                Button("Reset") {
                    engine.stop()
                    engine.update(mode: .countdown(customDuration > 0 ? customDuration : defaultDuration))
                }
            }
            .buttonStyle(.bordered)

            Stepper("Durata: \(Int(customDuration > 0 ? customDuration : defaultDuration))s", value: Binding(
                get: { customDuration > 0 ? customDuration : defaultDuration },
                set: { newValue in
                    customDuration = newValue
                    engine.update(mode: .countdown(newValue))
                }
            ), in: 5...600, step: 5)
        }
        .onAppear {
            if customDuration == 0 {
                customDuration = defaultDuration
            }
        }
    }

    private var progress: Double {
        guard engine.mode.initialDuration > 0 else { return 0 }
        return max(0, 1 - engine.remainingTime / engine.mode.initialDuration)
    }

    private func toggleTimer() {
        if engine.state == .running {
            engine.pause()
        } else if engine.state == .paused {
            engine.resume()
        } else {
            engine.start()
        }
    }
}

private struct ProtocolTimerView: View {
    @Bindable var engine: TrainingTimerEngine

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(phaseTitle)
                    .font(.headline)
                Spacer()
                Text(engine.remainingTime.formattedTime)
                    .font(.title2)
                    .monospacedDigit()
            }
            HStack {
                Button(engine.state == .running ? "Pausa" : "Avvia") {
                    if engine.state == .running {
                        engine.pause()
                    } else if engine.state == .paused {
                        engine.resume()
                    } else {
                        engine.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                Button("Reset") {
                    engine.stop()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var phaseTitle: String {
        switch engine.mode {
        case .tabata:
            switch engine.phase {
            case .work: return "Lavoro"
            case .rest: return "Recupero"
            case .completed: return "Completato"
            default: return ""
            }
        case .emom:
            return "Round \(engine.currentRound)/\(engine.totalRounds)"
        case .amrap:
            return engine.state == .stopped ? "Completo" : "AMRAP"
        case .circuit:
            return engine.phase == .rest ? "Transizione" : "Circuito"
        case .countdown:
            return "Timer"
        }
    }
}

private struct CardioStatusView: View {
    let currentHeartRate: Int
    let profile: UserProfile

    private var zone: HeartRateZone? {
        profile.zone(for: currentHeartRate)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentHeartRate) bpm")
                    .font(.title)
                    .fontWeight(.bold)
                Text(zone?.name ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let zone = zone {
                Circle()
                    .fill(zone.color)
                    .frame(width: 48, height: 48)
                    .overlay(Text("Z\(zone.rawValue)"))
            }
        }
        .padding()
        .background(zone?.color.opacity(0.2) ?? Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SessionSummarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var summary: WorkoutSessionViewModel.WorkoutSessionSummary
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("RPE Totale") {
                    Stepper(value: $summary.rpe, in: 6...20) {
                        Text("RPE: \(summary.rpe)")
                    }
                }

                Section("Note") {
                    TextEditor(text: $summary.notes)
                        .frame(minHeight: 100)
                }

                Section("Stato fisico") {
                    Picker("Stato", selection: $summary.feeling) {
                        ForEach(WorkoutSessionViewModel.WorkoutSessionSummary.PhysicalFeeling.allCases) { feeling in
                            Text("\(feeling.emoji) \(feeling.rawValue)").tag(feeling)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Salva Sessione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private extension UserProfile {
    func zone(for heartRate: Int) -> HeartRateZone? {
        switch heartRate {
        case ..<zone1Max:
            return .zone1
        case zone1Max..<zone2Max:
            return .zone2
        case zone2Max..<zone3Max:
            return .zone3
        case zone3Max..<zone4Max:
            return .zone4
        case zone4Max...:
            return .zone5
        default:
            return nil
        }
    }
}
