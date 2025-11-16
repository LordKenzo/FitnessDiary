import Foundation
import SwiftData

@Model
final class WorkoutBlock: Identifiable {
    var id: UUID
    var order: Int
    var blockType: BlockType
    var methodType: MethodType? // solo se blockType == .method

    // Parametri globali del blocco
    var globalSets: Int // numero di serie totali del blocco (es. 3 superset)
    var globalRestTime: TimeInterval? // recupero tra le serie del blocco
    var notes: String?

    @Relationship(deleteRule: .cascade)
    var exerciseItems: [WorkoutExerciseItem] // lista esercizi nel blocco

    init(order: Int, blockType: BlockType = .simple, methodType: MethodType? = nil, globalSets: Int = 3, globalRestTime: TimeInterval? = 60, notes: String? = nil, exerciseItems: [WorkoutExerciseItem] = []) {
        self.id = UUID()
        self.order = order
        self.blockType = blockType
        self.methodType = methodType
        self.globalSets = globalSets
        self.globalRestTime = globalRestTime
        self.notes = notes
        self.exerciseItems = exerciseItems
    }

    // Helper per il titolo del blocco
    var title: String {
        if blockType == .method, let method = methodType {
            return method.rawValue
        } else {
            if let firstExercise = exerciseItems.first?.exercise {
                return firstExercise.name
            }
            return "Esercizio"
        }
    }

    // Helper per il sottotitolo
    var subtitle: String {
        if blockType == .method {
            return "\(exerciseItems.count) esercizi • \(globalSets) serie"
        } else {
            let totalSets = exerciseItems.first?.sets.count ?? 0
            return "\(totalSets) serie"
        }
    }

    // Helper per formattare il tempo di recupero
    var formattedRestTime: String? {
        guard let restTime = globalRestTime else { return nil }
        let minutes = Int(restTime) / 60
        let seconds = Int(restTime) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
