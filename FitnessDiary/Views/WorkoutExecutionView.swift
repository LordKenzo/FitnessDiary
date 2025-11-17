import SwiftUI
import SwiftData
import Combine

// MARK: - View Model

final class WorkoutExecutionViewModel: ObservableObject {
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
    @Published private(set) var currentZone: HeartRateZone
    @Published private var zoneDurations: [HeartRateZone: TimeInterval] = [:]
    @Published private(set) var isCountdownActive: Bool = false
    @Published private(set) var countdownRemainingSeconds: Int = 0
    @Published private(set) var isSessionActive: Bool = false
    @Published private(set) var sessionTitle: String = "Allenamento"

    // Inputs for reps-based work
    @Published var completedSets: Int = 0
    @Published var loadText: String = ""
    @Published var perceivedExertion: Double = 7
    @Published var actualRepsText: String = ""

    private var timerCancellable: AnyCancellable?

    init(steps: [Step] = []) {
        self.steps = steps
        self.currentStepIndex = 0
        self.currentZone = steps.first?.zone ?? .zone1
        if !steps.isEmpty {
            isSessionActive = true
            sessionTitle = "Allenamento Demo"
        }
        startTimer()
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

    var encouragementMessage: String {
        if isCountdownActive {
            return "Respira e preparati a dare il massimo"
        }

        guard let currentStep else {
            return isSessionActive ? "Segui il flusso della scheda" : "Scegli una scheda per iniziare"
        }

        switch currentStep.type {
        case .timed(_, let isRest):
            return isRest ? "Approfitta del recupero" : "Concentrati sul ritmo"
        case .reps:
            return "Tecnica precisa e respiro controllato"
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
        currentZone = steps.first?.zone ?? .zone1
        sessionTitle = card.name
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
        currentZone = .zone1
        zoneDurations = [:]
    }

    func skipCountdown() {
        guard isCountdownActive else { return }
        isCountdownActive = false
        resetStepState()
    }

    func changeZone(to zone: HeartRateZone) {
        currentZone = zone
    }

    private func completeWorkout() {
        isWorkoutCompleted = true
        isPaused = true
        timerCancellable?.cancel()
    }

    private func resetStepState(resetCounters: Bool = false) {
        stepElapsedTime = 0
        if resetCounters {
            completedSets = 0
        }
        loadText = ""
        perceivedExertion = 7
        actualRepsText = repsTextForCurrentStep()
        if let currentStep {
            currentZone = currentStep.zone
        }
    }

    private func prepareForNextSet() {
        loadText = ""
        actualRepsText = repsTextForCurrentStep()
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

        if let currentStep {
            zoneDurations[currentStep.zone, default: 0] += 1
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
    @StateObject private var viewModel: WorkoutExecutionViewModel
    @Query(sort: \WorkoutCard.name) private var workoutCards: [WorkoutCard]
    @AppStorage("workoutCountdownSeconds") private var defaultCountdownSeconds = 10

    init(viewModel: WorkoutExecutionViewModel = WorkoutExecutionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
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
                    Text("Zone Cardio")
                        .font(.headline)
                }
                Spacer()
                Text(viewModel.currentZone.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HeartRateHistogram(currentZone: viewModel.currentZone, usagePercentages: viewModel.zoneUsagePercentages)
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

    private func format(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: seconds) ?? "00:00"
    }

    @ViewBuilder
    private var countdownOverlay: some View {
        if viewModel.isCountdownActive {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .overlay {
                    countdownView
                        .padding(24)
                }
                .transition(.opacity)
        }
    }

    private var countdownView: some View {
        VStack(spacing: 12) {
            Text("Countdown iniziale")
                .font(.headline)
            Text("\(viewModel.countdownRemainingSeconds)s")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("Puoi saltarlo se sei già pronto")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Salta countdown") {
                viewModel.skipCountdown()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Histogram Component

private struct HeartRateHistogram: View {
    let currentZone: HeartRateZone
    let usagePercentages: [HeartRateZone: Double]

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(HeartRateZone.allCases, id: \.self) { zone in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(zone == currentZone ? zone.color.opacity(0.9) : zone.color.opacity(0.25))
                            .frame(height: barHeight(for: zone, totalHeight: proxy.size.height - 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(zone.color, lineWidth: zone == currentZone ? 0 : 2)
                            )

                        Text("Z\(zone.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func barHeight(for zone: HeartRateZone, totalHeight: CGFloat) -> CGFloat {
        let percentage = usagePercentages[zone] ?? 0
        return max(totalHeight * CGFloat(percentage), 6)
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
    WorkoutExecutionView(viewModel: .demo())
}
