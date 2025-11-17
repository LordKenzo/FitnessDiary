import Foundation

enum WorkoutSheetFormat: String, CaseIterable, Identifiable {
    case verbose = "Testo"
    case technical = "Tecnico"

    var id: Self { self }

    var title: String {
        switch self {
        case .verbose:
            return "Testo"
        case .technical:
            return "Formato tecnico"
        }
    }
}

struct WorkoutDebugLogBuilder {
    static func buildLog(for blocks: [WorkoutBlock], format: WorkoutSheetFormat = .verbose) -> [String] {
        switch format {
        case .verbose:
            return buildVerboseLog(for: blocks)
        case .technical:
            return buildTechnicalLog(for: blocks)
        }
    }
}

private struct TechnicalSetGroup: Equatable {
    var count: Int
    var descriptor: String
}

private extension WorkoutDebugLogBuilder {
    static func buildVerboseLog(for blocks: [WorkoutBlock]) -> [String] {
        var lines: [String] = []

        if let countdownEntry = initialCountdownEntry() {
            lines.append(countdownEntry)
        }

        let orderedBlocks = blocks.sorted { $0.order < $1.order }
        for block in orderedBlocks {
            switch block.blockType {
            case .rest:
                lines.append(restEntry(for: block))
            case .simple:
                lines.append(contentsOf: simpleEntries(for: block))
            case .method:
                lines.append(contentsOf: methodEntries(for: block))
            }
        }

        return lines
    }

    static func buildTechnicalLog(for blocks: [WorkoutBlock]) -> [String] {
        var lines: [String] = []

        if let countdownEntry = initialCountdownEntry() {
            lines.append(countdownEntry)
        }

        let orderedBlocks = blocks.sorted { $0.order < $1.order }
        for block in orderedBlocks {
            switch block.blockType {
            case .rest:
                lines.append(technicalRestEntry(for: block))
            case .simple:
                lines.append(contentsOf: technicalSimpleEntries(for: block))
            case .method:
                lines.append(contentsOf: technicalMethodEntries(for: block))
            }
        }

        return lines
    }

    static func restEntry(for block: WorkoutBlock) -> String {
        "Blocco Pausa \(formatDuration(block.globalRestTime))"
    }

    static func simpleEntries(for block: WorkoutBlock) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else {
            return ["Blocco senza esercizi"]
        }

