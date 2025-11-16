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
    var blocks: [WorkoutBlock] // array di blocchi (esercizi singoli o metodologie)

    init(name: String, description: String? = nil, folder: WorkoutFolder? = nil, assignedTo: [Client] = [], blocks: [WorkoutBlock] = []) {
        self.id = UUID()
        self.name = name
        self.cardDescription = description
        self.createdDate = Date()
        self.folder = folder
        self.assignedTo = assignedTo
        self.blocks = blocks
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

    // Helper per il numero totale di blocchi
    var totalBlocks: Int {
        blocks.count
    }

    // Helper per il numero totale di esercizi (sommando tutti gli esercizi in tutti i blocchi)
    var totalExercises: Int {
        blocks.reduce(0) { $0 + $1.exerciseItems.count }
    }

    // Helper per il numero totale di serie
    var totalSets: Int {
        blocks.reduce(0) { total, block in
            if block.blockType == .method {
                // Per metodologie, conta le serie globali del blocco
                return total + block.globalSets
            } else {
                // Per esercizi singoli, conta le serie dell'esercizio
                return total + (block.exerciseItems.first?.sets.count ?? 0)
            }
        }
    }
}
