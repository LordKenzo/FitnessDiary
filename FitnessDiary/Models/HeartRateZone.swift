import SwiftUI

enum HeartRateZone: Int, CaseIterable {
    case zone1 = 1
    case zone2 = 2
    case zone3 = 3
    case zone4 = 4
    case zone5 = 5
    
    var name: String {
        switch self {
        case .zone1: return "Zona 1 - Recupero"
        case .zone2: return "Zona 2 - Endurance"
        case .zone3: return "Zona 3 - Tempo"
        case .zone4: return "Zona 4 - Soglia"
        case .zone5: return "Zona 5 - VO2 Max"
        }
    }
    
    var description: String {
        switch self {
        case .zone1: return "50-60% FC Max - Recupero attivo"
        case .zone2: return "60-70% FC Max - Resistenza aerobica"
        case .zone3: return "70-80% FC Max - Allenamento aerobico"
        case .zone4: return "80-90% FC Max - Soglia anaerobica"
        case .zone5: return "90-100% FC Max - Capacità massima"
        }
    }
    
    var color: Color {
        switch self {
        case .zone1: return .blue
        case .zone2: return .green
        case .zone3: return .yellow
        case .zone4: return .orange
        case .zone5: return .red
        }
    }
    
    var percentage: (min: Double, max: Double) {
        switch self {
        case .zone1: return (0.50, 0.60)
        case .zone2: return (0.60, 0.70)
        case .zone3: return (0.70, 0.80)
        case .zone4: return (0.80, 0.90)
        case .zone5: return (0.90, 1.00)
        }
    }
}
