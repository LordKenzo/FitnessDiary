import Foundation
import SwiftData

@Model
final class WorkoutCard: Identifiable {
    var id: UUID
    var name: String
    var cardDescription: String?
    var createdDate: Date
    var folder: WorkoutFolder?
    var assignedTo: [Client] // array di clienti assegnati (vuoto = scheda del trainer)
    @Relationship(deleteRule: .cascade)
    var exercises: [WorkoutExercise]

    init(name: String, description: String? = nil, folder: WorkoutFolder? = nil, assignedTo: [Client] = [], exercises: [WorkoutExercise] = []) {
        self.id = UUID()
        self.name = name
        self.cardDescription = description
        self.createdDate = Date()
        self.folder = folder
        self.assignedTo = assignedTo
        self.exercises = exercises
    }

    // Helper per sapere se la scheda è assegnata
    var isAssigned: Bool {
        !assignedTo.isEmpty
    }

    // Helper per il numero di clienti assegnati
    var assignedCount: Int {
        assignedTo.count
    }

    // Helper per il testo di assegnazione
    var assignmentText: String {
        if assignedTo.isEmpty {
            return "Mio"
        } else if assignedTo.count == 1 {
            return assignedTo[0].fullName
        } else {
            return "Assegnata a (\(assignedTo.count))"
        }
    }

    // Helper per il numero totale di esercizi
    var totalExercises: Int {
        exercises.count
    }

    // Helper per il numero totale di serie
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}
