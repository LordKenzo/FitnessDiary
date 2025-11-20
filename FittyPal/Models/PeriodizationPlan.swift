//
//  PeriodizationPlan.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData

/// Piano di periodizzazione dell'allenamento (Macrociclo)
/// RF1: L'utente può creare un piano inserendo data inizio, durata, profili forza, frequenza e modello
@Model
final class PeriodizationPlan {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var createdAt: Date

    // RF1: Modello di periodizzazione
    var periodizationModel: PeriodizationModel

    // RF1: Profili di forza
    var primaryStrengthProfile: StrengthExpressionType
    var secondaryStrengthProfile: StrengthExpressionType?

    // RF1: Frequenza settimanale (numero allenamenti/settimana)
    var weeklyFrequency: Int

    // Giorni settimanali di allenamento (rawValues di Weekday)
    // Esempio: [2, 4, 6] = Lunedì, Mercoledì, Venerdì
    var trainingDaysRaw: [Int] = []

    // Opzionale: note e descrizione
    var notes: String?

    // Flag per piano attivo
    var isActive: Bool

    // Template source (se creato da template)
    var templateId: UUID?

    // Relazioni
    @Relationship(deleteRule: .cascade, inverse: \Mesocycle.plan)
    var mesocycles: [Mesocycle] = []

    @Relationship(deleteRule: .nullify)
    var folders: [PeriodizationFolder] = [] // array di folder (un piano può stare in più folder)

    var userProfile: UserProfile?
    var client: Client?

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        periodizationModel: PeriodizationModel,
        primaryStrengthProfile: StrengthExpressionType,
        secondaryStrengthProfile: StrengthExpressionType? = nil,
        weeklyFrequency: Int,
        notes: String? = nil,
        isActive: Bool = true,
        templateId: UUID? = nil,
        userProfile: UserProfile? = nil,
        client: Client? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.periodizationModel = periodizationModel
        self.primaryStrengthProfile = primaryStrengthProfile
        self.secondaryStrengthProfile = secondaryStrengthProfile
        self.weeklyFrequency = weeklyFrequency
        self.notes = notes
        self.isActive = isActive
        self.templateId = templateId
        self.userProfile = userProfile
        self.client = client
    }

    // MARK: - Computed Properties

    /// Giorni di allenamento come enum Weekday
    var trainingDays: [Weekday] {
        get {
            trainingDaysRaw.compactMap { Weekday(rawValue: $0) }.sorted { $0.rawValue < $1.rawValue }
        }
        set {
            trainingDaysRaw = newValue.map { $0.rawValue }
        }
    }

    /// Verifica se i giorni di allenamento sono configurati
    var hasTrainingDaysConfigured: Bool {
        !trainingDaysRaw.isEmpty
    }

    /// Durata totale in giorni
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    /// Durata in settimane
    var durationInWeeks: Int {
        Int(ceil(Double(durationInDays) / 7.0))
    }

    /// Numero stimato di mesocicli (ipotizzando 4 settimane per mesociclo)
    var estimatedMesocycleCount: Int {
        max(1, durationInWeeks / 4)
    }

    /// Verifica se il piano è in corso
    func isCurrentlyActive(at date: Date = Date()) -> Bool {
        return isActive && date >= startDate && date <= endDate
    }

    /// Progresso percentuale del piano
    func progressPercentage(at date: Date = Date()) -> Double {
        guard date >= startDate else { return 0.0 }
        guard date <= endDate else { return 100.0 }

        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = date.timeIntervalSince(startDate)

        return (elapsed / totalDuration) * 100.0
    }

    // MARK: - Folder Helpers

    /// Helper per sapere se il piano è in un folder specifico
    func isInFolder(_ folder: PeriodizationFolder) -> Bool {
        folders.contains { $0.id == folder.id }
    }

    /// Helper per sapere se il piano non ha folder
    var hasNoFolders: Bool {
        folders.isEmpty
    }
}
