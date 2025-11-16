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
}

/// Temporary structure for editing an individual workout set
struct WorkoutSetData: Identifiable {
    let id = UUID()
    var order: Int
    var setType: SetType
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var notes: String?
    var loadType: LoadType
    var percentageOfMax: Double?
}

// MARK: - Validation Extensions

extension WorkoutExerciseItemData {
    /// Valida la progressione dei carichi in base al tipo di metodo
    /// - Parameter validation: Il tipo di validazione da applicare
    /// - Returns: nil se valido, altrimenti un messaggio di errore
    func validateLoadProgression(for validation: LoadProgressionValidation) -> String? {
        // Se non ci sono abbastanza serie per validare, è ok
        guard sets.count > 1 else { return nil }

        // Estrai i pesi dalle serie (solo se setType == .reps e loadType == .absolute)
        let weights = sets.compactMap { set -> Double? in
            guard set.setType == .reps, set.loadType == .absolute, let weight = set.weight else {
                return nil
            }
            return weight
        }

        // Se non ci sono abbastanza pesi da validare, è ok
        guard weights.count > 1 else { return nil }

        switch validation {
        case .none:
            return nil

        case .ascending:
            // Verifica che ogni peso sia >= del precedente
            for i in 1..<weights.count {
                if weights[i] < weights[i-1] {
                    return "Serie \(i+1): il peso deve essere maggiore o uguale alla serie precedente"
                }
            }
            return nil

        case .descending:
            // Verifica che ogni peso sia <= del precedente
            for i in 1..<weights.count {
                if weights[i] > weights[i-1] {
                    return "Serie \(i+1): il peso deve essere minore o uguale alla serie precedente"
                }
            }
            return nil

        case .constant:
            // Verifica che tutti i pesi siano uguali
            let firstWeight = weights[0]
            for i in 1..<weights.count {
                if weights[i] != firstWeight {
                    return "Tutte le serie devono avere lo stesso peso (\(String(format: "%.1f", firstWeight)) kg)"
                }
            }
            return nil
        }
    }
}
