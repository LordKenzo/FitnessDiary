import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class WorkoutSessionViewModel {
    struct SetExecutionResult: Identifiable {
        enum LoadFeedback: String, CaseIterable, Identifiable {
            case decrease = "Scarica"
            case keep = "Stesso Carico"
            case increase = "Carica"

            var id: String { rawValue }
            var symbol: String {
                switch self {
                case .decrease: return "arrow.down"
                case .keep: return "equal"
                case .increase: return "arrow.up"
                }
            }
        }

        let id = UUID()
        var setID: UUID
        var confirmedWeight: Double?
        var confirmedPercentage: Double?
        var perceivedEffort: Int = 7
        var feedback: LoadFeedback = .keep
    }

    struct WorkoutSessionSummary {
        enum PhysicalFeeling: String, CaseIterable, Identifiable, Hashable {
            case great = "Ottimo"
            case good = "Buono"
            case neutral = "Normale"
            case tired = "Stanco"
            case exhausted = "Cotto"

            var id: String { rawValue }

            var emoji: String {
                switch self {
                case .great: return "😄"
                case .good: return "🙂"
                case .neutral: return "😐"
                case .tired: return "😮‍💨"
                case .exhausted: return "😵"
                }
            }
        }

        var rpe: Int = 6
        var notes: String = ""
        var feeling: PhysicalFeeling = .good
    }

    let card: WorkoutCard

    var currentBlockIndex: Int = 0
    var currentExerciseIndex: Int = 0
    var currentMethodExerciseIndex: Int = 0
    var currentSetIndex: Int = 0

    var isPaused: Bool = false
    var isCompleted: Bool = false

    var sessionStartDate = Date()
    private var pausedDate: Date?
    private var accumulatedPause: TimeInterval = 0

    var intraSetTimer = TrainingTimerEngine(mode: .countdown(30))
    var interSetTimer = TrainingTimerEngine(mode: .countdown(90))
    var protocolTimer = TrainingTimerEngine(mode: .countdown(60))

    var setResults: [UUID: SetExecutionResult] = [:]
    var exerciseRPE: [UUID: Int] = [:]
    var summary = WorkoutSessionSummary()
    var lastSavedSummary: WorkoutSessionSummary?

    var showSummarySheet = false
    var showCompletionAlert = false
    var showAbandonAlert = false

    init(card: WorkoutCard) {
        self.card = card
        configureRecommendedTimers()
        configureProtocolTimer()
    }

    // MARK: - Computed Properties
    var totalBlocks: Int { card.blocks.count }

    private var orderedBlocks: [WorkoutBlock] {
        card.blocks.sorted(by: { $0.order < $1.order })
    }

    var progressValue: Double {
        guard totalBlocks > 0 else { return 0 }
        let blockProgress = Double(currentBlockIndex) / Double(totalBlocks)
        let intraBlockProgress = currentBlock.flatMap { block -> Double? in
            if block.blockType == .method {
                let totalSets = max(block.globalSets, 1)
                let perSet = 1.0 / Double(totalSets)
                return Double(currentSetIndex) * perSet
            } else if let exercise = currentExerciseItem {
                let totalSets = max(exercise.sets.count, 1)
                return Double(currentSetIndex) / Double(totalSets)
            }
            return nil
        } ?? 0
        return min(1.0, blockProgress + intraBlockProgress / Double(max(totalBlocks, 1)))
    }

    var elapsedTime: TimeInterval {
        let reference = isPaused ? (pausedDate ?? Date()) : Date()
        return reference.timeIntervalSince(sessionStartDate) - accumulatedPause
    }

    var canGoBack: Bool {
        currentBlockIndex > 0 || currentExerciseIndex > 0 || currentSetIndex > 0 || currentMethodExerciseIndex > 0
    }

    var currentBlock: WorkoutBlock? {
        guard currentBlockIndex < orderedBlocks.count else { return nil }
        return orderedBlocks[currentBlockIndex]
    }

    var currentExerciseItem: WorkoutExerciseItem? {
        guard let block = currentBlock else { return nil }
        let exercises = block.exerciseItems.sorted(by: { $0.order < $1.order })
        if exercises.isEmpty { return nil }
        if block.blockType == .method {
            let idx = min(currentMethodExerciseIndex, exercises.count - 1)
            return exercises[idx]
        } else {
            let idx = min(currentExerciseIndex, exercises.count - 1)
            return exercises[idx]
        }
    }

    var currentWorkoutSet: WorkoutSet? {
        guard let exercise = currentExerciseItem else { return nil }
        let sets = exercise.sets.sorted(by: { $0.order < $1.order })
        guard !sets.isEmpty else { return nil }
        let idx = min(currentSetIndex, max(sets.count - 1, 0))
        return sets[idx]
    }

    var nextExercisePreview: String {
        guard let block = currentBlock else { return "" }
        let exercises = block.exerciseItems.sorted(by: { $0.order < $1.order })
        if block.blockType == .method {
            if currentMethodExerciseIndex + 1 < exercises.count {
                return exercises[currentMethodExerciseIndex + 1].exercise?.name ?? ""
            } else if currentSetIndex + 1 < block.globalSets {
                return exercises.first?.exercise?.name ?? ""
            }
        } else {
            if currentExerciseIndex + 1 < exercises.count {
                return exercises[currentExerciseIndex + 1].exercise?.name ?? ""
            } else if currentBlockIndex + 1 < totalBlocks {
                let nextBlock = orderedBlocks[currentBlockIndex + 1]
                return nextBlock.exerciseItems.first?.exercise?.name ?? nextBlock.title
            }
        }
        return ""
    }

    var recommendedInterRest: TimeInterval {
        if let block = currentBlock {
            if block.blockType == .method {
                return block.globalRestTime ?? 90
            }
        }
        if let exercise = currentExerciseItem, let rest = exercise.restTime {
            return rest
        }
        return 90
    }

    var recommendedIntraRest: TimeInterval {
        guard let set = currentWorkoutSet else { return 20 }
        if let clusterRest = set.clusterRestTime { return clusterRest }
        if let restPause = set.restPauseDuration { return restPause }
        return 20
    }

    var cardioShouldBeVisible: Bool {
        guard let block = currentBlock else { return false }
        if block.methodType == .emom || block.methodType == .amrap || block.methodType == .circuit || block.methodType == .tabata {
            return true
        }
        if let set = currentWorkoutSet, set.setType == .duration {
            return true
        }
        return false
    }

    var protocolTimerMode: TrainingTimerMode? {
        guard let block = currentBlock else { return nil }
        if let method = block.methodType {
            switch method {
            case .tabata:
                return .tabata(work: block.tabataWorkDuration ?? 20, rest: block.tabataRestDuration ?? 10, rounds: block.tabataRounds ?? 8)
            case .emom:
                return .emom(duration: max(block.globalRestTime ?? 60, 10), rounds: block.globalSets)
            case .amrap:
                return .amrap(total: TimeInterval(block.globalSets * Int(block.globalRestTime ?? 60)))
            case .circuit:
                return .circuit(work: block.tabataWorkDuration ?? 40, rest: block.tabataRestDuration ?? 20, rounds: block.globalSets)
            default:
                break
            }
        }
        if let set = currentWorkoutSet, set.setType == .duration, let duration = set.duration {
            return .countdown(duration)
        }
        return nil
    }

    // MARK: - Session Controls
    func pauseSession() {
        guard !isPaused else { return }
        pausedDate = Date()
        isPaused = true
        intraSetTimer.pause()
        interSetTimer.pause()
        protocolTimer.pause()
    }

    func resumeSession() {
        guard isPaused else { return }
        if let pausedDate = pausedDate {
            accumulatedPause += Date().timeIntervalSince(pausedDate)
        }
        self.pausedDate = nil
        isPaused = false
        intraSetTimer.resume()
        interSetTimer.resume()
        protocolTimer.resume()
    }

    func togglePause() {
        if isPaused { resumeSession() } else { pauseSession() }
    }

    func completeCurrentStep() {
        guard !isCompleted else { return }
        guard let block = currentBlock else {
            finishSession()
            return
        }

        if block.blockType == .method {
            if currentMethodExerciseIndex + 1 < block.exerciseItems.count {
                currentMethodExerciseIndex += 1
            } else {
                currentMethodExerciseIndex = 0
                if currentSetIndex + 1 < block.globalSets {
                    currentSetIndex += 1
                } else {
                    advanceBlock()
                }
            }
        } else {
            if let exercise = currentExerciseItem {
                if currentSetIndex + 1 < exercise.sets.count {
                    currentSetIndex += 1
                } else {
                    currentSetIndex = 0
                    if currentExerciseIndex + 1 < block.exerciseItems.count {
                        currentExerciseIndex += 1
                    } else {
                        advanceBlock()
                    }
                }
            } else {
                advanceBlock()
            }
        }
        configureRecommendedTimers()
        configureProtocolTimer()
    }

    func previousStep() {
        guard currentBlockIndex > 0 || currentExerciseIndex > 0 || currentSetIndex > 0 || currentMethodExerciseIndex > 0 else { return }
        if let block = currentBlock, block.blockType == .method {
            if currentMethodExerciseIndex > 0 {
                currentMethodExerciseIndex -= 1
            } else if currentSetIndex > 0 {
                currentMethodExerciseIndex = max(block.exerciseItems.count - 1, 0)
                currentSetIndex -= 1
            } else if currentBlockIndex > 0 {
                currentBlockIndex -= 1
                let previousBlock = orderedBlocks[currentBlockIndex]
                currentSetIndex = max(previousBlock.globalSets - 1, 0)
                currentMethodExerciseIndex = max(previousBlock.exerciseItems.count - 1, 0)
            }
        } else {
            if currentSetIndex > 0 {
                currentSetIndex -= 1
            } else if currentExerciseIndex > 0 {
                currentExerciseIndex -= 1
                if let exercise = currentExerciseItem {
                    currentSetIndex = max(exercise.sets.count - 1, 0)
                }
            } else if currentBlockIndex > 0 {
                currentBlockIndex -= 1
                let previousBlock = orderedBlocks[currentBlockIndex]
                currentExerciseIndex = max(previousBlock.exerciseItems.count - 1, 0)
                if let exercise = currentExerciseItem {
                    currentSetIndex = max(exercise.sets.count - 1, 0)
                }
            }
        }
        configureRecommendedTimers()
        configureProtocolTimer()
    }

    func resetSession() {
        currentBlockIndex = 0
        currentExerciseIndex = 0
        currentMethodExerciseIndex = 0
        currentSetIndex = 0
        isCompleted = false
        isPaused = false
        accumulatedPause = 0
        sessionStartDate = Date()
        configureRecommendedTimers()
        configureProtocolTimer()
    }

    func finishSession() {
        isCompleted = true
        showSummarySheet = true
    }

    func saveSummary() {
        lastSavedSummary = summary
        showSummarySheet = false
        showCompletionAlert = true
    }

    // MARK: - Timers
    func configureRecommendedTimers() {
        intraSetTimer.update(mode: .countdown(max(recommendedIntraRest, 5)))
        interSetTimer.update(mode: .countdown(max(recommendedInterRest, 10)))
    }

    func configureProtocolTimer() {
        if let mode = protocolTimerMode {
            protocolTimer.update(mode: mode)
        } else {
            protocolTimer.stop()
        }
    }

    // MARK: - Helpers
    private func advanceBlock() {
        if currentBlockIndex + 1 < orderedBlocks.count {
            currentBlockIndex += 1
            currentExerciseIndex = 0
            currentSetIndex = 0
            currentMethodExerciseIndex = 0
        } else {
            finishSession()
        }
    }
}

