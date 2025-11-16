//
//  WorkoutSession.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import Foundation
import SwiftData

/// Sessione di allenamento in corso
/// Viene persistita su SwiftData per supportare recovery da interruzioni
@Model
final class WorkoutSession: Identifiable {
    var id: UUID

    // Riferimenti
    var workoutCard: WorkoutCard  // Scheda allenamento in esecuzione
    var client: Client?  // Cliente (se l'allenamento è per un cliente)

    // Timing
    var startDate: Date  // Inizio allenamento
    var lastUpdateDate: Date  // Ultimo aggiornamento (per calcolare tempo trascorso)

    // Stato corrente dell'esecuzione
    var currentBlockIndex: Int  // Blocco corrente (0-based)
    var currentExerciseIndex: Int  // Esercizio corrente nel blocco
    var currentSetIndex: Int  // Serie corrente nell'esercizio
    var currentRound: Int  // Round corrente (per metodologie multi-round come Tabata)

    // Stato sessione
    var isCompleted: Bool  // True quando allenamento completato
    var isPaused: Bool  // True quando in pausa
    var pauseStartTime: Date?  // Timestamp inizio pausa corrente
    var totalPausedTime: TimeInterval  // Tempo totale in pausa accumulato

    // Timer state (per ripristino dopo interruzioni)
    var restTimerStartTime: Date?  // Inizio timer recupero corrente
    var restTimerDuration: TimeInterval?  // Durata totale recupero corrente

    // Performance tracking
    @Relationship(deleteRule: .cascade)
    var completedSets: [SetPerformance]  // Serie completate

    // Note generali sulla sessione
    var notes: String?

    init(
        id: UUID = UUID(),
        workoutCard: WorkoutCard,
        client: Client? = nil,
        startDate: Date = Date(),
        currentBlockIndex: Int = 0,
        currentExerciseIndex: Int = 0,
        currentSetIndex: Int = 0,
        currentRound: Int = 1,
        isCompleted: Bool = false,
        isPaused: Bool = false,
        totalPausedTime: TimeInterval = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.workoutCard = workoutCard
        self.client = client
        self.startDate = startDate
        self.lastUpdateDate = Date()
        self.currentBlockIndex = currentBlockIndex
        self.currentExerciseIndex = currentExerciseIndex
        self.currentSetIndex = currentSetIndex
        self.currentRound = currentRound
        self.isCompleted = isCompleted
        self.isPaused = isPaused
        self.pauseStartTime = nil
        self.totalPausedTime = totalPausedTime
        self.restTimerStartTime = nil
        self.restTimerDuration = nil
        self.completedSets = []
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// Durata totale della sessione (escluso tempo in pausa)
    var activeDuration: TimeInterval {
        let total = Date().timeIntervalSince(startDate)
        let paused = isPaused
            ? totalPausedTime + Date().timeIntervalSince(pauseStartTime ?? Date())
            : totalPausedTime
        return max(0, total - paused)
    }

    /// Durata totale includendo pause
    var totalDuration: TimeInterval {
        return Date().timeIntervalSince(startDate)
    }

    /// Blocco corrente
    var currentBlock: WorkoutBlock? {
        guard currentBlockIndex < workoutCard.blocks.count else { return nil }
        return workoutCard.blocks[currentBlockIndex]
    }

    /// Esercizio corrente
    var currentExercise: WorkoutExerciseItem? {
        guard let block = currentBlock,
              currentExerciseIndex < block.exerciseItems.count else {
            return nil
        }
        return block.exerciseItems[currentExerciseIndex]
    }

    /// Serie corrente
    var currentSet: WorkoutSet? {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.sets.count else {
            return nil
        }
        return exercise.sets[currentSetIndex]
    }

    /// Percentuale di completamento dell'allenamento
    var progressPercentage: Double {
        let totalSets = workoutCard.totalSets
        guard totalSets > 0 else { return 0 }
        return Double(completedSets.count) / Double(totalSets) * 100.0
    }

    /// Numero totale di serie completate
    var totalCompletedSets: Int {
        return completedSets.count
    }

    /// Tempo rimanente di recupero (se timer attivo)
    var remainingRestTime: TimeInterval? {
        guard let startTime = restTimerStartTime,
              let duration = restTimerDuration else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = duration - elapsed
        return max(0, remaining)
    }

    /// Verifica se il timer di recupero è attivo
    var isRestTimerActive: Bool {
        return restTimerStartTime != nil && (remainingRestTime ?? 0) > 0
    }

    // MARK: - Actions

    /// Avvia la pausa
    func pause() {
        guard !isPaused else { return }
        isPaused = true
        pauseStartTime = Date()
    }

    /// Riprende dall'ultima pausa
    func resume() {
        guard isPaused, let pauseStart = pauseStartTime else { return }
        totalPausedTime += Date().timeIntervalSince(pauseStart)
        isPaused = false
        pauseStartTime = nil
    }

    /// Registra il completamento di una serie
    func completeCurrentSet(performance: SetPerformance) {
        completedSets.append(performance)
        lastUpdateDate = Date()
    }

    /// Avvia timer di recupero
    func startRestTimer(duration: TimeInterval) {
        restTimerStartTime = Date()
        restTimerDuration = duration
        lastUpdateDate = Date()
    }

    /// Ferma timer di recupero
    func stopRestTimer() {
        restTimerStartTime = nil
        restTimerDuration = nil
        lastUpdateDate = Date()
    }

    /// Passa alla serie successiva
    func moveToNextSet() {
        guard let exercise = currentExercise else { return }

        currentSetIndex += 1

        // Se abbiamo finito le serie dell'esercizio corrente
        if currentSetIndex >= exercise.sets.count {
            moveToNextExercise()
        }

        lastUpdateDate = Date()
    }

    /// Passa all'esercizio successivo
    func moveToNextExercise() {
        guard let block = currentBlock else { return }

        currentExerciseIndex += 1
        currentSetIndex = 0

        // Se abbiamo finito gli esercizi del blocco corrente
        if currentExerciseIndex >= block.exerciseItems.count {
            moveToNextBlock()
        }

        lastUpdateDate = Date()
    }

    /// Passa al blocco successivo
    func moveToNextBlock() {
        currentBlockIndex += 1
        currentExerciseIndex = 0
        currentSetIndex = 0

        // Se abbiamo finito tutti i blocchi, segna come completato
        if currentBlockIndex >= workoutCard.blocks.count {
            isCompleted = true
        }

        lastUpdateDate = Date()
    }

    /// Completa manualmente la sessione
    func complete() {
        isCompleted = true
        lastUpdateDate = Date()
    }

    /// Verifica se la performance per la serie corrente è già stata registrata
    func hasPerformanceForCurrentSet() -> Bool {
        return completedSets.contains { performance in
            performance.blockIndex == currentBlockIndex &&
            performance.exerciseIndex == currentExerciseIndex &&
            performance.setIndex == currentSetIndex &&
            performance.round == currentRound
        }
    }

    /// Ottiene la performance registrata per la serie corrente (se esiste)
    func getPerformanceForCurrentSet() -> SetPerformance? {
        return completedSets.first { performance in
            performance.blockIndex == currentBlockIndex &&
            performance.exerciseIndex == currentExerciseIndex &&
            performance.setIndex == currentSetIndex &&
            performance.round == currentRound
        }
    }
}
