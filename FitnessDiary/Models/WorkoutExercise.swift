import Foundation
import SwiftData

@Model
final class WorkoutExercise: Identifiable {
    var id: UUID
    var order: Int
    var exercise: Exercise? // relationship con l'esercizio dalla libreria
    @Relationship(deleteRule: .cascade)
    var sets: [WorkoutSet]
    var notes: String?
    var restTime: TimeInterval? // tempo di recupero tra le serie in secondi

    init(order: Int, exercise: Exercise? = nil, sets: [WorkoutSet] = [], notes: String? = nil, restTime: TimeInterval? = nil) {
        self.id = UUID()
        self.order = order
        self.exercise = exercise
        self.sets = sets
        self.notes = notes
        self.restTime = restTime
    }

    // Helper per formattare il tempo di recupero
    var formattedRestTime: String? {
        guard let restTime = restTime else { return nil }
        let minutes = Int(restTime) / 60
        let seconds = Int(restTime) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
