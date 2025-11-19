import Foundation

/// Protocol che fornisce calcoli comuni per i Cluster Set
/// Implementato da WorkoutSet e WorkoutSetData per evitare duplicazione di codice
protocol ClusterCalculations {
    var reps: Int? { get }
    var clusterSize: Int? { get }
    var clusterRestTime: TimeInterval? { get }
    var clusterProgression: ClusterLoadProgression? { get }
    var clusterMinPercentage: Double? { get }
    var clusterMaxPercentage: Double? { get }
}

extension ClusterCalculations {

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