@MainActor
@Observable
final class TrainingTimerEngine {
    enum TimerState {
        case stopped
        case running
        case paused
    }

    private var timer: Timer?

    var mode: TrainingTimerMode
    var remainingTime: TimeInterval
    var currentRound: Int = 1
    var totalRounds: Int = 1
    var phase: TrainingTimerMode.Phase = .work
    var state: TimerState = .stopped

    init(mode: TrainingTimerMode) {
        self.mode = mode
        self.remainingTime = mode.initialDuration
        self.totalRounds = mode.rounds
        self.phase = mode.initialPhase
    }

    func update(mode: TrainingTimerMode) {
        timer?.invalidate()
        self.mode = mode
        self.remainingTime = mode.initialDuration
        self.phase = mode.initialPhase
        self.currentRound = 1
        self.totalRounds = mode.rounds
        state = .stopped
    }

    func start() {
        guard state != .running else { return }
        if remainingTime <= 0 { remainingTime = mode.initialDuration }
        state = .running
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        state = .stopped
        remainingTime = mode.initialDuration
        phase = mode.initialPhase
        currentRound = 1
    }

    private func tick() {
        guard remainingTime > 0 else {
            nextPhase()
            return
        }
        remainingTime -= 1
        if remainingTime <= 0 {
            nextPhase()
        }
    }

