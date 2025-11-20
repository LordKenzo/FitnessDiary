import Foundation

// MARK: - Temporary data structures for workout card editing
// These structures are used to manage workout card data before persisting to SwiftData

/// Temporary structure for editing a workout block
struct WorkoutBlockData: Identifiable {
    let id = UUID()
    var blockType: BlockType
    var methodType: MethodType?
    var customMethodID: UUID?
    var customMethodName: String? // Cached name for display
    var order: Int
    var globalSets: Int
    var globalRestTime: TimeInterval?
    var notes: String?

    // Parametri Tabata (solo per methodType == .tabata)
    var tabataWorkDuration: TimeInterval?
    var tabataRestDuration: TimeInterval?
    var tabataRounds: Int?
    var tabataRecoveryBetweenRounds: TimeInterval?

    var exerciseItems: [WorkoutExerciseItemData]

    // MARK: - Display Properties
    // Lightweight computed properties for UI display without full model conversion

    var title: String {
        switch blockType {
        case .method:
            if let method = methodType {
                return method.displayName
            }
            return "Metodo"
        case .customMethod:
            return customMethodName ?? "Metodo Custom"
        case .rest:
            return "Riposo"
        case .simple:
            return exerciseItems.first?.exercise.name ?? "Esercizio"
        }
    }

    var subtitle: String {
        switch blockType {
        case .method, .customMethod:
            return "\(exerciseItems.count) esercizi • \(globalSets) serie"
        case .rest:
            return formattedRestTime ?? "Durata personalizzata"
        case .simple:
            let totalSets = exerciseItems.first?.sets.count ?? 0
            return "\(totalSets) serie"
        }
    }

    var formattedRestTime: String? {
        guard let restTime = globalRestTime, restTime > 0 else { return nil }
        let minutes = Int(restTime) / 60
        let seconds = Int(restTime) % 60

        if minutes > 0 && seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

/// Temporary structure for editing a workout exercise item within a block
struct WorkoutExerciseItemData: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var order: Int
    var sets: [WorkoutSetData]
    var notes: String?
    var restTime: TimeInterval?
}

/// Temporary structure for editing an individual workout set
struct WorkoutSetData: Identifiable, ClusterCalculations {
    let id = UUID()
    var order: Int
    var setType: SetType
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var notes: String?
    var loadType: LoadType
    var percentageOfMax: Double?

    // Cluster Set parameters
    var clusterSize: Int? // Quante ripetizioni per cluster (es. 2)
    var clusterRestTime: TimeInterval? // Pausa tra i cluster in secondi (15-60)
    var clusterProgression: ClusterLoadProgression? // Tipo di progressione del carico tra i cluster
    var clusterMinPercentage: Double? // Percentuale minima 1RM (es. 80%)
    var clusterMaxPercentage: Double? // Percentuale massima 1RM (es. 95%)

    // Rest-Pause parameters
    var restPauseCount: Int? // Numero di pause nella serie (es. 2-3)
    var restPauseDuration: TimeInterval? // Durata delle pause in secondi (es. 10-20)
}

// MARK: - Cluster Set Extensions
// numberOfClusters, clusterDescription, clusterLoadPercentages(), clusterLoadWeights()
// sono forniti dal protocol ClusterCalculations

// MARK: - Rest-Pause Extensions

extension WorkoutSetData {
    // Helper per formattare la descrizione del rest-pause
    var restPauseDescription: String? {
        guard let reps = reps,
              let pauseCount = restPauseCount,
              let pauseDuration = restPauseDuration else {
            return nil
        }
        return "\(reps) reps con \(pauseCount) pause da \(Int(pauseDuration))s"
    }
}

// MARK: - Validation Extensions

extension WorkoutExerciseItemData {
    /// Valida la progressione dei carichi in base al tipo di metodo
    /// - Parameter validation: Il tipo di validazione da applicare
    /// - Returns: nil se valido, altrimenti un messaggio di errore
    func validateLoadProgression(for validation: LoadProgressionValidation) -> String? {
        // Se non ci sono abbastanza serie per validare, è ok
        guard sets.count > 1 else { return nil }

        // Estrai i carichi dalle serie (supporta sia kg assoluti che % 1RM)
        let loads = sets.compactMap { set -> Double? in
            guard set.setType == .reps else { return nil }
            return set.loadType == .absolute ? set.weight : set.percentageOfMax
        }

        // Se non ci sono abbastanza carichi da validare, è ok
        guard loads.count > 1 else { return nil }

        switch validation {
        case .none:
            return nil

        case .ascending:
            // Verifica che ogni carico sia >= del precedente
            for i in 1..<loads.count {
                if loads[i] < loads[i-1] {
                    return "Serie \(i+1): il carico deve essere maggiore o uguale alla serie precedente"
                }
            }
            return nil

        case .descending:
            // Verifica che ogni carico sia <= del precedente
            for i in 1..<loads.count {
                if loads[i] > loads[i-1] {
                    return "Serie \(i+1): il carico deve essere minore o uguale alla serie precedente"
                }
            }
            return nil

        case .constant:
            // Verifica che tutti i carichi siano uguali
            let firstLoad = loads[0]
            for i in 1..<loads.count {
                if loads[i] != firstLoad {
                    return "Tutte le serie devono avere lo stesso carico (\(String(format: "%.1f", firstLoad)))"
                }
            }
            return nil
        }
    }
}

// MARK: - Utility helpers

extension Array where Element == WorkoutSetData {
    mutating func cloneLoadIfNeeded(from sourceSet: WorkoutSetData) {
        switch sourceSet.loadType {
        case .absolute:
            guard let weight = sourceSet.weight else { return }
            propagateAbsoluteLoad(weight, sourceId: sourceSet.id)
        case .percentage:
            guard let percentage = sourceSet.percentageOfMax else { return }
            propagatePercentageLoad(percentage, sourceId: sourceSet.id)
        }
    }

    private mutating func propagateAbsoluteLoad(_ weight: Double, sourceId: UUID) {
        for index in indices {
            guard self[index].id != sourceId else { continue }
            guard self[index].weight == nil && self[index].percentageOfMax == nil else { continue }
            self[index].loadType = .absolute
            self[index].weight = weight
        }
    }

    private mutating func propagatePercentageLoad(_ percentage: Double, sourceId: UUID) {
        for index in indices {
            guard self[index].id != sourceId else { continue }
            guard self[index].weight == nil && self[index].percentageOfMax == nil else { continue }
            self[index].loadType = .percentage
            self[index].percentageOfMax = percentage
        }
    }
}
