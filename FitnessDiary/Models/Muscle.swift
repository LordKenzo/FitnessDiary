import Foundation
import SwiftData

@Model
final class Muscle: Identifiable {
    var id: UUID
    var name: String
    var category: MuscleCategory

    init(
        id: UUID = UUID(),
        name: String,
        category: MuscleCategory
    ) {
        self.id = id
        self.name = name
        self.category = category
    }
}

enum MuscleCategory: String, Codable, CaseIterable {
    case chest = "Petto"
    case back = "Schiena"
    case shoulders = "Spalle"
    case biceps = "Bicipiti"
    case triceps = "Tricipiti"
    case forearms = "Avambracci"
    case abs = "Addominali"
    case quadriceps = "Quadricipiti"
    case hamstrings = "Femorali"
    case glutes = "Glutei"
    case calves = "Polpacci"

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .biceps: return "figure.strengthtraining.traditional"
        case .triceps: return "figure.strengthtraining.traditional"
        case .forearms: return "hand.raised"
        case .abs: return "figure.core.training"
        case .quadriceps: return "figure.run"
        case .hamstrings: return "figure.run"
        case .glutes: return "figure.stairs"
        case .calves: return "figure.walk"
        }
    }
}
