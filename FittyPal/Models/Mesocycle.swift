//
//  Mesocycle.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData

/// Mesociclo: blocco di allenamento di 3-6 settimane
/// RF2: Il sistema suddivide il piano in mesocicli assegnando tipo, profilo forza e pattern di carico
@Model
final class Mesocycle {
    var id: UUID
    var order: Int // Posizione nel piano (1, 2, 3...)
    var name: String
    var startDate: Date
    var endDate: Date

    // RF2: Tipo del mesociclo (accumulo, intensificazione, trasformazione)
    var phaseType: PhaseType

    // RF2: Profilo di forza in focus (può differire dal piano principale)
    var focusStrengthProfile: StrengthExpressionType

    // RF2: Pattern di carico (es. 3 settimane carico + 1 scarico)
    var loadWeeks: Int // Settimane di carico attivo
    var deloadWeeks: Int // Settimane di scarico (min 1 per RF3)

    // Note e descrizione
    var notes: String?

    // Relazioni
    var plan: PeriodizationPlan?

    @Relationship(deleteRule: .cascade, inverse: \Microcycle.mesocycle)
    var microcycles: [Microcycle] = []

    init(
        id: UUID = UUID(),
        order: Int,
        name: String,
        startDate: Date,
        endDate: Date,
        phaseType: PhaseType,
        focusStrengthProfile: StrengthExpressionType,
        loadWeeks: Int = 3,
        deloadWeeks: Int = 1,
        notes: String? = nil,
        plan: PeriodizationPlan? = nil
    ) {
        self.id = id
        self.order = order
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.phaseType = phaseType
        self.focusStrengthProfile = focusStrengthProfile
        self.loadWeeks = loadWeeks
        self.deloadWeeks = deloadWeeks
        self.notes = notes
        self.plan = plan
    }

    // MARK: - Computed Properties

    /// Durata totale in settimane
    var durationInWeeks: Int {
        loadWeeks + deloadWeeks
    }

    /// Durata in giorni
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    /// Verifica se il mesociclo è in corso
    func isCurrentlyActive(at date: Date = Date()) -> Bool {
        return date >= startDate && date <= endDate
    }

    /// Progresso percentuale del mesociclo
    func progressPercentage(at date: Date = Date()) -> Double {
        guard date >= startDate else { return 0.0 }
        guard date <= endDate else { return 100.0 }

        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = date.timeIntervalSince(startDate)

        return (elapsed / totalDuration) * 100.0
    }

    /// Ottieni microcicli ordinati
    var sortedMicrocycles: [Microcycle] {
        microcycles.sorted { $0.order < $1.order }
    }

    /// Verifica se contiene almeno una settimana di scarico (RF3)
    var hasDeloadWeek: Bool {
        deloadWeeks >= 1
    }
}
