import Foundation
import SwiftData

enum SetType: String, Codable {
    case reps = "Ripetizioni"
    case duration = "Durata"
}

@Model
final class WorkoutSet: Identifiable {
    var id: UUID
    var order: Int
    var setType: SetType // tipo di serie: ripetizioni o durata
    var reps: Int?
    var weight: Double? // kg
    var duration: TimeInterval? // secondi, per esercizi a tempo
    var notes: String?

    init(order: Int, setType: SetType = .reps, reps: Int? = nil, weight: Double? = nil, duration: TimeInterval? = nil, notes: String? = nil) {
        self.id = UUID()
        self.order = order
        self.setType = setType
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.notes = notes
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
}
