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

    /// Tenta di mappare il nome dell'esercizio a un Big5Exercise
    /// Cerca corrispondenze case-insensitive nel nome
    static func from(exerciseName: String) -> Big5Exercise? {
        let lowercasedName = exerciseName.lowercased()

        // Panca Piana - varianti comuni
        if lowercasedName.contains("panca") && (lowercasedName.contains("piana") || lowercasedName.contains("bilanciere")) {
            return .benchPress
        }
        if lowercasedName.contains("bench press") {
            return .benchPress
        }

        // Stacco - varianti comuni
        if lowercasedName.contains("stacco") || lowercasedName.contains("deadlift") {
            return .deadlift
        }

        // Military Press - varianti comuni
        if lowercasedName.contains("military") ||
           (lowercasedName.contains("lento") && lowercasedName.contains("avanti")) ||
           lowercasedName.contains("shoulder press") {
            return .militaryPress
        }

        // Hip Thrust
        if lowercasedName.contains("hip thrust") || lowercasedName.contains("ponte glutei") {
            return .hipThrust
        }

        // Squat - varianti comuni
        if lowercasedName.contains("squat") {
            return .squat
        }

        return nil
    }
}

// Extension su Exercise per facilitare l'accesso al Big5
extension Exercise {
    /// Restituisce il Big5Exercise corrispondente se l'esercizio è uno dei 5 fondamentali
    var big5Exercise: Big5Exercise? {
        return Big5Exercise.from(exerciseName: self.name)
    }
}
