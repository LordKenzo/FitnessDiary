import Foundation

enum Big5Exercise: String, Codable, CaseIterable, Identifiable {
    case benchPress = "Panca Piana"
    case deadlift = "Stacco"
    case militaryPress = "Military Press"
    case hipThrust = "Hip Thrust"
    case squat = "Squat"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .benchPress:
            return "figure.strengthtraining.traditional"
        case .deadlift:
            return "figure.strengthtraining.functional"
        case .militaryPress:
            return "figure.arms.open"
        case .hipThrust:
            return "figure.strengthtraining.traditional"
        case .squat:
            return "figure.squat"
        }
    }
}