        var lines: [String] = []
        for exercise in exercises {
            let sets = orderedSets(for: exercise)
            guard !sets.isEmpty else {
                lines.append("Esercizio \(exerciseName(exercise)) senza serie configurate")
                continue
            }

            for (index, set) in sets.enumerated() {
                let prefix = "Esercizio \(exerciseName(exercise)) \(index + 1) serie di \(sets.count)"
                let description = setDescription(for: set)
                lines.append("\(prefix) \(description)")

                if index < sets.count - 1,
                   let rest = exercise.restTime ?? block.globalRestTime {
                    lines.append("Riposo tra le serie \(formatDuration(rest))")
                }
            }
        }
        return lines
    }

    static func methodEntries(for block: WorkoutBlock) -> [String] {
        guard let method = block.methodType else {
            return simpleEntries(for: block)
        }

        var lines: [String] = []
        let blockName = methodBlockName(for: block)
        lines.append("Inizio Blocco \(blockName)")

        let content: [String]
        switch method {
        case .cluster:
            content = clusterEntries(for: block)
        case .tabata:
            content = tabataEntries(for: block)
        default:
            content = multiExerciseEntries(for: block, allowsRest: method.allowsRestBetweenSets)
        }

        lines.append(contentsOf: content)
        lines.append("Fine Blocco \(blockName)")
        return lines
    }

    static func technicalRestEntry(for block: WorkoutBlock) -> String {
        "Rest \(formatShortDuration(block.globalRestTime))"
    }

    static func technicalSimpleEntries(for block: WorkoutBlock) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else {
            return ["Blocco senza esercizi"]
        }

        var lines: [String] = []
        for exercise in exercises {
            let name = exerciseName(exercise)
            let groups = technicalSetGroups(for: exercise)
            if groups.isEmpty {
                lines.append("\(name) senza serie configurate")
                continue
            }

            for group in groups {
                lines.append("\(name) \(group.count)x\(group.descriptor)")
            }
        }
        return lines
    }

    static func technicalMethodEntries(for block: WorkoutBlock) -> [String] {
        guard let method = block.methodType else {
            return technicalSimpleEntries(for: block)
        }

        switch method {
        case .superset:
            return complexSetEntries(for: block, labelPrefix: "A")
        case .triset:
            return complexSetEntries(for: block, labelPrefix: "A")
        case .giantSet:
            return complexSetEntries(for: block, labelPrefix: "A")
        case .dropset:
            return dropsetEntries(for: block)
        case .rest_pause:
            return restPauseEntries(for: block)
        case .cluster:
            return clusterNotationEntries(for: block)
        case .emom:
            return emomEntries(for: block)
        case .amrap:
            return amrapEntries(for: block)
        case .circuit:
            return circuitEntries(for: block)
        case .tabata:
            return tabataTechnicalEntries(for: block)
        default:
            return technicalSimpleEntries(for: block)
        }
    }

    static func complexSetEntries(for block: WorkoutBlock, labelPrefix: String) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else { return ["Blocco metodo senza esercizi"] }

        var lines: [String] = []
        for (index, exercise) in exercises.enumerated() {
            let label = "\(labelPrefix)\(index + 1))"
            let summary = condensedSummary(for: exercise) ?? "senza serie"
            lines.append("\(label) \(exerciseName(exercise)) \(summary)")
        }

        if let rest = block.globalRestTime {
            lines.append("Rest \(formatShortDuration(rest))")
        }
        lines.append("x \(max(block.globalSets, 1)) rounds")
        return lines
    }

    static func dropsetEntries(for block: WorkoutBlock) -> [String] {
        guard let exercise = block.exerciseItems.sorted(by: { $0.order < $1.order }).first else {
            return ["Dropset senza esercizi"]
        }

        let sets = orderedSets(for: exercise)
        let segments = sets.compactMap { technicalSetDescriptor(for: $0) }
        guard !segments.isEmpty else {
            return ["Dropset senza serie"]
        }

        let line = segments.joined(separator: " + ")
        return ["\(exerciseName(exercise)) 1x(\(line))"]
    }

    static func restPauseEntries(for block: WorkoutBlock) -> [String] {
        guard let exercise = block.exerciseItems.sorted(by: { $0.order < $1.order }).first else {
            return ["Rest-Pause senza esercizi"]
        }

        guard let set = orderedSets(for: exercise).first,
              let reps = set.reps else {
            return ["Rest-Pause senza serie"]
        }

        var line = "\(exerciseName(exercise)) 1x\(reps)"
        if let load = technicalLoadText(for: set) {
            line += load
        }

        var rpDetails: [String] = []
        if let pauseCount = set.restPauseCount {
            rpDetails.append("x\(pauseCount)")
        }
        if let duration = set.restPauseDuration {
            rpDetails.append(formatShortDuration(duration))
        }

        if rpDetails.isEmpty {
            line += " + RP"
        } else {
            line += " + RP: \(rpDetails.joined(separator: ", "))"
        }
        return [line]
    }

    static func clusterNotationEntries(for block: WorkoutBlock) -> [String] {
        guard let exercise = block.exerciseItems.sorted(by: { $0.order < $1.order }).first,
              let set = orderedSets(for: exercise).first else {
            return ["Cluster senza esercizi"]
        }

        let seriesCount = max(block.globalSets, 1)
        let repsPerCluster = max(set.clusterSize ?? 1, 1)
        let fallbackClusters = Int(ceil(Double(set.reps ?? repsPerCluster) / Double(repsPerCluster)))
        let clusters = max(set.numberOfClusters ?? fallbackClusters, 1)

        var line = "\(exerciseName(exercise)) \(seriesCount)x\(clusters)/\(repsPerCluster)"
        if let load = clusterLoadText(for: set) {
            line += load
        }

        var restComponents: [String] = []
        if let intra = set.clusterRestTime {
            restComponents.append(formatShortDuration(intra))
        }
        if let inter = block.globalRestTime {
            restComponents.append(formatShortDuration(inter))
        }
        if !restComponents.isEmpty {
            line += ", \(restComponents.joined(separator: ", "))"
        }
        return [line]
    }

    static func emomEntries(for block: WorkoutBlock) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else { return ["EMOM senza esercizi"] }

        let durationText = "\(max(block.globalSets, 1))'"
        if exercises.count == 1 {
            return ["EMOM \(durationText): \(taskLine(for: exercises[0]))"]
        }

        var lines: [String] = ["EMOM \(durationText):"]
        for (index, exercise) in exercises.enumerated() {
            lines.append("Min \(index + 1) – \(taskLine(for: exercise))")
        }
        return lines
    }

    static func amrapEntries(for block: WorkoutBlock) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else { return ["AMRAP senza esercizi"] }

        let durationText = "\(max(block.globalSets, 1))'"
        var lines: [String] = ["AMRAP \(durationText):"]
        for exercise in exercises {
            lines.append(taskLine(for: exercise))
        }
        return lines
    }

    static func circuitEntries(for block: WorkoutBlock) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else { return ["Circuito senza esercizi"] }

        var lines: [String] = ["Circuit x \(max(block.globalSets, 1)) rounds"]
        for exercise in exercises {
            lines.append(circuitLine(for: exercise))
        }
        if let rest = block.globalRestTime {
            lines.append("Rest \(formatShortDuration(rest))")
        }
        return lines
    }

    static func tabataTechnicalEntries(for block: WorkoutBlock) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else { return ["Tabata senza esercizi"] }

        let work = formatShortDuration(block.tabataWorkDuration ?? 20)
        let rest = formatShortDuration(block.tabataRestDuration ?? 10)
        let rounds = max(block.tabataRounds ?? 1, 1)

        var lines: [String] = []
        let header = "Tabata \(work)/\(rest) × 8"
        if exercises.count == 1 {
            lines.append("\(header): \(exerciseName(exercises[0]))")
        } else {
            lines.append("\(header):")
            for (index, exercise) in exercises.enumerated() {
                lines.append("A\(index + 1)) \(exerciseName(exercise))")
            }
        }

        if rounds > 1 {
            lines.append("Round totali: \(rounds)")
            if let between = block.tabataRecoveryBetweenRounds {
                lines.append("Rest tra round \(formatShortDuration(between))")
            }
        }
        return lines
    }

    static func clusterEntries(for block: WorkoutBlock) -> [String] {
        guard let exercise = block.exerciseItems.sorted(by: { $0.order < $1.order }).first,
              let set = orderedSets(for: exercise).first else {
            return ["Cluster senza esercizi"]
        }

        let totalReps = max(set.reps ?? 1, 1)
        let clusterSize = max(min(set.clusterSize ?? totalReps, totalReps), 1)
        var lines: [String] = []

        let loadText = loadDescription(for: set)

        for rep in 1...totalReps {
            var entry = "Esercizio Cluster \(exerciseName(exercise)) Ripetizione \(rep)"
            if let loadText {
                entry += " \(loadText)"
            }
            lines.append(entry)

            if rep % clusterSize == 0,
               rep < totalReps,
               let rest = set.clusterRestTime {
                lines.append("Riposo tra i cluster \(formatDuration(rest))")
            }
        }

        return lines
    }

    static func tabataEntries(for block: WorkoutBlock) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else { return ["Tabata senza esercizi"] }

        let rounds = max(block.tabataRounds ?? 5, 1)
        let workDuration = block.tabataWorkDuration ?? 20
        let restDuration = block.tabataRestDuration ?? 10

        var lines: [String] = []

        for round in 1...rounds {
            for exercise in exercises {
                lines.append("Tabata Round \(round) - \(exerciseName(exercise)) lavoro \(formatDuration(workDuration))")
                lines.append("Recupero Tabata \(formatDuration(restDuration))")
            }

            if round < rounds,
               let betweenRounds = block.tabataRecoveryBetweenRounds {
                lines.append("Recupero tra i round \(formatDuration(betweenRounds))")
            }
        }

        return lines
    }

    static func multiExerciseEntries(for block: WorkoutBlock, allowsRest: Bool) -> [String] {
        let exercises = block.exerciseItems.sorted { $0.order < $1.order }
        guard !exercises.isEmpty else { return ["Blocco metodo senza esercizi"] }

        let totalSets = max(block.globalSets, 1)
        var lines: [String] = []

        for setIndex in 0..<totalSets {
            for exercise in exercises {
                let set = setForExercise(exercise, at: setIndex)
                let prefix = "Esercizio \(exerciseName(exercise)) \(setIndex + 1) serie di \(totalSets)"
                let description = setDescription(for: set)
                lines.append("\(prefix) \(description)")
            }

            if setIndex < totalSets - 1,
               allowsRest,
               let rest = block.globalRestTime {
                lines.append("Riposo tra le serie \(formatDuration(rest))")
            }
        }

        return lines
    }

    static func circuitLine(for exercise: WorkoutExerciseItem) -> String {
        guard let firstSet = orderedSets(for: exercise).first else {
            return exerciseName(exercise)
        }

        switch firstSet.setType {
        case .duration:
            if let duration = firstSet.duration {
                return "\(exerciseName(exercise)) \(formatShortDuration(duration))"
            }
            return exerciseName(exercise)
        case .reps:
            if let summary = condensedSummary(for: exercise) {
                return "\(exerciseName(exercise)) \(summary)"
            }
            return exerciseName(exercise)
        }
    }

    static func taskLine(for exercise: WorkoutExerciseItem) -> String {
        guard let set = orderedSets(for: exercise).first else {
            return exerciseName(exercise)
        }

        switch set.setType {
        case .reps:
            guard let reps = set.reps else { return exerciseName(exercise) }
            var line = "\(reps) \(exerciseName(exercise))"
            if let load = technicalLoadText(for: set) {
                line += " \(load)"
            }
            return line
        case .duration:
            guard let duration = set.duration else { return exerciseName(exercise) }
            return "\(exerciseName(exercise)) \(formatShortDuration(duration))"
        }
    }

    static func condensedSummary(for exercise: WorkoutExerciseItem) -> String? {
        let groups = technicalSetGroups(for: exercise)
        guard !groups.isEmpty else { return nil }
        let parts = groups.map { "\($0.count)x\($0.descriptor)" }
        return parts.joined(separator: " + ")
    }

    static func technicalSetGroups(for exercise: WorkoutExerciseItem) -> [TechnicalSetGroup] {
        let sets = orderedSets(for: exercise)
        guard !sets.isEmpty else { return [] }

        var groups: [TechnicalSetGroup] = []
        for set in sets {
            guard let descriptor = technicalSetDescriptor(for: set) else { continue }
            if let lastIndex = groups.indices.last, groups[lastIndex].descriptor == descriptor {
                groups[lastIndex].count += 1
            } else {
                groups.append(TechnicalSetGroup(count: 1, descriptor: descriptor))
            }
        }
        return groups
    }

    static func technicalSetDescriptor(for set: WorkoutSet) -> String? {
        switch set.setType {
        case .reps:
            guard let reps = set.reps else { return nil }
            var descriptor = "\(reps)"
            if let load = technicalLoadText(for: set) {
                descriptor += load
            }
            return descriptor
        case .duration:
            guard let duration = set.duration else { return nil }
            return formatShortDuration(duration)
        }
    }

    static func technicalLoadText(for set: WorkoutSet) -> String? {
        switch set.actualLoadType {
        case .absolute:
            guard let weight = set.weight else { return nil }
            return "@\(formatWeight(weight))kg"
        case .percentage:
            guard let percentage = set.percentageOfMax else { return nil }
            return "@\(formatPercentage(percentage))%"
        }
    }

    static func clusterLoadText(for set: WorkoutSet) -> String? {
        if let minPct = set.clusterMinPercentage,
           let maxPct = set.clusterMaxPercentage {
            if abs(minPct - maxPct) < 0.01 {
                return "@\(formatPercentage(minPct))%"
            } else {
                return "@\(formatPercentage(minPct))–\(formatPercentage(maxPct))%"
            }
        }
        return technicalLoadText(for: set)
    }

    static func setForExercise(_ exercise: WorkoutExerciseItem, at index: Int) -> WorkoutSet? {
        let sets = orderedSets(for: exercise)
        guard !sets.isEmpty else { return nil }
        if index < sets.count { return sets[index] }
        return sets.last
    }

    static func orderedSets(for exercise: WorkoutExerciseItem) -> [WorkoutSet] {
        exercise.sets.sorted { $0.order < $1.order }
    }

    static func exerciseName(_ exercise: WorkoutExerciseItem) -> String {
        exercise.exercise?.name ?? "Esercizio"
    }

    static func setDescription(for set: WorkoutSet?) -> String {
        guard let set = set else { return "senza dettagli" }

        var components: [String] = []

        switch set.setType {
        case .reps:
            if let description = set.restPauseDescription {
                components.append(description)
            } else if let reps = set.reps {
                components.append("\(reps) ripetizioni")
            } else {
                components.append("ripetizioni")
            }
        case .duration:
            components.append("tempo \(formatDuration(set.duration))")
        }

        if let loadText = loadDescription(for: set) {
            components.append(loadText)
        }

        return components.joined(separator: " ")
    }

    static func loadDescription(for set: WorkoutSet) -> String? {
        switch set.actualLoadType {
        case .absolute:
            guard let weight = set.weight else { return nil }
            return "con \(formatWeight(weight)) kg"
        case .percentage:
            guard let percentage = set.percentageOfMax else { return nil }
            return "al \(formatPercentage(percentage))% 1RM"
        }
    }

    static func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return String(format: "%.1f", weight)
        }
    }

    static func formatPercentage(_ percentage: Double) -> String {
        if percentage.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(percentage))"
        } else {
            return String(format: "%.1f", percentage)
        }
    }

    static func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "personalizzata" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        var components: [String] = []
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minuto" : "minuti")")
        }
        if seconds > 0 {
            components.append("\(seconds) \(seconds == 1 ? "secondo" : "secondi")")
        }
        if components.isEmpty {
            components.append("0 secondi")
        }
        return components.joined(separator: " ")
    }

    static func formatShortDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "personalizzata" }
        return formatShortDuration(duration)
    }

    static func formatShortDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var components: [String] = []
        if hours > 0 {
            components.append("\(hours)h")
        }
        if minutes > 0 {
            components.append("\(minutes)'")
        }
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds)\"")
        }
        return components.joined()
    }

    static func initialCountdownEntry() -> String? {
        let countdown = storedCountdownSeconds()
        guard countdown > 0 else { return nil }
        return "Countdown iniziale \(formatDuration(TimeInterval(countdown)))"
    }

    static func storedCountdownSeconds() -> Int {
        if let stored = UserDefaults.standard.object(forKey: countdownSecondsKey) as? Int {
            return stored
        }
        return defaultCountdownSeconds
    }

    static let countdownSecondsKey = "workoutCountdownSeconds"
    static let defaultCountdownSeconds = 10

    static func methodBlockName(for block: WorkoutBlock) -> String {
        block.methodType?.rawValue ?? block.title
    }
}
