import SwiftUI
import SwiftData
import Combine
import Observation
import AVFoundation

// MARK: - View Model

@MainActor
final class WorkoutExecutionViewModel: ObservableObject {
    enum TimerSound: String, CaseIterable, Identifiable {
        case classic
        case soft
        case pulse
        case mute

        struct Tone {
            let frequency: Double
            let duration: TimeInterval
        }

        var id: String { rawValue }

        var localizationKey: String {
            switch self {
            case .classic: return "timer.sound.option.classic"
            case .soft: return "timer.sound.option.soft"
            case .pulse: return "timer.sound.option.pulse"
            case .mute: return "timer.sound.option.mute"
            }
        }

        var iconName: String {
            switch self {
            case .classic: return "speaker.wave.2"
            case .soft: return "bell"
            case .pulse: return "waveform.path"
            case .mute: return "speaker.slash"
            }
        }

        func tone(for event: MotivationEngine.Event) -> Tone? {
            guard self != .mute else { return nil }
            switch (self, event) {
            case (.classic, .rest):
                return Tone(frequency: 440, duration: 0.20)
            case (.classic, _):
                return Tone(frequency: 880, duration: 0.35)
            case (.soft, .rest):
                return Tone(frequency: 523.25, duration: 0.25)
            case (.soft, _):
                return Tone(frequency: 659.25, duration: 0.35)
            case (.pulse, .rest):
                return Tone(frequency: 350, duration: 0.18)
            case (.pulse, _):
                return Tone(frequency: 1100, duration: 0.22)
            case (.mute, _):
                return nil
            }
        }
    }

    private enum Preferences {
        static let selectedSoundKey = "timer.selectedSound"
        static let volumeKey = "timer.soundVolume"
    }
    struct Step: Identifiable {
        enum StepType: Equatable {
            case timed(duration: TimeInterval, isRest: Bool)
            case reps(totalSets: Int, repsPerSet: Int)
        }

        let id = UUID()
        let title: String
        let subtitle: String
        let zone: HeartRateZone
        let estimatedDuration: TimeInterval
        let type: StepType
        let highlight: String
    }

    @Published private(set) var steps: [Step]
    @Published private(set) var currentStepIndex: Int
    @Published private(set) var generalElapsedTime: TimeInterval = 0
    @Published private(set) var stepElapsedTime: TimeInterval = 0
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isWorkoutCompleted: Bool = false
    @Published private(set) var currentHeartRateZone: HeartRateZone?
    @Published private var zoneDurations: [HeartRateZone: TimeInterval] = [:]
    @Published private(set) var isCountdownActive: Bool = false
    @Published private(set) var countdownRemainingSeconds: Int = 0
    @Published private(set) var isSessionActive: Bool = false
    @Published private(set) var sessionTitle: String = "Allenamento"
    @Published private(set) var activeCard: WorkoutCard?
    @Published private(set) var encouragementMessage: String
    @Published private(set) var selectedSound: TimerSound
    @Published private(set) var soundVolume: Double

    // Inputs for reps-based work
    @Published var completedSets: Int = 0
    @Published var loadText: String = ""
    @Published var perceivedExertion: Double = 7
    @Published var actualRepsText: String = ""

    private var timerCancellable: AnyCancellable?
    private let userDefaults: UserDefaults
    private let motivationEngine: MotivationEngine
    private var audioPlayer: AVAudioPlayer?

    init(
        steps: [Step] = [],
        userDefaults: UserDefaults = .standard,
        motivationEngine: MotivationEngine = MotivationEngine()
    ) {
        self.userDefaults = userDefaults
        self.motivationEngine = motivationEngine
        self.steps = steps
        self.currentStepIndex = 0
        self.currentHeartRateZone = nil
        if let savedSound = userDefaults.string(forKey: Preferences.selectedSoundKey),
           let storedSound = TimerSound(rawValue: savedSound) {
            selectedSound = storedSound
        } else {
            selectedSound = .classic
        }

        if userDefaults.object(forKey: Preferences.volumeKey) != nil {
            soundVolume = userDefaults.double(forKey: Preferences.volumeKey)
        } else {
            soundVolume = 0.8
        }

        encouragementMessage = motivationEngine.defaultMessage
        if !steps.isEmpty {
            isSessionActive = true
            sessionTitle = "Allenamento Demo"
        }
        startTimer()
        updateMotivation(for: currentStep)
    }

