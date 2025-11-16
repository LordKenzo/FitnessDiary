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

    // Cluster Set parameters
    var clusterSize: Int? // Quante ripetizioni per cluster (es. 2)
    var clusterRestTime: TimeInterval? // Pausa tra i cluster in secondi (15-60)
    var clusterProgression: ClusterLoadProgression? // Tipo di progressione del carico tra i cluster
    var clusterMinPercentage: Double? // Percentuale minima 1RM (es. 80%)
    var clusterMaxPercentage: Double? // Percentuale massima 1RM (es. 95%)
}

// MARK: - Cluster Set Extensions

extension WorkoutSetData {
    // Helper per calcolare il numero di cluster in una serie
    var numberOfClusters: Int? {
        guard let totalReps = reps, let clusterSize = clusterSize, clusterSize > 0 else {
            return nil
        }
        return Int(ceil(Double(totalReps) / Double(clusterSize)))
    }

    // Helper per formattare la descrizione del cluster
    var clusterDescription: String? {
        guard reps != nil,
              let clusterSize = clusterSize,
              let clusters = numberOfClusters,
              let restTime = clusterRestTime else {
            return nil
        }
        return "\(clusters) cluster da \(clusterSize) reps (\(Int(restTime))s pausa)"
    }

    // Calcola le percentuali di carico per ogni cluster
    func clusterLoadPercentages() -> [Double]? {
        guard let clusters = numberOfClusters,
              let progression = clusterProgression,
              let minPct = clusterMinPercentage,
              let maxPct = clusterMaxPercentage else {
            return nil
        }

        // Se c'è un solo cluster, usa la percentuale media
        if clusters == 1 {
            return [(minPct + maxPct) / 2.0]
        }

        var percentages: [Double] = []

        switch progression {
        case .constant:
            // Valore costante a metà tra min e max
            let constantPct = (minPct + maxPct) / 2.0
            percentages = Array(repeating: constantPct, count: clusters)

        case .ascending:
            // Progressione lineare da minima a massima
            for i in 0..<clusters {
                let progress = Double(i) / Double(clusters - 1)
                let pct = minPct + (maxPct - minPct) * progress
                percentages.append(pct)
            }

        case .descending:
            // Progressione lineare da massima a minima
            for i in 0..<clusters {
                let progress = Double(i) / Double(clusters - 1)
                let pct = maxPct - (maxPct - minPct) * progress
                percentages.append(pct)
            }

        case .wave:
            // Ondulato: sale fino a metà (max), poi scende (min)
            let midPoint = clusters / 2
            for i in 0..<clusters {
                if i <= midPoint {
                    // Prima metà: ascendente verso max
                    let progress = Double(i) / Double(midPoint)
                    let pct = minPct + (maxPct - minPct) * progress
                    percentages.append(pct)
                } else {
                    // Seconda metà: discendente verso min
                    let progress = Double(i - midPoint) / Double(clusters - midPoint - 1)
                    let pct = maxPct - (maxPct - minPct) * progress
                    percentages.append(pct)
                }
            }
        }

        return percentages
    }

    // Calcola i pesi effettivi per ogni cluster dato un 1RM
    func clusterLoadWeights(oneRepMax: Double?) -> [Double]? {
        guard let oneRM = oneRepMax,
              let percentages = clusterLoadPercentages() else {
            return nil
        }
        return percentages.map { ($0 / 100.0) * oneRM }
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
