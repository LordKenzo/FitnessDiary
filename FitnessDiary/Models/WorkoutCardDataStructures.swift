import Foundation

// MARK: - Temporary data structures for workout card editing
// These structures are used to manage workout card data before persisting to SwiftData

/// Temporary structure for editing a workout block
struct WorkoutBlockData: Identifiable {
    let id = UUID()
    var blockType: BlockType
    var methodType: MethodType?
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
}

/// Temporary structure for editing a workout exercise item within a block
struct WorkoutExerciseItemData: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var order: Int
    var sets: [WorkoutSetData]
    var notes: String?
    var restTime: TimeInterval?
    var targetExpression: StrengthExpressionType?
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
