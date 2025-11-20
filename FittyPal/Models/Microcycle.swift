//
//  Microcycle.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData

/// Microciclo: settimana di allenamento
/// RF3: Include settimane di scarico con loadLevel = LOW
/// RF4/RF5: Contiene fattori di intensità e volume per modulare le schede
@Model
final class Microcycle {
    var id: UUID
    var order: Int // Posizione nel mesociclo (1, 2, 3...)
    var weekNumber: Int // Settimana assoluta nel piano (1-52)
    var startDate: Date
    var endDate: Date

    // RF3: Livello di carico (HIGH, MEDIUM, LOW per scarico)
    var loadLevel: LoadLevel

    // RF4/RF5: Fattori per modulare intensità e volume della scheda
    var intensityFactor: Double // 0.5-1.2 (es. 0.7 per scarico, 1.0 normale, 1.15 intensificazione)
    var volumeFactor: Double // 0.5-1.2 (es. 0.6 per scarico, 1.0 normale, 1.2 accumulo)

    // Progressione automatica carico: incremento % rispetto settimana precedente
    var loadProgressionPercentage: Double // es. 2.5% = 0.025

    // Note
    var notes: String?

    // Relazioni
    var mesocycle: Mesocycle?

    @Relationship(deleteRule: .cascade, inverse: \TrainingDay.microcycle)
    var trainingDays: [TrainingDay] = []

    init(
        id: UUID = UUID(),
        order: Int,
        weekNumber: Int,
        startDate: Date,
        endDate: Date,
        loadLevel: LoadLevel,
        intensityFactor: Double? = nil,
        volumeFactor: Double? = nil,
        loadProgressionPercentage: Double = 0.025,
        notes: String? = nil,
        mesocycle: Mesocycle? = nil
    ) {
        self.id = id
        self.order = order
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.loadLevel = loadLevel
        // Usa fattori predefiniti se non specificati
        self.intensityFactor = intensityFactor ?? loadLevel.defaultIntensityFactor
        self.volumeFactor = volumeFactor ?? loadLevel.defaultVolumeFactor
        self.loadProgressionPercentage = loadProgressionPercentage
        self.notes = notes
        self.mesocycle = mesocycle
    }

    // MARK: - Computed Properties

    /// Verifica se è settimana di scarico (RF3)
    var isDeloadWeek: Bool {
        loadLevel == .low
    }

    /// Verifica se il microciclo è in corso
    func isCurrentlyActive(at date: Date = Date()) -> Bool {
        return date >= startDate && date <= endDate
    }

    /// Progresso percentuale della settimana
    func progressPercentage(at date: Date = Date()) -> Double {
        guard date >= startDate else { return 0.0 }
        guard date <= endDate else { return 100.0 }

        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = date.timeIntervalSince(startDate)

        return (elapsed / totalDuration) * 100.0
    }

    /// Giorni ordinati
    var sortedTrainingDays: [TrainingDay] {
        trainingDays.sorted { $0.date < $1.date }
    }

    /// Giorni completati (esclusi giorni di riposo)
    var completedDays: Int {
        trainingDays.filter { !$0.isRestDay && $0.completed }.count
    }

    /// Giorni totali pianificati (esclusi giorni di riposo)
    var totalPlannedDays: Int {
        trainingDays.filter { !$0.isRestDay }.count
    }

    /// Percentuale completamento settimana (solo giorni allenamento)
    var completionPercentage: Double {
        guard totalPlannedDays > 0 else { return 0.0 }
        return (Double(completedDays) / Double(totalPlannedDays)) * 100.0
    }

    // MARK: - Volume Statistics

    /// Numero totale di esercizi pianificati nella settimana
    var totalWeeklyExercises: Int {
        trainingDays
            .filter { !$0.isRestDay }
            .compactMap { $0.workoutCard }
            .reduce(0) { $0 + $1.totalExercises }
    }

    /// Numero totale di serie pianificate nella settimana
    var totalWeeklySets: Int {
        trainingDays
            .filter { !$0.isRestDay }
            .compactMap { $0.workoutCard }
            .reduce(0) { $0 + $1.totalSets }
    }

    /// Durata totale stimata della settimana in minuti
    var totalWeeklyDurationMinutes: Int {
        trainingDays
            .filter { !$0.isRestDay }
            .compactMap { $0.workoutCard }
            .reduce(0) { $0 + $1.estimatedDurationMinutes }
    }

    /// Numero di schede assegnate (giorni con workout card)
    var assignedWorkoutCount: Int {
        trainingDays.filter { !$0.isRestDay && $0.workoutCard != nil }.count
    }

    /// Verifica se tutte le schede sono state assegnate
    var hasAllWorkoutsAssigned: Bool {
        assignedWorkoutCount == totalPlannedDays
    }

    /// Verifica se almeno una scheda è stata assegnata
    var hasAnyWorkoutAssigned: Bool {
        assignedWorkoutCount > 0
    }
}