    deinit {
        timerCancellable?.cancel()
    }

    var currentStep: Step? {
        guard steps.indices.contains(currentStepIndex) else { return nil }
        return steps[currentStepIndex]
    }

    var totalEstimatedDuration: TimeInterval {
        steps.reduce(0) { $0 + $1.estimatedDuration }
    }

    var zoneUsagePercentages: [HeartRateZone: Double] {
        let total = zoneDurations.values.reduce(0, +)
        guard total > 0 else {
            return HeartRateZone.allCases.reduce(into: [:]) { result, zone in
                result[zone] = 0
            }
        }

        return HeartRateZone.allCases.reduce(into: [:]) { result, zone in
            let zoneSeconds = zoneDurations[zone, default: 0]
            result[zone] = zoneSeconds / total
        }
    }

    var stepProgress: Double {
        guard let step = currentStep else { return 0 }
        switch step.type {
        case let .timed(duration, _):
            guard duration > 0 else { return 1 }
            return min(stepElapsedTime / duration, 1)
        case let .reps(totalSets, _):
            guard totalSets > 0 else { return 1 }
            return min(Double(completedSets) / Double(totalSets), 1)
        }
    }

    var remainingTimeForCurrentStep: TimeInterval {
        guard let step = currentStep else { return 0 }
        switch step.type {
        case let .timed(duration, _):
            return max(duration - stepElapsedTime, 0)
        case .reps:
            return 0
        }
    }

    func togglePause() {
        guard isSessionActive, !isCountdownActive else { return }
        isPaused.toggle()
    }

