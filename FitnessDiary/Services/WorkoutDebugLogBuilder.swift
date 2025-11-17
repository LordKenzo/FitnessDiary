import Foundation

struct WorkoutDebugLogBuilder {
    static func buildLog(for blocks: [WorkoutBlock]) -> [String] {
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
}

private extension WorkoutDebugLogBuilder {
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
