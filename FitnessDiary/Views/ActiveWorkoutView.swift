//
//  ActiveWorkoutView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI
import SwiftData

// Workout View States
enum WorkoutViewState {
    case countdown
    case active
}

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: WorkoutSession

    // User Profile for settings
    @Query private var profiles: [UserProfile]

    // Timer manager
    @State private var timerManager = WorkoutTimerManager()

    // Heart Rate Manager
    @State private var heartRateManager = BluetoothHeartRateManager()

    // Workout State
    @State private var workoutState: WorkoutViewState = .countdown
    @State private var countdownSeconds: Int = 10
    @State private var countdownTimer: Timer?

    // Performance input state
    @State private var inputReps: String = ""
    @State private var inputWeight: String = ""
    @State private var inputDuration: TimeInterval = 0
    @State private var inputNotes: String = ""
    @State private var inputRPE: Double = 5.0

    // UI State
    @State private var showingCompleteAlert = false
    @State private var showingAbandonAlert = false
    @State private var showingSetInput = false
    @State private var autoStartRest = true
    @State private var isDataLoaded = false

    private var userProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        Group {
            if isDataLoaded {
                if workoutState == .countdown {
                    countdownView
                        .navigationTitle("Preparazione")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
                } else {
                    workoutContent
                        .navigationTitle(session.workoutCard.name)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            toolbarContent
                        }
                        .alert("Completa Allenamento", isPresented: $showingCompleteAlert) {
                            Button("Annulla", role: .cancel) { }
                            Button("Completa") {
                                completeWorkout()
                            }
                        } message: {
                            Text("Sei sicuro di voler completare l'allenamento?")
                        }
                        .alert("Abbandona Allenamento", isPresented: $showingAbandonAlert) {
                            Button("Annulla", role: .cancel) { }
                            Button("Abbandona", role: .destructive) {
                                abandonWorkout()
                            }
                        } message: {
                            Text("L'allenamento verrà salvato come incompleto.")
                        }
                }
            } else {
                loadingView
                    .navigationTitle("Caricamento...")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            verifyDataLoaded()
        }
        .onDisappear {
            stopCountdown()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Caricamento allenamento...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Countdown View

    private var countdownView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Text("Inizia tra...")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("\(countdownSeconds)")
                    .font(.system(size: 100, weight: .bold, design: .rounded))
                    .foregroundStyle(countdownSeconds <= 3 ? .red : .primary)
                    .contentTransition(.numericText())
            }

            Button {
                skipCountdown()
            } label: {
                Text("Inizia Subito")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            startCountdown()
        }
    }

    // MARK: - Main Content

    private var workoutContent: some View {
        VStack(spacing: 0) {
            // Header con info allenamento
            workoutHeader

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Progress bar
                    progressBar

                    // Blocco corrente
                    currentBlockCard

                    // Esercizio corrente
                    currentExerciseCard

                    // Serie corrente
                    currentSetCard

                    // Timer (se attivo)
                    if timerManager.timerState != .idle {
                        timerCard
                    }

                    // Performance input
                    performanceInputCard

                    // Actions
                    actionButtons
                }
                .padding()
            }
        }
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            pauseButton
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showingCompleteAlert = true
                } label: {
                    Label("Completa Allenamento", systemImage: "checkmark.circle")
                }

                Button(role: .destructive) {
                    showingAbandonAlert = true
                } label: {
                    Label("Abbandona", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Workout Header

    private var workoutHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Durata
                VStack(alignment: .leading, spacing: 4) {
                    Text("Durata")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Usa tickCount per far aggiornare la durata in tempo reale
                    let _ = timerManager.tickCount
                    Text(timerManager.formatLongTime(session.activeDuration))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                Spacer()

                // Heart Rate (compatto)
                if heartRateManager.isConnected {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                            Text("BPM")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(heartRateManager.currentHeartRate)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(currentHeartRateColor)
                            .contentTransition(.numericText())
                    }
                }

                Spacer()

                // Serie
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Serie")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(session.totalCompletedSets) / \(session.workoutCard.totalSets)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    // Helper per determinare colore BPM in base alla zona
    private var currentHeartRateColor: Color {
        guard let profile = userProfile else { return .gray }
        let hr = heartRateManager.currentHeartRate
        guard hr > 0 else { return .gray }

        if hr <= profile.zone1Max {
            return .blue
        } else if hr <= profile.zone2Max {
            return .green
        } else if hr <= profile.zone3Max {
            return .yellow
        } else if hr <= profile.zone4Max {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progresso")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(session.progressPercentage))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: session.progressPercentage, total: 100)
                .tint(.blue)
        }
    }

    // MARK: - Current Block Card

    private var currentBlockCard: some View {
        Group {
            if let block = session.currentBlock {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Blocco \(session.currentBlockIndex + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if block.blockType == .method, let method = block.methodType {
                            Label(method.rawValue, systemImage: method.icon)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(method.color.opacity(0.2))
                                .foregroundStyle(method.color)
                                .cornerRadius(6)
                        }
                    }

                    Text(block.title)
                        .font(.headline)

                    if let notes = block.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }

    // MARK: - Current Exercise Card

    private var currentExerciseCard: some View {
        Group {
            if let exerciseItem = session.currentExercise,
               let exercise = exerciseItem.exercise {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Esercizio \(session.currentExerciseIndex + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }

                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    // Muscoli target
                    if !exercise.primaryMuscles.isEmpty {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption)

                            Text(exercise.primaryMuscles.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Note esercizio
                    if let notes = exerciseItem.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }

                    // Target expression se presente
                    if let target = exerciseItem.targetExpression {
                        Label(target.rawValue, systemImage: "target")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }

    // MARK: - Current Set Card

    private var currentSetCard: some View {
        Group {
            if let set = session.currentSet {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Serie \(session.currentSetIndex + 1)")
                            .font(.headline)

                        Spacer()

                        // Indicatore set type
                        Label(
                            set.setType == .reps ? "Ripetizioni" : "Durata",
                            systemImage: set.setType == .reps ? "number" : "clock"
                        )
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                    }

                    // Target prescription
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prescrizione:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            if set.setType == .reps {
                                if let reps = set.reps {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reps")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text("\(reps)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                }

                                if let weight = getTargetWeight(set) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Carico")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(String(format: "%.1f kg", weight))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                }
                            } else if set.setType == .duration {
                                if let duration = set.duration {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Durata")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(timerManager.formatTime(duration))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    // Cluster info se presente
                    if let clusterDesc = set.clusterDescription {
                        Text(clusterDesc)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }

                    // Rest-Pause info se presente
                    if let rpDesc = set.restPauseDescription {
                        Text(rpDesc)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Timer Card

    private var timerCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: timerManager.timerType.icon)
                    .font(.title3)

                Text(timerManager.timerType.description)
                    .font(.headline)

                Spacer()

                Text(timerManager.timerState.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }

            // Timer display
            Text(timerManager.formatTime(timerManager.remainingTime))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timerManager.timerType.color)

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(timerManager.timerType.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 100, height: 100)

            // Timer controls
            HStack(spacing: 16) {
                if timerManager.timerState == .running {
                    Button {
                        timerManager.pause()
                    } label: {
                        Label("Pausa", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else if timerManager.timerState == .paused {
                    Button {
                        timerManager.resume()
                    } label: {
                        Label("Riprendi", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    timerManager.skipToEnd()
                } label: {
                    Label("Salta", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(timerManager.timerType.color.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Performance Input Card

    private var performanceInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Registra Performance")
                .font(.headline)

            if let set = session.currentSet {
                if set.setType == .reps {
                    // Reps input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ripetizioni Effettive")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Reps", text: $inputReps)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                    }

                    // Weight input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Carico Effettivo (kg)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Kg", text: $inputWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                    }
                } else {
                    // Duration input (optional - could use timer)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Durata Effettiva")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(timerManager.formatTime(inputDuration))
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }

                // RPE input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("RPE (Sforzo Percepito)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(String(format: "%.1f/10", inputRPE))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Slider(value: $inputRPE, in: 1...10, step: 0.5)
                        .tint(.orange)
                }

                // Notes input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note (opzionale)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Es: forma ottima, leggero dolore spalla...", text: $inputNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Complete set button
            Button {
                completeCurrentSet()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)

                    Text("Completa Serie")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(!canCompleteSet)

            // Skip set button
            Button {
                skipCurrentSet()
            } label: {
                HStack {
                    Image(systemName: "forward.fill")
                        .font(.title3)

                    Text("Salta Serie")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Pause Button

    private var pauseButton: some View {
        Button {
            if session.isPaused {
                session.resume()
            } else {
                session.pause()
            }
            saveSession()
        } label: {
            Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
        }
    }

    // MARK: - Helpers

    private func getTargetWeight(_ set: WorkoutSet) -> Double? {
        guard let exerciseItem = session.currentExercise else { return nil }

        // Get 1RM for calculation if using percentage
        var oneRM: Double? = nil
        if let exercise = exerciseItem.exercise,
           let big5 = Big5Exercise.from(exerciseName: exercise.name) {
            oneRM = session.client?.getOneRepMax(for: big5)
        }

        return set.calculatedWeight(oneRepMax: oneRM)
    }

    private var canCompleteSet: Bool {
        guard let set = session.currentSet else { return false }

        if set.setType == .reps {
            // Require at least reps or weight
            return !inputReps.isEmpty || !inputWeight.isEmpty
        } else {
            // For duration, always allow (could use timer value)
            return true
        }
    }

    private func prepareCurrentSet() {
        guard let set = session.currentSet else { return }

        // Pre-fill with target values
        if let reps = set.reps {
            inputReps = "\(reps)"
        }

        if let weight = getTargetWeight(set) {
            inputWeight = String(format: "%.1f", weight)
        }

        // Pre-fill duration for duration-based sets
        if set.setType == .duration, let duration = set.duration {
            inputDuration = duration

            // Auto-start timer per esercizi a durata (corsa, camminata, plank, ecc.)
            if autoStartRest {
                timerManager.startCountdown(duration: duration, type: .custom)
            }
        } else {
            inputDuration = 0
        }

        inputRPE = 5.0
        inputNotes = ""
    }

    private func verifyDataLoaded() {
        // Verifica che tutte le relazioni necessarie siano caricate
        // Usa un task per dare tempo a SwiftData di caricare i dati
        Task {
            // Piccolo delay per dare tempo a SwiftData
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 secondi

            await MainActor.run {
                // Verifica che le relazioni principali siano accessibili
                let hasCard = session.workoutCard.blocks.count >= 0
                let hasBlocks = session.currentBlock != nil || session.workoutCard.blocks.isEmpty

                if hasCard && hasBlocks {
                    isDataLoaded = true

                    // Inizializza countdown da UserProfile (default 10 se non presente)
                    countdownSeconds = userProfile?.workoutCountdownSeconds ?? 10

                    // Se countdown è 0, salta direttamente al workout
                    if countdownSeconds == 0 {
                        workoutState = .active
                    } else {
                        workoutState = .countdown
                    }

                    prepareCurrentSet()
                } else {
                    // Retry dopo altro delay
                    Task {
                        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 secondi
                        await MainActor.run {
                            isDataLoaded = true

                            // Inizializza countdown da UserProfile
                            countdownSeconds = userProfile?.workoutCountdownSeconds ?? 10

                            if countdownSeconds == 0 {
                                workoutState = .active
                            } else {
                                workoutState = .countdown
                            }

                            prepareCurrentSet()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Countdown Functions

    private func startCountdown() {
        guard countdownSeconds > 0 else {
            workoutState = .active
            return
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.countdownSeconds > 1 {
                    self.countdownSeconds -= 1
                } else {
                    self.stopCountdown()
                    self.workoutState = .active
                }
            }
        }
    }

    private func skipCountdown() {
        stopCountdown()
        workoutState = .active
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Actions

    private func completeCurrentSet() {
        guard let set = session.currentSet else { return }

        // Create performance record
        let performance = SetPerformance(
            blockIndex: session.currentBlockIndex,
            exerciseIndex: session.currentExerciseIndex,
            setIndex: session.currentSetIndex,
            round: session.currentRound,
            actualReps: Int(inputReps),
            actualWeight: Double(inputWeight),
            actualDuration: set.setType == .duration ? inputDuration : nil,
            notes: inputNotes.isEmpty ? nil : inputNotes,
            rpe: inputRPE
        )

        // Save performance
        session.completeCurrentSet(performance: performance)

        // Check if we're about to finish the current block (for inter-block rest)
        let willChangeBlock = checkIfFinishingCurrentBlock()
        let previousBlock = session.currentBlock

        // Move to next set
        session.moveToNextSet()

        // Auto-start rest timer based on workout structure
        if willChangeBlock, let block = previousBlock, let recoveryTime = block.recoveryAfterBlock, recoveryTime > 0 {
            // Rest tra blocchi (priorità massima)
            timerManager.startRestTimer(restDuration: recoveryTime)
        } else {
            // Rest normale tra serie
            startRestTimerIfNeeded()
        }

        // Reset input fields
        prepareCurrentSet()

        // Save session
        saveSession()

        // Check if workout is completed
        if session.isCompleted {
            completeWorkout()
        }
    }

    /// Verifica se il prossimo moveToNextSet() cambierà blocco
    private func checkIfFinishingCurrentBlock() -> Bool {
        guard let block = session.currentBlock,
              let exercise = session.currentExercise else {
            return false
        }

        // Siamo all'ultima serie dell'ultimo esercizio del blocco?
        let isLastSet = session.currentSetIndex >= (exercise.sets.count - 1)
        let isLastExercise = session.currentExerciseIndex >= (block.exerciseItems.count - 1)

        return isLastSet && isLastExercise
    }

    /// Avvia automaticamente il timer di rest in base alla struttura dell'allenamento
    private func startRestTimerIfNeeded() {
        guard autoStartRest, !session.isCompleted else { return }
        guard let block = session.currentBlock else { return }

        var restDuration: TimeInterval?

        if block.blockType == .method {
            // SUPERSET/TRISET/GIANT SET: Rest solo dopo l'ultimo esercizio
            // Verifica se siamo all'ultimo esercizio del set
            let isLastExerciseInSet = session.currentExerciseIndex == 0 && session.currentSetIndex > 0

            if isLastExerciseInSet {
                // Abbiamo completato un giro completo, avvia rest
                restDuration = block.globalRestTime
            }
            // Altrimenti passa al prossimo esercizio senza rest
        } else {
            // ESERCIZIO SINGOLO: Rest dopo ogni serie
            if let exerciseItem = session.currentExercise {
                restDuration = exerciseItem.restTime
            }
        }

        // Avvia timer se c'è un tempo di rest
        if let duration = restDuration, duration > 0 {
            timerManager.startRestTimer(restDuration: duration)
        }
    }

    private func skipCurrentSet() {
        session.moveToNextSet()
        prepareCurrentSet()
        saveSession()

        if session.isCompleted {
            showingCompleteAlert = true
        }
    }

    private func completeWorkout() {
        // Mark session as completed
        session.complete()

        // Create CompletedWorkout
        let completed = CompletedWorkout.fromSession(session)
        modelContext.insert(completed)

        // Delete session
        modelContext.delete(session)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("⚠️ Failed to complete workout: \(error)")
        }
    }

    private func abandonWorkout() {
        let completed = CompletedWorkout.fromSession(session)
        modelContext.insert(completed)
        modelContext.delete(session)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("⚠️ Failed to abandon workout: \(error)")
        }
    }

    private func saveSession() {
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to save session: \(error)")
        }
    }
}

// MARK: - Extensions

extension TimerState {
    var description: String {
        switch self {
        case .idle: return "Inattivo"
        case .running: return "In corso"
        case .paused: return "In pausa"
        case .completed: return "Completato"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkoutCard.self, WorkoutSession.self,
        configurations: config
    )

    // Create preview data
    let card = WorkoutCard(name: "Test Workout")
    let session = WorkoutSession(workoutCard: card)

    container.mainContext.insert(session)

    return NavigationStack {
        ActiveWorkoutView(session: session)
            .modelContainer(container)
    }
}
