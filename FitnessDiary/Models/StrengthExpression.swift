//
//  StrengthExpression.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import Foundation
import SwiftData

// Tipo di espressione di forza
enum StrengthExpressionType: String, Codable, CaseIterable, Identifiable {
    case maxStrength = "Forza Massima"
    case maxDynamicStrength = "Forza Dinamica Massima"
    case speedStrength = "Forza Rapida"
    case resistantStrength = "Forza Resistente"
    case hypertrophy = "Ipertrofia"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .maxStrength:
            return "bolt.fill"
        case .maxDynamicStrength:
            return "bolt.horizontal.fill"
        case .speedStrength:
            return "hare.fill"
        case .resistantStrength:
            return "tortoise.fill"
        case .hypertrophy:
            return "figure.strengthtraining.traditional"
        }
    }
}

// Parametri configurabili per ogni espressione di forza
@Model
final class StrengthExpressionParameters {
    var type: StrengthExpressionType

    // Range percentuale di carico rispetto a 1-RM
    var loadPercentageMin: Double
    var loadPercentageMax: Double

    // Range serie
    var setsMin: Int
    var setsMax: Int

    // Range ripetizioni
    var repsMin: Int
    var repsMax: Int

    // Range tempo di recupero (in secondi)
    var restTimeMin: Double
    var restTimeMax: Double

    init(
        type: StrengthExpressionType,
        loadPercentageMin: Double,
        loadPercentageMax: Double,
        setsMin: Int,
        setsMax: Int,
        repsMin: Int,
        repsMax: Int,
        restTimeMin: Double,
        restTimeMax: Double
    ) {
        self.type = type
        self.loadPercentageMin = loadPercentageMin
        self.loadPercentageMax = loadPercentageMax
        self.setsMin = setsMin
        self.setsMax = setsMax
        self.repsMin = repsMin
        self.repsMax = repsMax
        self.restTimeMin = restTimeMin
        self.restTimeMax = restTimeMax
    }

    // Valori di default per ogni tipo
    static func defaultParameters(for type: StrengthExpressionType) -> StrengthExpressionParameters {
        switch type {
        case .maxStrength:
            return StrengthExpressionParameters(
                type: type,
                loadPercentageMin: 70,
                loadPercentageMax: 100,
                setsMin: 4,
                setsMax: 6,
                repsMin: 1,
                repsMax: 6,
                restTimeMin: 120, // 2 minuti
                restTimeMax: 300  // 5 minuti
            )

        case .maxDynamicStrength:
            return StrengthExpressionParameters(
                type: type,
                loadPercentageMin: 30,
                loadPercentageMax: 70,
                setsMin: 4,
                setsMax: 6,
                repsMin: 6,
                repsMax: 8,
                restTimeMin: 90,  // 1:30
                restTimeMax: 150  // 2:30
            )

        case .speedStrength:
            return StrengthExpressionParameters(
                type: type,
                loadPercentageMin: 0,
                loadPercentageMax: 30,
                setsMin: 4,
                setsMax: 6,
                repsMin: 2,
                repsMax: 6,
                restTimeMin: 120, // 2 minuti
                restTimeMax: 180  // 3 minuti
            )

        case .resistantStrength:
            return StrengthExpressionParameters(
                type: type,
                loadPercentageMin: 20,
                loadPercentageMax: 100,
                setsMin: 3,
                setsMax: 5,
                repsMin: 12,
                repsMax: 20,
                restTimeMin: 90,  // 1:30
                restTimeMax: 150  // 2:30
            )

        case .hypertrophy:
            return StrengthExpressionParameters(
                type: type,
                loadPercentageMin: 70,
                loadPercentageMax: 95,
                setsMin: 4,
                setsMax: 6,
                repsMin: 6,
                repsMax: 12,
                restTimeMin: 90,  // 1:30
                restTimeMax: 150  // 2:30
            )
        }
    }

    // Verifica se i parametri di un esercizio rientrano nei range
    func isLoadInRange(_ loadPercentage: Double) -> Bool {
        return loadPercentage >= loadPercentageMin && loadPercentage <= loadPercentageMax
    }

    func areSetsInRange(_ sets: Int) -> Bool {
        return sets >= setsMin && sets <= setsMax
    }

    func areRepsInRange(_ reps: Int) -> Bool {
        return reps >= repsMin && reps <= repsMax
    }

    func isRestTimeInRange(_ restTime: Double) -> Bool {
        return restTime >= restTimeMin && restTime <= restTimeMax
    }

    // Formato leggibile del tempo di recupero
    var restTimeMinFormatted: String {
        formatTime(restTimeMin)
    }

    var restTimeMaxFormatted: String {
        formatTime(restTimeMax)
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if secs == 0 {
            return "\(minutes)'"
        } else {
            return "\(minutes)'\(secs)\""
        }
    }
}
