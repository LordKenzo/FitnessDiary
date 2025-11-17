//
//  SetPerformance.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import Foundation
import SwiftData

/// Rappresenta la performance effettiva registrata per una singola serie durante l'esecuzione
@Model
final class SetPerformance: Identifiable {
    var id: UUID

    // Identificazione della serie nel contesto della WorkoutCard
    var blockIndex: Int  // Indice del blocco nella scheda
    var exerciseIndex: Int  // Indice dell'esercizio nel blocco
    var setIndex: Int  // Indice della serie nell'esercizio
    var round: Int?  // Round per metodologie multi-round (Tabata, Circuit)

    // Performance effettiva registrata
    var actualReps: Int?  // Ripetizioni effettivamente eseguite
    var actualWeight: Double?  // Peso effettivamente sollevato (kg)
    var actualDuration: TimeInterval?  // Durata effettiva per esercizi a tempo

    // Metadata
    var completedAt: Date  // Timestamp completamento
    var notes: String?  // Note sulla serie (es. "difficoltà tecnica", "dolore")
    var rpe: Double?  // Rate of Perceived Exertion (1-10 scala)

    // Cluster Set tracking (opzionale)
    var clusterTimings: [TimeInterval]?  // Durate effettive di ogni cluster
    var clusterReps: [Int]?  // Reps effettive per ogni cluster

    // Rest-Pause tracking (opzionale)
    var restPauseReps: [Int]?  // Reps per ogni segmento del rest-pause

    init(
        id: UUID = UUID(),
        blockIndex: Int,
        exerciseIndex: Int,
        setIndex: Int,
        round: Int? = nil,
        actualReps: Int? = nil,
        actualWeight: Double? = nil,
        actualDuration: TimeInterval? = nil,
        completedAt: Date = Date(),
        notes: String? = nil,
        rpe: Double? = nil,
        clusterTimings: [TimeInterval]? = nil,
        clusterReps: [Int]? = nil,
        restPauseReps: [Int]? = nil
    ) {
        self.id = id
        self.blockIndex = blockIndex
        self.exerciseIndex = exerciseIndex
        self.setIndex = setIndex
        self.round = round
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.actualDuration = actualDuration
        self.completedAt = completedAt
        self.notes = notes
        self.rpe = rpe
        self.clusterTimings = clusterTimings
        self.clusterReps = clusterReps
        self.restPauseReps = restPauseReps
    }

    // MARK: - Helpers

    /// Verifica se la serie è stata completata con successo
    var isCompleted: Bool {
        // Almeno uno dei campi performance deve essere valorizzato
        return actualReps != nil || actualWeight != nil || actualDuration != nil
    }

    /// Descrizione testuale della performance
    var performanceDescription: String {
        var parts: [String] = []

        if let reps = actualReps {
            parts.append("\(reps) reps")
        }

        if let weight = actualWeight {
            parts.append("\(String(format: "%.1f", weight)) kg")
        }

        if let duration = actualDuration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            if minutes > 0 {
                parts.append("\(minutes)m \(seconds)s")
            } else {
                parts.append("\(seconds)s")
            }
        }

        return parts.joined(separator: " • ")
    }

    /// Descrizione RPE formattata
    var rpeDescription: String? {
        guard let rpe = rpe else { return nil }
        return String(format: "RPE %.1f/10", rpe)
    }

    /// Calcola la percentuale di completamento rispetto al target
    func completionPercentage(targetReps: Int?, targetWeight: Double?, targetDuration: TimeInterval?) -> Double? {
        // Priorità: reps, peso, durata

        // 1. Calcoliamo in base alle reps se disponibili
        if let actual = actualReps, let target = targetReps, target > 0 {
            return Double(actual) / Double(target) * 100.0
        }

        // 2. Altrimenti in base al peso
        if let actual = actualWeight, let target = targetWeight, target > 0 {
            return actual / target * 100.0
        }

        // 3. Altrimenti in base alla durata
        if let actual = actualDuration, let target = targetDuration, target > 0 {
            return actual / target * 100.0
        }

        return nil
    }
}
