import Foundation
import SwiftData

enum SetType: String, Codable {
    case reps = "Ripetizioni"
    case duration = "Durata"
}

enum LoadType: String, Codable {
    case absolute = "Kg"
    case percentage = "% 1RM"
}

@Model
final class WorkoutSet: Identifiable {
    var id: UUID
    var order: Int
    var setType: SetType // tipo di serie: ripetizioni o durata
    var reps: Int?
    var weight: Double? // kg (quando loadType = .absolute)
    var duration: TimeInterval? // secondi, per esercizi a tempo
    var notes: String?
    var loadType: LoadType? // tipo di carico: assoluto (kg) o percentuale (% 1RM) - opzionale per backward compatibility
    var percentageOfMax: Double? // percentuale dell'1RM (quando loadType = .percentage)

    // Cluster Set parameters
    var clusterSize: Int? // Quante ripetizioni per cluster (es. 2 reps per cluster)
    var clusterRestTime: TimeInterval? // Pausa tra i cluster in secondi (15-60)

    init(order: Int, setType: SetType = .reps, reps: Int? = nil, weight: Double? = nil, duration: TimeInterval? = nil, notes: String? = nil, loadType: LoadType = .absolute, percentageOfMax: Double? = nil, clusterSize: Int? = nil, clusterRestTime: TimeInterval? = nil) {
        self.id = UUID()
        self.order = order
        self.setType = setType
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.notes = notes
        self.loadType = loadType
        self.percentageOfMax = percentageOfMax
        self.clusterSize = clusterSize
        self.clusterRestTime = clusterRestTime
    }

    // Computed property che ritorna il loadType effettivo, defaultando a .absolute per dati legacy
    var actualLoadType: LoadType {
        return loadType ?? .absolute
    }

    // Helper per calcolare il peso effettivo da percentuale e 1RM
    func calculatedWeight(oneRepMax: Double?) -> Double? {
        switch actualLoadType {
        case .absolute:
            return weight
        case .percentage:
            guard let percentage = percentageOfMax, let max = oneRepMax else {
                return nil
            }
            return (percentage / 100.0) * max
        }
    }

    // Helper per calcolare la percentuale da peso assoluto e 1RM
    func calculatedPercentage(oneRepMax: Double?) -> Double? {
        switch actualLoadType {
        case .absolute:
            guard let weight = weight, let max = oneRepMax, max > 0 else {
                return nil
            }
            return (weight / max) * 100.0
        case .percentage:
            return percentageOfMax
        }
    }

    // Helper per formattare la durata
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    // Helper per calcolare il numero di cluster in una serie
    var numberOfClusters: Int? {
        guard let totalReps = reps, let clusterSize = clusterSize, clusterSize > 0 else {
            return nil
        }
        return Int(ceil(Double(totalReps) / Double(clusterSize)))
    }

    // Helper per formattare la descrizione del cluster
    var clusterDescription: String? {
        guard let totalReps = reps,
              let clusterSize = clusterSize,
              let clusters = numberOfClusters,
              let restTime = clusterRestTime else {
            return nil
        }
        return "\(clusters) cluster da \(clusterSize) reps (\(Int(restTime))s pausa)"
    }
}
