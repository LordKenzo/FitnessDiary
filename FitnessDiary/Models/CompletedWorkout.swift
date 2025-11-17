//
//  CompletedWorkout.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import Foundation
import SwiftData

/// Allenamento completato - salvato nello storico
@Model
final class CompletedWorkout: Identifiable {
    var id: UUID

    // Riferimenti
    var workoutCard: WorkoutCard  // Scheda allenamento utilizzata
    var client: Client?  // Cliente (se l'allenamento era per un cliente)

    // Timing
    var completedDate: Date  // Data completamento (usata per ordinamento storico)
    var startTime: Date  // Orario inizio effettivo
    var endTime: Date  // Orario fine effettivo
    var totalDuration: TimeInterval  // Durata totale (incluse pause)
    var activeDuration: TimeInterval  // Durata attiva (escluse pause)
    var totalPausedTime: TimeInterval  // Tempo totale in pausa

    // Performance tracking
    @Relationship(deleteRule: .cascade)
    var performances: [SetPerformance]  // Tutte le serie completate

    // Feedback soggettivo
    var notes: String?  // Note generali sull'allenamento
    var overallRating: Double?  // Valutazione generale (1-5 stelle)
    var averageRPE: Double?  // RPE medio della sessione

    // Metadata utili
    var wasCompletelyFinished: Bool  // True se tutti gli esercizi sono stati completati
    var totalSetsCompleted: Int  // Numero totale di serie completate
    var totalSetsPlanned: Int  // Numero totale di serie pianificate

    init(
        id: UUID = UUID(),
        workoutCard: WorkoutCard,
        client: Client? = nil,
        completedDate: Date = Date(),
        startTime: Date,
        endTime: Date = Date(),
        totalDuration: TimeInterval,
        activeDuration: TimeInterval,
        totalPausedTime: TimeInterval,
        performances: [SetPerformance] = [],
        notes: String? = nil,
        overallRating: Double? = nil,
        averageRPE: Double? = nil,
        wasCompletelyFinished: Bool = false,
        totalSetsCompleted: Int = 0,
        totalSetsPlanned: Int = 0
    ) {
        self.id = id
        self.workoutCard = workoutCard
        self.client = client
        self.completedDate = completedDate
        self.startTime = startTime
        self.endTime = endTime
        self.totalDuration = totalDuration
        self.activeDuration = activeDuration
        self.totalPausedTime = totalPausedTime
        self.performances = performances
        self.notes = notes
        self.overallRating = overallRating
        self.averageRPE = averageRPE
        self.wasCompletelyFinished = wasCompletelyFinished
        self.totalSetsCompleted = totalSetsCompleted
        self.totalSetsPlanned = totalSetsPlanned
    }

    // MARK: - Factory Method

    /// Crea un CompletedWorkout da una WorkoutSession completata
    static func fromSession(_ session: WorkoutSession) -> CompletedWorkout {
        let endTime = Date()
        let totalDuration = endTime.timeIntervalSince(session.startDate)

        // Calcola RPE medio
        let rpeValues = session.completedSets.compactMap { $0.rpe }
        let avgRPE = rpeValues.isEmpty ? nil : rpeValues.reduce(0, +) / Double(rpeValues.count)

        // Clone SetPerformance objects to prevent cascade delete
        // When session is deleted, its completedSets will be cascade-deleted
        // We need independent copies for the CompletedWorkout
        let clonedPerformances = session.completedSets.map { originalPerformance in
            SetPerformance(
                blockIndex: originalPerformance.blockIndex,
                exerciseIndex: originalPerformance.exerciseIndex,
                setIndex: originalPerformance.setIndex,
                round: originalPerformance.round,
                actualReps: originalPerformance.actualReps,
                actualWeight: originalPerformance.actualWeight,
                actualDuration: originalPerformance.actualDuration,
                completedAt: originalPerformance.completedAt,
                notes: originalPerformance.notes,
                rpe: originalPerformance.rpe,
                clusterTimings: originalPerformance.clusterTimings,
                clusterReps: originalPerformance.clusterReps,
                restPauseReps: originalPerformance.restPauseReps
            )
        }

        return CompletedWorkout(
            workoutCard: session.workoutCard,
            client: session.client,
            completedDate: endTime,
            startTime: session.startDate,
            endTime: endTime,
            totalDuration: totalDuration,
            activeDuration: session.activeDuration,
            totalPausedTime: session.totalPausedTime,
            performances: clonedPerformances,
            notes: session.notes,
            averageRPE: avgRPE,
            wasCompletelyFinished: session.isCompleted,
            totalSetsCompleted: session.completedSets.count,
            totalSetsPlanned: session.workoutCard.totalSets
        )
    }

    // MARK: - Computed Properties

    /// Percentuale di completamento
    var completionPercentage: Double {
        guard totalSetsPlanned > 0 else { return 0 }
        return Double(totalSetsCompleted) / Double(totalSetsPlanned) * 100.0
    }

    /// Durata formattata (HH:mm:ss)
    var formattedDuration: String {
        let hours = Int(activeDuration) / 3600
        let minutes = (Int(activeDuration) % 3600) / 60
        let seconds = Int(activeDuration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Durata breve formattata (es. "45min")
    var shortDuration: String {
        let minutes = Int(activeDuration) / 60
        if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)min"
            } else {
                return "\(hours)h"
            }
        }
    }

    /// Data formattata per visualizzazione
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedDate)
    }

    /// Rating formattato
    var formattedRating: String? {
        guard let rating = overallRating else { return nil }
        let stars = String(repeating: "⭐️", count: Int(rating))
        return stars
    }

    /// RPE medio formattato
    var formattedAverageRPE: String? {
        guard let rpe = averageRPE else { return nil }
        return String(format: "RPE %.1f/10", rpe)
    }

    // MARK: - Statistics

    /// Totale kg sollevati nella sessione
    var totalWeightLifted: Double {
        return performances.reduce(0) { total, performance in
            let weight = performance.actualWeight ?? 0
            let reps = performance.actualReps ?? 0
            return total + (weight * Double(reps))
        }
    }

    /// Peso medio per serie
    var averageWeight: Double? {
        let weights = performances.compactMap { $0.actualWeight }
        guard !weights.isEmpty else { return nil }
        return weights.reduce(0, +) / Double(weights.count)
    }

    /// Ripetizioni medie per serie
    var averageReps: Double? {
        let reps = performances.compactMap { $0.actualReps }
        guard !reps.isEmpty else { return nil }
        return Double(reps.reduce(0, +)) / Double(reps.count)
    }

    /// Serie per esercizio (raggruppate)
    func performancesByExercise() -> [String: [SetPerformance]] {
        var grouped: [String: [SetPerformance]] = [:]

        for performance in performances {
            // Trova l'esercizio corrispondente
            if let block = workoutCard.blocks[safe: performance.blockIndex],
               let exerciseItem = block.exerciseItems[safe: performance.exerciseIndex],
               let exercise = exerciseItem.exercise {
                let key = exercise.name
                grouped[key, default: []].append(performance)
            }
        }

        return grouped
    }

    /// Trova performance per un esercizio specifico
    func performances(for exerciseName: String) -> [SetPerformance] {
        return performancesByExercise()[exerciseName] ?? []
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
