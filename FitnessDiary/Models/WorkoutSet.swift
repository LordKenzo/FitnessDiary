import Foundation
import SwiftData

@Model
final class WorkoutSet: Identifiable {
    var id: UUID
    var order: Int
    var reps: Int?
    var weight: Double? // kg
    var duration: TimeInterval? // secondi, per esercizi a tempo
    var notes: String?

    init(order: Int, reps: Int? = nil, weight: Double? = nil, duration: TimeInterval? = nil, notes: String? = nil) {
        self.id = UUID()
        self.order = order
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.notes = notes
    }
}