    func skipToNextStep() {
        guard !steps.isEmpty else { return }
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            resetStepState()
        } else {
            completeWorkout()
        }
    }

    func goToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        resetStepState(resetCounters: true)
    }

    func confirmSet() {
        advanceSet()
    }

    func skipCurrentSet() {
        advanceSet()
    }

    private func advanceSet() {
        guard let step = currentStep else { return }
        if case let .reps(totalSets, _) = step.type {
            if completedSets < totalSets {
                completedSets += 1
            }

            if completedSets >= totalSets {
                skipToNextStep()
            } else {
                prepareForNextSet()
            }
        }
    }

    func start(card: WorkoutCard, countdownSeconds: Int) {
        steps = WorkoutExecutionStepFactory.steps(for: card)
        currentStepIndex = 0
        generalElapsedTime = 0
        stepElapsedTime = 0
        zoneDurations = [:]
        completedSets = 0
        loadText = ""
        actualRepsText = ""
        perceivedExertion = 7
        isWorkoutCompleted = false
        isPaused = false
        currentHeartRateZone = nil
        sessionTitle = card.name
        activeCard = card
        isSessionActive = true
        countdownRemainingSeconds = countdownSeconds
        isCountdownActive = countdownSeconds > 0

        if !isCountdownActive {
            resetStepState()
        }
    }

    func resetSession() {
        steps = []
        currentStepIndex = 0
        generalElapsedTime = 0
        stepElapsedTime = 0
        completedSets = 0
        loadText = ""
        actualRepsText = ""
        perceivedExertion = 7
        isPaused = false
        isWorkoutCompleted = false
        isCountdownActive = false
        countdownRemainingSeconds = 0
        isSessionActive = false
        sessionTitle = "Allenamento"
        zoneDurations = [:]
        activeCard = nil
        encouragementMessage = motivationEngine.defaultMessage
    }

    func skipCountdown() {
        guard isCountdownActive else { return }
        isCountdownActive = false
        resetStepState()
    }

    func updateHeartRateZone(_ zone: HeartRateZone?) {
        currentHeartRateZone = zone
    }

    private func completeWorkout() {
        isWorkoutCompleted = true
        isPaused = true
    }

    private func resetStepState(resetCounters: Bool = false) {
        stepElapsedTime = 0
        completedSets = 0
        loadText = ""
        perceivedExertion = 7
        actualRepsText = repsTextForCurrentStep()
        updateMotivation(for: currentStep)
    }

    private func prepareForNextSet() {
        loadText = ""
        actualRepsText = repsTextForCurrentStep()
        applyMotivation(event: .set)
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleTick()
            }
    }

    private func handleTick() {
        if isCountdownActive {
            guard countdownRemainingSeconds > 0 else { return }
            countdownRemainingSeconds -= 1
            if countdownRemainingSeconds == 0 {
                isCountdownActive = false
                resetStepState()
            }
            return
        }

        guard isSessionActive, !isPaused, !isWorkoutCompleted, currentStep != nil else { return }
        generalElapsedTime += 1

        if let currentHeartRateZone {
            zoneDurations[currentHeartRateZone, default: 0] += 1
        }

        switch currentStep?.type {
        case let .timed(duration, _):
            stepElapsedTime += 1
            if stepElapsedTime >= duration {
                skipToNextStep()
            }
        case .reps:
            break
        case .none:
            break
        }
    }

    private func repsTextForCurrentStep() -> String {
        guard let currentStep else { return "" }
        switch currentStep.type {
        case let .reps(_, repsPerSet):
            return String(repsPerSet)
        case .timed:
            return ""
        }
    }

    func updateSelectedSound(_ sound: TimerSound) {
        guard selectedSound != sound else { return }
        selectedSound = sound
        userDefaults.set(sound.rawValue, forKey: Preferences.selectedSoundKey)
    }

    func updateSoundVolume(_ volume: Double) {
        let clamped = min(max(volume, 0), 1)
        soundVolume = clamped
        userDefaults.set(clamped, forKey: Preferences.volumeKey)
    }

    private func updateMotivation(for step: Step?) {
        guard let step else {
            encouragementMessage = motivationEngine.defaultMessage
            return
        }

        switch step.type {
        case let .timed(_, isRest):
            applyMotivation(event: isRest ? .rest : .work)
        case .reps:
            applyMotivation(event: .set)
        }
    }

    private func applyMotivation(event: MotivationEngine.Event) {
        encouragementMessage = motivationEngine.message(for: event)
        playSound(for: event)
    }

    private func playSound(for event: MotivationEngine.Event) {
        guard soundVolume > 0, let tone = selectedSound.tone(for: event) else { return }
        let toneData = TimerToneGenerator.makeToneData(frequency: tone.frequency, duration: tone.duration)
        guard !toneData.isEmpty else { return }

        do {
            audioPlayer = try AVAudioPlayer(data: toneData)
            audioPlayer?.volume = Float(soundVolume)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play timer tone", error)
        }
    }
}

extension WorkoutExecutionViewModel {
    static func demo() -> WorkoutExecutionViewModel {
        let steps: [Step] = [
            Step(
                title: "Riscaldamento Bike",
                subtitle: "Cadenza agile 5'",
                zone: .zone2,
                estimatedDuration: 300,
                type: .timed(duration: 300, isRest: false),
                highlight: "Cuore pronto"
            ),
            Step(
                title: "Panca Piana",
                subtitle: "3x10 @ 50kg",
                zone: .zone3,
                estimatedDuration: 420,
                type: .reps(totalSets: 3, repsPerSet: 10),
                highlight: "Stabilità massima"
            ),
            Step(
                title: "Recupero",
                subtitle: "90s di pausa",
                zone: .zone1,
                estimatedDuration: 90,
                type: .timed(duration: 90, isRest: true),
                highlight: "Respira e reset"
            )
        ]

        let viewModel = WorkoutExecutionViewModel(steps: steps)
        viewModel.isSessionActive = true
        viewModel.sessionTitle = "Scheda Demo"
        return viewModel
    }
}

// MARK: - View

