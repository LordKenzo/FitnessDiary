import Foundation
import SwiftData

@Model
final class Equipment: Identifiable {
    var id: UUID
    var name: String
    var category: EquipmentCategory

    init(
        id: UUID = UUID(),
        name: String,
        category: EquipmentCategory
    ) {
        self.id = id
        self.name = name
        self.category = category
    }
}

enum EquipmentCategory: String, Codable, CaseIterable {
    case bodyweight = "Corpo Libero"
    case barbell = "Bilanciere"
    case dumbbell = "Manubri"
    case machine = "Macchine"
    case kettlebell = "Kettlebell"
    case cable = "Cavi"
    case band = "Bande Elastiche"
    case trx = "TRX/Sospensione"
    case cardio = "Cardio"
    case other = "Altro"

    var icon: String {
        switch self {
        case .bodyweight: return "figure.walk"
        case .barbell: return "scalemass"
        case .dumbbell: return "dumbbell"
        case .machine: return "gearshape.2"
        case .kettlebell: return "figure.strengthtraining.traditional"
        case .cable: return "cable.connector"
        case .band: return "waveform.path"
        case .trx: return "triangle"
        case .cardio: return "heart.circle"
        case .other: return "cube.box"
        }
    }
}