    private func nextPhase() {
        switch mode {
        case .countdown:
            timer?.invalidate()
            state = .stopped
            remainingTime = 0
        case let .tabata(work, rest, rounds):
            if phase == .work {
                phase = .rest
                remainingTime = rest
            } else {
                if currentRound >= rounds {
                    timer?.invalidate()
                    state = .stopped
                    phase = .completed
                    remainingTime = 0
                } else {
                    currentRound += 1
                    phase = .work
                    remainingTime = work
                }
            }
        case let .emom(duration, rounds):
            if currentRound >= rounds {
                timer?.invalidate()
                state = .stopped
                phase = .completed
                remainingTime = 0
            } else {
                currentRound += 1
                remainingTime = duration
            }
        case let .amrap(total):
            timer?.invalidate()
            state = .stopped
            remainingTime = 0
            phase = .completed
            currentRound = Int(total)
        case let .circuit(work, rest, rounds):
            if phase == .work {
                phase = .rest
                remainingTime = rest
            } else {
                if currentRound >= rounds {
                    timer?.invalidate()
                    state = .stopped
                    phase = .completed
                    remainingTime = 0
                } else {
                    currentRound += 1
                    phase = .work
                    remainingTime = work
                }
            }
        }
    }
}

enum TrainingTimerMode: Equatable {
    case countdown(TimeInterval)
    case tabata(work: TimeInterval, rest: TimeInterval, rounds: Int)
    case emom(duration: TimeInterval, rounds: Int)
    case amrap(total: TimeInterval)
    case circuit(work: TimeInterval, rest: TimeInterval, rounds: Int)

    enum Phase {
        case work
        case rest
        case countdown
        case completed
    }

    var initialDuration: TimeInterval {
        switch self {
        case let .countdown(duration):
            return duration
        case let .tabata(work, _, _):
            return work
        case let .emom(duration, _):
            return duration
        case let .amrap(total):
            return total
        case let .circuit(work, _, _):
            return work
        }
    }

    var rounds: Int {
        switch self {
        case .countdown:
            return 1
        case let .tabata(_, _, rounds):
            return max(1, rounds)
        case let .emom(_, rounds):
            return max(1, rounds)
        case .amrap:
            return 1
        case let .circuit(_, _, rounds):
            return max(1, rounds)
        }
    }

    var initialPhase: Phase {
        switch self {
        case .countdown:
            return .countdown
        case .tabata:
            return .work
        case .emom:
            return .work
        case .amrap:
            return .work
        case .circuit:
            return .work
        }
    }
}
