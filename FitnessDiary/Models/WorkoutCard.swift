import Foundation
import SwiftData

@Model
final class WorkoutCard: Identifiable {
    var id: UUID
    var name: String
    var cardDescription: String?
    var createdDate: Date
    var folder: WorkoutFolder?
    var assignedTo: Client? // nil = scheda del trainer, altrimenti assegnata al cliente
    var exercises: [WorkoutExercise]

    init(name: String, description: String? = nil, folder: WorkoutFolder? = nil, assignedTo: Client? = nil, exercises: [WorkoutExercise] = []) {
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
        assignedTo != nil
    }

    // Helper per il nome del proprietario
    var ownerName: String {
        assignedTo?.fullName ?? "Mio"
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
