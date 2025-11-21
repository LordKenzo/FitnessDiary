//
//  PeriodizationTemplate.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData

/// Template di periodizzazione riutilizzabile
/// Permette di salvare configurazioni di piani per riuso futuro (punto 6)
@Model
final class PeriodizationTemplate {
    var id: UUID
    var name: String
    var periodizationDescription: String?
    var createdAt: Date

    // Configurazione template
    var periodizationModel: PeriodizationModel
    var primaryStrengthProfile: StrengthExpressionType
    var secondaryStrengthProfile: StrengthExpressionType?
    var weeklyFrequency: Int

    // Durata consigliata in settimane
    var recommendedDurationWeeks: Int

    // Pattern mesocicli (configurazione serializzata)
    var mesocyclePattern: String? // JSON serializzato con pattern mesocicli

    // Configurazione auto-progressione
    var autoProgressionEnabled: Bool
    var baseProgressionPercentage: Double // es. 2.5% = 0.025

    // Template pubblico (condivisibile) o privato
    var isPublic: Bool

    // Autore (trainer che ha creato il template)
    var createdByUserId: UUID?
    var createdByClientId: UUID?

    // Statistiche utilizzo
    var usageCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        periodizationDescription: String? = nil,
        periodizationModel: PeriodizationModel,
        primaryStrengthProfile: StrengthExpressionType,
        secondaryStrengthProfile: StrengthExpressionType? = nil,
        weeklyFrequency: Int,
        recommendedDurationWeeks: Int,
        mesocyclePattern: String? = nil,
        autoProgressionEnabled: Bool = true,
        baseProgressionPercentage: Double = 0.025,
        isPublic: Bool = false,
        createdByUserId: UUID? = nil,
        createdByClientId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.periodizationDescription = periodizationDescription
        self.createdAt = Date()
        self.periodizationModel = periodizationModel
        self.primaryStrengthProfile = primaryStrengthProfile
        self.secondaryStrengthProfile = secondaryStrengthProfile
        self.weeklyFrequency = weeklyFrequency
        self.recommendedDurationWeeks = recommendedDurationWeeks
        self.mesocyclePattern = mesocyclePattern
        self.autoProgressionEnabled = autoProgressionEnabled
        self.baseProgressionPercentage = baseProgressionPercentage
        self.isPublic = isPublic
        self.createdByUserId = createdByUserId
        self.createdByClientId = createdByClientId
        self.usageCount = 0
    }

    // MARK: - Template Pattern Structure

    struct MesocyclePatternItem: Codable {
        var order: Int
        var phaseType: PhaseType
        var focusStrengthProfile: StrengthExpressionType
        var loadWeeks: Int
        var deloadWeeks: Int
    }

    /// Decodifica il pattern dei mesocicli
    func decodedMesocyclePattern() -> [MesocyclePatternItem]? {
        guard let patternString = mesocyclePattern,
              let data = patternString.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode([MesocyclePatternItem].self, from: data)
    }

    /// Codifica il pattern dei mesocicli
    static func encodeMesocyclePattern(_ pattern: [MesocyclePatternItem]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(pattern),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    /// Incrementa contatore utilizzo
    func incrementUsage() {
        usageCount += 1
    }
}
