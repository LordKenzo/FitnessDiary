import Foundation
import SwiftData

@Model
final class WorkoutCard: Identifiable {
    var id: UUID
    var name: String
    var cardDescription: String?
    var createdDate: Date
    var targetExpression: StrengthExpressionType?
    @Relationship(deleteRule: .nullify)
    var folders: [WorkoutFolder] // array di folder (una scheda può stare in più folder)
    var isAssignedToMe: Bool // toggle separato per assegnazione a me stesso
    @Relationship(deleteRule: .nullify)
    var assignedTo: [Client] // array di clienti assegnati
    @Relationship(deleteRule: .cascade)
    var blocks: [WorkoutBlock] // array di blocchi (esercizi singoli o metodologie)

    init(name: String, description: String? = nil, targetExpression: StrengthExpressionType? = nil, folders: [WorkoutFolder] = [], isAssignedToMe: Bool = true, assignedTo: [Client] = [], blocks: [WorkoutBlock] = []) {
        self.id = UUID()
        self.name = name
        self.cardDescription = description
        self.createdDate = Date()
        self.targetExpression = targetExpression
        self.folders = folders
        self.isAssignedToMe = isAssignedToMe
        self.assignedTo = assignedTo
        self.blocks = blocks
    }

    // Helper per sapere se la scheda è assegnata (a me o a clienti)
    var isAssigned: Bool {
        isAssignedToMe || !assignedTo.isEmpty
    }

    // Helper per il numero di clienti assegnati
    var assignedCount: Int {
        assignedTo.count
    }

    // Helper per il testo di assegnazione
    var assignmentText: String {
        if isAssignedToMe && assignedTo.isEmpty {
            return "Mia"
        } else if !isAssignedToMe && assignedTo.isEmpty {
            return "Non assegnata"
        } else if isAssignedToMe && assignedTo.count == 1 {
            return "Mia • \(assignedTo[0].fullName)"
        } else if isAssignedToMe && assignedTo.count > 1 {
            return "Mia • \(assignedTo.count) clienti"
        } else if assignedTo.count == 1 {
            return assignedTo[0].fullName
        } else {
            return "\(assignedTo.count) clienti"
        }
    }

    // Helper per sapere se la scheda è in un folder specifico
    func isInFolder(_ folder: WorkoutFolder) -> Bool {
        folders.contains { $0.id == folder.id }
    }

    // Helper per sapere se la scheda non ha folder
    var hasNoFolders: Bool {
        folders.isEmpty
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

    // Stima della durata totale dell'allenamento in secondi
    var estimatedDurationSeconds: TimeInterval {
        blocks.reduce(0.0) { total, block in
            return total + block.estimatedDurationSeconds
        }
    }

    // Stima della durata in minuti (arrotondata)
    var estimatedDurationMinutes: Int {
        Int(estimatedDurationSeconds / 60)
    }

    // Verifica se la scheda è valida o è ancora in bozza
    var isDraft: Bool {
        // Scheda vuota = bozza
        if blocks.isEmpty {
            return true
        }

        // Verifica ogni blocco
        for block in blocks {
            // I blocchi di riposo sono validi anche senza esercizi
            if block.blockType != .rest && block.exerciseItems.isEmpty {
                return true
            }

            // Se è un metodo, verifica i vincoli min/max esercizi
            if block.blockType == .method, let method = block.methodType {
                let exerciseCount = block.exerciseItems.count

                // Verifica minimo
                if exerciseCount < method.minExercises {
                    return true
                }

                // Verifica massimo se presente
                if let max = method.maxExercises, exerciseCount > max {
                    return true
                }
            }
        }

        return false
    }
}

// MARK: - WorkoutBlock Duration Estimation
extension WorkoutBlock {
    /// Stima della durata del blocco in secondi
    var estimatedDurationSeconds: TimeInterval {
        if blockType == .rest {
            return globalRestTime ?? 0
        }
        // Tempo di recupero totale: globalSets - 1 (recupero tra le serie) * globalRestTime
        let totalRestTime = Double(max(0, globalSets - 1)) * (globalRestTime ?? 0)

        // Tempo di esecuzione degli esercizi
        var executionTime: TimeInterval = 0

        for exerciseItem in exerciseItems {
            // Per ogni esercizio, calcola il tempo di esecuzione delle sue serie
            for set in exerciseItem.sets {
                switch set.setType {
                case .reps:
                    // 1 secondo per ripetizione (stima)
                    executionTime += TimeInterval(set.reps ?? 10)
                case .duration:
                    // Usa la durata specificata
                    executionTime += set.duration ?? 30
                }
            }
        }

        // Se è un metodo con esercizi multipli (superset, triset, etc.),
        // gli esercizi vengono fatti consecutivamente, quindi il tempo è la somma
        // Se è un esercizio singolo, il tempo è quello calcolato

        return totalRestTime + executionTime
    }
}
