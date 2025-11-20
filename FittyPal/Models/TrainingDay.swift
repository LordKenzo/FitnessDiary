//
//  TrainingDay.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData

/// Giorno di allenamento nel piano di periodizzazione
@Model
final class TrainingDay {
    var id: UUID
    var date: Date
    var dayOfWeek: Int // 1-7 (1 = lunedì, 7 = domenica)

    // Tipo di allenamento pianificato per questo giorno
    var plannedSplitType: SplitType?

    // Flag per giorni di riposo
    var isRestDay: Bool

    // Scheda associata (l'utente configura manualmente)
    var workoutCard: WorkoutCard?

    // Note per il giorno
    var notes: String?

    // Tracking esecuzione
    var completed: Bool
    var completedAt: Date?

    // Relazione al log di sessione (se completato)
    var sessionLog: WorkoutSessionLog?

    // Relazioni
    var microcycle: Microcycle?

    init(
        id: UUID = UUID(),
        date: Date,
        dayOfWeek: Int? = nil,
        plannedSplitType: SplitType? = nil,
        isRestDay: Bool = false,
        workoutCard: WorkoutCard? = nil,
        notes: String? = nil,
        completed: Bool = false,
        completedAt: Date? = nil,
        sessionLog: WorkoutSessionLog? = nil,
        microcycle: Microcycle? = nil
    ) {
        self.id = id
        self.date = date
        // Calcola automaticamente dayOfWeek se non specificato
        self.dayOfWeek = dayOfWeek ?? Calendar.current.component(.weekday, from: date)
        self.plannedSplitType = plannedSplitType
        self.isRestDay = isRestDay
        self.workoutCard = workoutCard
        self.notes = notes
        self.completed = completed
        self.completedAt = completedAt
        self.sessionLog = sessionLog
        self.microcycle = microcycle
    }

    // MARK: - Computed Properties

    /// Nome del giorno della settimana
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized
    }

    /// Nome breve del giorno (es. Lun, Mar...)
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }

    /// Verifica se il giorno è passato
    var isPast: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date()) == false && date < Date()
    }

    /// Verifica se è oggi
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }

    /// Verifica se è futuro
    var isFuture: Bool {
        date > Date() && !isToday
    }

    /// Segna il giorno come completato
    func markCompleted(with log: WorkoutSessionLog? = nil) {
        completed = true
        completedAt = Date()
        sessionLog = log
    }

    /// Rimuovi completamento
    func markIncomplete() {
        completed = false
        completedAt = nil
        sessionLog = nil
    }
}
