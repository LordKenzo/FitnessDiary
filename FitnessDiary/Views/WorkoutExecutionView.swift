import SwiftUI
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
    }

    @Published private(set) var steps: [Step]
    @Published private(set) var currentStepIndex: Int
    @Published private(set) var generalElapsedTime: TimeInterval = 0
    @Published private(set) var stepElapsedTime: TimeInterval = 0
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isWorkoutCompleted: Bool = false
    @Published private(set) var currentZone: HeartRateZone
    @Published private var zoneDurations: [HeartRateZone: TimeInterval] = [:]

    // Inputs for reps-based work
    @Published var completedSets: Int = 0
    @Published var loadText: String = ""
    @Published var perceivedExertion: Double = 7

    private var timerCancellable: AnyCancellable?

    init(steps: [Step]) {
        self.steps = steps
        self.currentStepIndex = 0
        self.currentZone = steps.first?.zone ?? .zone1
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

    func togglePause() {
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
        guard let step = currentStep else { return }
        if case let .reps(totalSets, _) = step.type {
            if completedSets < totalSets {
                completedSets += 1
            }

            if completedSets >= totalSets {
                skipToNextStep()
            }
        }
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
        } else {
            completedSets = 0
        }
        loadText = ""
        perceivedExertion = 7
        if let currentStep {
            currentZone = currentStep.zone
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleTick()
            }
    }

    private func handleTick() {
        guard !isPaused, !isWorkoutCompleted, currentStep != nil else { return }
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
}

extension WorkoutExecutionViewModel {
    static func demo() -> WorkoutExecutionViewModel {
        let steps: [Step] = [
            Step(
                title: "Countdown iniziale",
                subtitle: "Respira e preparati",
                zone: .zone1,
                estimatedDuration: 30,
                type: .timed(duration: 30, isRest: true)
            ),
            Step(
                title: "Riscaldamento Bike",
                subtitle: "Cadenza agile",
                zone: .zone2,
                estimatedDuration: 300,
                type: .timed(duration: 300, isRest: false)
            ),
            Step(
                title: "Panca Piana",
                subtitle: "3x10 @ 50kg",
                zone: .zone3,
                estimatedDuration: 420,
                type: .reps(totalSets: 3, repsPerSet: 10)
            ),
            Step(
                title: "Recupero",
                subtitle: "Respira profondamente",
                zone: .zone1,
                estimatedDuration: 90,
                type: .timed(duration: 90, isRest: true)
            ),
            Step(
                title: "Rematore Bilanciere",
                subtitle: "4x8 @ 60kg",
                zone: .zone4,
                estimatedDuration: 480,
                type: .reps(totalSets: 4, repsPerSet: 8)
            ),
            Step(
                title: "Defaticamento",
                subtitle: "Camminata sul tapis roulant",
                zone: .zone2,
                estimatedDuration: 240,
                type: .timed(duration: 240, isRest: false)
            )
        ]

        return WorkoutExecutionViewModel(steps: steps)
    }
}

// MARK: - View

struct WorkoutExecutionView: View {
    @StateObject private var viewModel: WorkoutExecutionViewModel

    init(viewModel: WorkoutExecutionViewModel = WorkoutExecutionViewModel.demo()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    heartRateSection
                    currentStepSection
                    upcomingSection
                }
                .padding(24)
            }
            .navigationTitle("Allenamento Live")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: viewModel.goToPreviousStep) {
                        Label("Indietro", systemImage: "backward.fill")
                    }
                    .disabled(viewModel.currentStepIndex == 0)

                    Button(action: viewModel.skipToNextStep) {
                        Label("Avanti", systemImage: "forward.fill")
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Label("Timer", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Text(format(seconds: viewModel.generalElapsedTime))
                    .font(.system(.title2, design: .rounded))
                    .monospacedDigit()
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentStep?.title ?? "Nessun esercizio")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(viewModel.currentStep?.subtitle ?? "")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Stimato", systemImage: "hourglass")
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
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Zone Cardio", systemImage: "heart.fill")
                    .font(.headline)
                Spacer()
                Text(viewModel.currentZone.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HeartRateHistogram(currentZone: viewModel.currentZone, usagePercentages: viewModel.zoneUsagePercentages)
                .frame(height: 140)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var currentStepSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fase corrente")
                .font(.headline)

            if let step = viewModel.currentStep {
                switch step.type {
                case let .timed(_, isRest):
                    timedStepView(step: step, isRest: isRest)
                case let .reps(totalSets, repsPerSet):
                    repsStepView(step: step, totalSets: totalSets, repsPerSet: repsPerSet)
                }
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
                Text("Serie \(viewModel.completedSets) di \(totalSets)")
                    .font(.title3)
                    .bold()
                Text("Ripetizioni suggerite: \(repsPerSet)")
                    .font(.subheadline)
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

#Preview {
    WorkoutExecutionView()
}