struct WorkoutExecutionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: WorkoutExecutionViewModel
    @Bindable private var bluetoothManager: BluetoothHeartRateManager
    @Query(sort: \WorkoutCard.name) private var workoutCards: [WorkoutCard]
    @Query private var profiles: [UserProfile]
    @AppStorage("workoutCountdownSeconds") private var defaultCountdownSeconds = 10
    @State private var isCompletionSheetPresented = false
    @State private var isHistoryPresented = false
    @State private var completionNotes: String = ""
    @State private var selectedMood: WorkoutMood = .neutral
    @State private var includeRPE = false
    @State private var completionRPE: Double = 7
    @State private var isSaveErrorAlertPresented = false
    @State private var saveErrorMessage: String?

    init(
        viewModel: WorkoutExecutionViewModel = WorkoutExecutionViewModel(),
        bluetoothManager: BluetoothHeartRateManager = BluetoothHeartRateManager()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.bluetoothManager = bluetoothManager
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSessionActive {
                    ZStack {
                        ScrollView {
                            VStack(spacing: 24) {
                                headerSection
                                heartRateSection
                                currentStepSection
                                soundControlsSection
                                upcomingSection
                            }
                            .padding(24)
                        }
                        .disabled(viewModel.isCountdownActive)

                        countdownOverlay
                    }
                } else {
                    workoutPicker
                }
            }
            .navigationTitle(viewModel.sessionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .onAppear(perform: refreshHeartRateZone)
        .onChange(of: bluetoothManager.currentHeartRate) { _, _ in
            refreshHeartRateZone()
        }
        .onChange(of: profiles) { _, _ in
            refreshHeartRateZone()
        }
        .onChange(of: viewModel.isWorkoutCompleted) { _, isCompleted in
            if isCompleted {
                prepareCompletionSheet()
            }
        }
        .sheet(isPresented: $isCompletionSheetPresented) {
            completionSheet
        }
        .sheet(isPresented: $isHistoryPresented) {
            NavigationStack {
                WorkoutHistoryView()
            }
        }
        .alert("Impossibile salvare l'allenamento", isPresented: $isSaveErrorAlertPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "Si è verificato un errore inatteso. Riprova.")
        }
    }

    private var soundControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(L("timer.sound.title"), systemImage: "speaker.wave.2.fill")
                .font(.headline)

            Menu {
                ForEach(WorkoutExecutionViewModel.TimerSound.allCases) { sound in
                    Button {
                        viewModel.updateSelectedSound(sound)
                    } label: {
                        Label {
                            Text(localized: sound.localizationKey)
                        } icon: {
                            Image(systemName: sound == viewModel.selectedSound ? "checkmark" : sound.iconName)
                        }
                    }
                    .disabled(sound == viewModel.selectedSound)
                }
            } label: {
                HStack {
                    Label {
                        Text(localized: viewModel.selectedSound.localizationKey)
                    } icon: {
                        Image(systemName: "music.note.list")
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localized: "timer.sound.volume")
                    Spacer()
                    Text(String(format: "%.0f%%", viewModel.soundVolume * 100))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { viewModel.soundVolume },
                        set: { viewModel.updateSoundVolume($0) }
                    ),
                    in: 0...1
                )
                .disabled(viewModel.selectedSound == .mute)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                isHistoryPresented = true
            } label: {
                Label("Storico", systemImage: "clock.arrow.circlepath")
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Storico allenamenti")

            if viewModel.isSessionActive {
                Button("Termina") {
                    viewModel.resetSession()
                }
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if viewModel.isSessionActive {
                Button(action: viewModel.goToPreviousStep) {
                    Label("Indietro", systemImage: "backward.fill")
                }
                .disabled(viewModel.currentStepIndex == 0)

                Button(action: viewModel.skipToNextStep) {
                    Label("Avanti", systemImage: "forward.fill")
                }
                .disabled(viewModel.isWorkoutCompleted)
            }
        }
    }

    private var workoutPicker: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Seleziona una scheda per iniziare")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 16)

                if workoutCards.isEmpty {
                    ContentUnavailableView {
                        Label("Nessuna scheda disponibile", systemImage: "doc.text")
                    } description: {
                        Text("Crea una scheda nella tab Schede per farla comparire qui")
                    }
                    .padding()
                } else {
                    ForEach(workoutCards) { card in
                        workoutCardButton(for: card)
                    }
                }
            }
            .padding(24)
        }
    }

    private func workoutCardButton(for card: WorkoutCard) -> some View {
        let scriptLines = WorkoutDebugLogBuilder.buildLog(for: card.blocks)
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.headline)
                    if let description = card.cardDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Durata stimata")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(card.estimatedDurationMinutes) min")
                        .font(.body)
                        .bold()
                }
            }

            if !scriptLines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(scriptLines.prefix(3), id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if scriptLines.count > 3 {
                        Text("…")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Button {
                viewModel.start(card: card, countdownSeconds: defaultCountdownSeconds)
            } label: {
                Label("Avvia con countdown di \(defaultCountdownSeconds)s", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Label("Durata Totale", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Text(format(seconds: viewModel.generalElapsedTime))
                    .font(.system(.title2, design: .rounded))
                    .monospacedDigit()
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Nome esercizio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.currentStep?.title ?? "In attesa")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(viewModel.currentStep?.subtitle ?? "Seleziona una scheda per iniziare")
                    .foregroundStyle(.secondary)
                Text(viewModel.encouragementMessage)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            HStack {
                Label("Tempo stimato scheda", systemImage: "hourglass")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(seconds: viewModel.totalEstimatedDuration))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(action: viewModel.togglePause) {
                Label(viewModel.isPaused ? "Riprendi" : "Metti in pausa", systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isSessionActive || viewModel.isCountdownActive || viewModel.isWorkoutCompleted)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .scaleEffect(1.1)
                    Text(heartRateText)
                        .font(.headline)
                        .contentTransition(.numericText())
                }
                Spacer()
                Text(activeZoneLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HeartRateHistogram(currentZone: activeHeartRateZone, usagePercentages: viewModel.zoneUsagePercentages)
                .frame(height: 140)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var currentStepSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fase corrente")
                .font(.headline)

            if let step = viewModel.currentStep, !viewModel.isCountdownActive {
                switch step.type {
                case let .timed(_, isRest):
                    timedStepView(step: step, isRest: isRest)
                case let .reps(totalSets, repsPerSet):
                    repsStepView(step: step, totalSets: totalSets, repsPerSet: repsPerSet)
                }
            } else if viewModel.isCountdownActive {
                Text("Il countdown è attivo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if viewModel.isWorkoutCompleted {
                Label("Allenamento completato", systemImage: "checkmark.seal.fill")
                    .font(.title3)
            } else {
                Text("Nessuna fase disponibile")
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func timedStepView(step: WorkoutExecutionViewModel.Step, isRest: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(isRest ? "Pausa" : "Timer esercizio", systemImage: isRest ? "moon.zzz.fill" : "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(isRest ? .blue : .orange)
                Spacer()
                Text(format(seconds: viewModel.remainingTimeForCurrentStep))
                    .font(.system(.title3, design: .rounded))
                    .monospacedDigit()
            }

            Text(step.highlight)
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: viewModel.stepProgress)
                .tint(isRest ? .blue : .orange)

            HStack {
                Button(action: viewModel.togglePause) {
                    Label(viewModel.isPaused ? "Riprendi" : "Pausa", systemImage: viewModel.isPaused ? "play" : "pause")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: viewModel.skipToNextStep) {
                    Label("Salta", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func repsStepView(step: WorkoutExecutionViewModel.Step, totalSets: Int, repsPerSet: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Serie \(min(viewModel.completedSets + 1, totalSets)) di \(totalSets)")
                    .font(.title3)
                    .bold()
                Text("Ripetizioni suggerite: \(repsPerSet)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(step.highlight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: viewModel.stepProgress)
                .tint(.green)

            VStack(alignment: .leading, spacing: 8) {
                Text("Carico effettivo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Kg", text: $viewModel.loadText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ripetizioni completate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Ripetizioni", text: $viewModel.actualRepsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RPE")
                    Spacer()
                    Text(String(format: "%.0f", viewModel.perceivedExertion))
                        .font(.subheadline)
                        .bold()
                }
                Slider(value: $viewModel.perceivedExertion, in: 1...10, step: 1)
            }

            Button(action: viewModel.confirmSet) {
                Label("Conferma serie", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.completedSets >= totalSets)

            Button(role: .cancel, action: viewModel.skipCurrentSet) {
                Label("Salta serie", systemImage: "forward.end.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.completedSets >= totalSets)
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fasi successive")
                    .font(.headline)
                Spacer()
                Text("\(max(stepsRemaining, 0)) step")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if upcomingSteps.isEmpty {
                Text("Hai quasi finito! 🎉")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(upcomingSteps) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(step.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var upcomingSteps: ArraySlice<WorkoutExecutionViewModel.Step> {
        guard viewModel.currentStepIndex < viewModel.steps.count else { return [] }
        let start = viewModel.currentStepIndex + 1
        guard start < viewModel.steps.count else { return [] }
        let end = min(start + 3, viewModel.steps.count)
        return viewModel.steps[start..<end]
    }

    private var stepsRemaining: Int {
        max(viewModel.steps.count - (viewModel.currentStepIndex + 1), 0)
    }

    private var userProfile: UserProfile? { profiles.first }

    private var activeHeartRateZone: HeartRateZone? {
        heartRateZone(for: bluetoothManager.currentHeartRate)
    }

    private var activeZoneLabel: String {
        if let zone = activeHeartRateZone {
            return zone.name
        }

        if let targetZone = viewModel.currentStep?.zone {
            return "Target: \(targetZone.name)"
        }

        return "Zone cardio"
    }

    private var heartRateText: String {
        if bluetoothManager.isConnected {
            let bpm = bluetoothManager.currentHeartRate
            return bpm > 0 ? "\(bpm) bpm" : "Segnale in arrivo"
        } else {
            return "Collega sensore"
        }
    }

    private func heartRateZone(for bpm: Int) -> HeartRateZone? {
        guard bpm > 0 else { return nil }

        if let profile = userProfile {
            if bpm <= profile.zone1Max { return .zone1 }
            if bpm <= profile.zone2Max { return .zone2 }
            if bpm <= profile.zone3Max { return .zone3 }
            if bpm <= profile.zone4Max { return .zone4 }
            return .zone5
        }

        let estimatedMaxHR = 190
        let ratio = Double(bpm) / Double(estimatedMaxHR)

        for zone in HeartRateZone.allCases {
            if ratio <= zone.percentage.max {
                return zone
            }
        }

        return .zone5
    }

    private func refreshHeartRateZone() {
        viewModel.updateHeartRateZone(activeHeartRateZone)
    }

    private func prepareCompletionSheet() {
        completionNotes = ""
        selectedMood = .neutral
        includeRPE = false
        completionRPE = 7
        isCompletionSheetPresented = true
    }

    private func saveWorkoutLog() {
        let trimmedNotes = completionNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let rpeValue = includeRPE ? Int(completionRPE.rounded()) : nil
        let log = WorkoutSessionLog(
            card: viewModel.activeCard,
            cardName: viewModel.activeCard?.name ?? viewModel.sessionTitle,
            notes: trimmedNotes,
            mood: selectedMood,
            rpe: rpeValue,
            durationSeconds: viewModel.generalElapsedTime
        )
        modelContext.insert(log)
        do {
            try modelContext.save()
            dismissCompletionSheet()
        } catch {
            modelContext.delete(log)
            saveErrorMessage = error.localizedDescription
            isSaveErrorAlertPresented = true
            print("Failed to save workout log", error)
        }
    }

    private func dismissCompletionSheet(resetSession: Bool = true) {
        isCompletionSheetPresented = false
        if resetSession {
            viewModel.resetSession()
        }
    }

    private func discardWorkoutLog() {
        dismissCompletionSheet(resetSession: true)
    }

    private var completionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        completionSummarySection
                        moodSelectionSection
                        notesSection
                        rpeSection
                    }
                    .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button {
                        saveWorkoutLog()
                    } label: {
                        Label("Salva allenamento", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        discardWorkoutLog()
                    } label: {
                        Label("Scarta", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Fine allenamento")
        }
        .interactiveDismissDisabled()
        .presentationDetents([.medium, .large])
    }

    private var completionSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.activeCard?.name ?? viewModel.sessionTitle)
                .font(.title3)
                .fontWeight(.semibold)
            Label("Durata", systemImage: "clock")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(format(seconds: viewModel.generalElapsedTime))
                .font(.system(.title, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Come ti senti?")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                ForEach(WorkoutMood.allCases) { mood in
                    Button {
                        selectedMood = mood
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 32))
                            Text(mood.title)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedMood == mood ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedMood == mood ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $completionNotes)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                if completionNotes.isEmpty {
                    Text("Annota sensazioni, focus o modifiche")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Aggiungi RPE", isOn: $includeRPE.animation())
            if includeRPE {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $completionRPE, in: 1...10, step: 1)
                    Text("RPE: \(Int(completionRPE))")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var countdownOverlay: some View {
        if viewModel.isCountdownActive {
            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Countdown")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(viewModel.countdownRemainingSeconds)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("Preparati a iniziare l'allenamento")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    Button(action: viewModel.skipCountdown) {
                        Text("Salta countdown")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .transition(.opacity)
        }
    }

    private func format(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: seconds) ?? "00:00"
    }

}

@MainActor
struct MotivationEngine {
    enum Event {
        case work
        case rest
        case set
    }

    private let defaultKey = "motivation.default"
    private let workKeys = ["motivation.work.1", "motivation.work.2", "motivation.work.3"]
    private let restKeys = ["motivation.rest.1", "motivation.rest.2", "motivation.rest.3"]
    private let setKeys = ["motivation.set.1", "motivation.set.2", "motivation.set.3"]

    var defaultMessage: String { L(defaultKey) }

    func message(for event: Event) -> String {
        let keys: [String]
        switch event {
        case .work: keys = workKeys
        case .rest: keys = restKeys
        case .set: keys = setKeys
        }

        let localized = keys
            .map { L($0) }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return localized.randomElement() ?? defaultMessage
    }
}

private enum TimerToneGenerator {
    static func makeToneData(frequency: Double, duration: TimeInterval, sampleRate: Double = 44100) -> Data {
        guard frequency > 0, duration > 0 else { return Data() }
        let sampleCount = Int(sampleRate * duration)
        guard sampleCount > 0 else { return Data() }

        var sampleData = Data(capacity: sampleCount * MemoryLayout<Int16>.size)
        for index in 0..<sampleCount {
            let sample = sin(2 * .pi * frequency * Double(index) / sampleRate)
            var value = Int16(sample * Double(Int16.max))
            withUnsafeBytes(of: &value) { buffer in
                sampleData.append(contentsOf: buffer)
            }
        }

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        var chunkSize = UInt32(36 + sampleData.count).littleEndian
        data.append(Data(bytes: &chunkSize, count: 4))
        data.append(contentsOf: "WAVEfmt ".utf8)
        var subchunk1Size: UInt32 = 16
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: UInt16 = 1
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: UInt16 = 1
        data.append(Data(bytes: &numChannels, count: 2))
        var sampleRateUInt: UInt32 = UInt32(sampleRate)
        data.append(Data(bytes: &sampleRateUInt, count: 4))
        var byteRate: UInt32 = sampleRateUInt * UInt32(numChannels) * UInt32(2)
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: UInt16 = numChannels * 2
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: UInt16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))
        data.append(contentsOf: "data".utf8)
        var subchunk2Size = UInt32(sampleData.count).littleEndian
        data.append(Data(bytes: &subchunk2Size, count: 4))
        data.append(sampleData)

        return data
    }
}

// MARK: - Histogram Component

private struct HeartRateHistogram: View {
    let currentZone: HeartRateZone?
    let usagePercentages: [HeartRateZone: Double]
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(HeartRateZone.allCases, id: \.self) { zone in
                    let isActive = zone == currentZone

                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(zone.color.opacity(isActive ? 0.9 : 0.25))
                            .frame(height: barHeight(for: zone, totalHeight: proxy.size.height - 20))
                            .scaleEffect(isActive ? (pulse ? 1.05 : 0.95) : 1, anchor: .bottom)
                            .shadow(color: isActive ? zone.color.opacity(0.35) : .clear, radius: isActive ? 12 : 0, y: isActive ? 6 : 0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(zone.color.opacity(isActive ? 0.9 : 0.5), lineWidth: isActive ? 3 : 1)
                            )

                        Text("Z\(zone.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(isActive ? zone.color : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear(perform: startPulseIfNeeded)
        .onChange(of: currentZone?.rawValue ?? -1) { _, _ in
            startPulseIfNeeded()
        }
    }

    private func barHeight(for zone: HeartRateZone, totalHeight: CGFloat) -> CGFloat {
        let percentage = usagePercentages[zone] ?? 0
        return max(totalHeight * CGFloat(percentage), 6)
    }

    private func startPulseIfNeeded() {
        guard currentZone != nil else {
            pulse = false
            return
        }

        pulse = false
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}

// MARK: - Step Factory

private enum WorkoutExecutionStepFactory {
    static func steps(for card: WorkoutCard) -> [WorkoutExecutionViewModel.Step] {
        var result: [WorkoutExecutionViewModel.Step] = []
        let orderedBlocks = card.blocks.sorted { $0.order < $1.order }

        for block in orderedBlocks {
            switch block.blockType {
            case .rest:
                let restDuration = block.globalRestTime ?? 0
                let subtitle = block.notes ?? (restDuration > 0 ? "Recupero \(formatDuration(restDuration))" : "Recupero libero")
                result.append(
                    WorkoutExecutionViewModel.Step(
                        title: "Pausa", 
                        subtitle: subtitle,
                        zone: .zone1,
                        estimatedDuration: restDuration,
                        type: .timed(duration: restDuration, isRest: true),
                        highlight: "Respira profondamente"
                    )
                )
            case .simple, .method:
                result.append(contentsOf: stepsForExercises(in: block))
            }
        }

        return result
    }

    private static func stepsForExercises(in block: WorkoutBlock) -> [WorkoutExecutionViewModel.Step] {
        var steps: [WorkoutExecutionViewModel.Step] = []
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }

        for exercise in exercises {
            let sets = exercise.sets.sorted { $0.order < $1.order }
            guard let firstSet = sets.first else { continue }

            let title = exercise.exercise?.name ?? "Esercizio"
            let subtitle = exercise.notes ?? setDescription(for: firstSet, totalSets: sets.count, restTime: exercise.restTime ?? block.globalRestTime)
            let highlight = exercise.targetExpression?.rawValue ?? "Focus sulla tecnica"

            switch firstSet.setType {
            case .duration:
                let duration = max(firstSet.duration ?? 30, 10)
                steps.append(
                    WorkoutExecutionViewModel.Step(
                        title: title,
                        subtitle: subtitle,
                        zone: .zone3,
                        estimatedDuration: duration,
                        type: .timed(duration: duration, isRest: false),
                        highlight: highlight
                    )
                )
            case .reps:
                let reps = max(firstSet.reps ?? 8, 1)
                steps.append(
                    WorkoutExecutionViewModel.Step(
                        title: title,
                        subtitle: subtitle,
                        zone: .zone4,
                        estimatedDuration: TimeInterval(reps * max(sets.count, 1)),
                        type: .reps(totalSets: max(sets.count, 1), repsPerSet: reps),
                        highlight: highlight
                    )
                )
            }
        }

        return steps
    }

    private static func setDescription(for set: WorkoutSet, totalSets: Int, restTime: TimeInterval?) -> String {
        var parts: [String] = []

        if totalSets > 0 {
            parts.append("\(totalSets)x")
        }

        switch set.setType {
        case .reps:
            if let reps = set.reps {
                parts.append("\(reps) reps")
            }
        case .duration:
            if let duration = set.duration {
                parts.append(formatDuration(duration))
            }
        }

        if let weight = set.weight {
            parts.append(String(format: "@ %.0f kg", weight))
        } else if let percentage = set.percentageOfMax {
            parts.append(String(format: "@ %.0f%% 1RM", percentage))
        }

        if let restTime {
            parts.append("Rec. \(formatDuration(restTime))")
        }

        return parts.joined(separator: " • ")
    }

    private static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    WorkoutExecutionView(viewModel: .demo(), bluetoothManager: BluetoothHeartRateManager())
        .modelContainer(for: [WorkoutCard.self, UserProfile.self], inMemory: true)
}
