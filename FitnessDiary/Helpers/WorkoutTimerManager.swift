//
//  WorkoutTimerManager.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import Foundation
import SwiftUI
import UserNotifications

/// Tipo di timer
enum TimerType: Equatable {
    case rest  // Recupero tra serie
    case tabata  // Tabata workout/rest
    case emom  // Every Minute On the Minute
    case amrap  // As Many Reps As Possible (countdown)
    case cluster  // Micro-pause intra-serie
    case custom  // Timer generico
}

/// Stato del timer
enum TimerState: Equatable {
    case idle
    case running
    case paused
    case completed
}

/// Manager centralizzato per la gestione di timer durante l'allenamento
/// Usa Date-based tracking per supportare background mode
@MainActor
@Observable
final class WorkoutTimerManager {

    // MARK: - Properties

    var timerState: TimerState = .idle
    var timerType: TimerType = .rest
    var tickCount: Int = 0  // Incrementato ad ogni tick per triggherare Observable

    private var startTime: Date?
    private var pauseTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var targetDuration: TimeInterval = 0

    // Timer publisher per aggiornamento UI
    private var displayTimer: Timer?

    // Callbacks
    var onTimerComplete: (() -> Void)?
    var onTimerTick: ((TimeInterval) -> Void)?  // Chiamato ogni secondo con remaining time

    // MARK: - Computed Properties

    /// Tempo trascorso dall'inizio (escluse pause)
    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }

        let totalElapsed = Date().timeIntervalSince(start)

        if timerState == .paused, let pauseStart = pauseTime {
            let currentPause = Date().timeIntervalSince(pauseStart)
            return max(0, totalElapsed - totalPausedDuration - currentPause)
        }

        return max(0, totalElapsed - totalPausedDuration)
    }

    /// Tempo rimanente (per countdown)
    var remainingTime: TimeInterval {
        return max(0, targetDuration - elapsedTime)
    }

    /// Percentuale completamento (0.0 - 1.0)
    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(1.0, elapsedTime / targetDuration)
    }

    /// Verifica se il timer è completato
    var isCompleted: Bool {
        return timerState == .completed || (targetDuration > 0 && elapsedTime >= targetDuration)
    }

    // MARK: - Initialization

    init() {
        // Request notification authorization on init
        requestNotificationAuthorization()
    }

    // MARK: - Timer Control

    /// Avvia un countdown timer
    func startCountdown(duration: TimeInterval, type: TimerType = .rest) {
        reset()

        self.targetDuration = duration
        self.timerType = type
        self.startTime = Date()
        self.timerState = .running

        startDisplayTimer()
        scheduleNotification(for: duration, type: type)
    }

    /// Avvia un timer in modalità stopwatch (senza limite)
    func startStopwatch(type: TimerType = .custom) {
        reset()

        self.targetDuration = 0  // No limit
        self.timerType = type
        self.startTime = Date()
        self.timerState = .running

        startDisplayTimer()
    }

    /// Mette in pausa il timer
    func pause() {
        guard timerState == .running else { return }

        timerState = .paused
        pauseTime = Date()

        stopDisplayTimer()
        cancelNotifications()
    }

    /// Riprende il timer dalla pausa
    func resume() {
        guard timerState == .paused, let pauseStart = pauseTime else { return }

        // Accumula il tempo di pausa
        totalPausedDuration += Date().timeIntervalSince(pauseStart)
        pauseTime = nil

        timerState = .running

        startDisplayTimer()

        // Rischedula notifica per il tempo rimanente
        if targetDuration > 0 {
            scheduleNotification(for: remainingTime, type: timerType)
        }
    }

    /// Ferma il timer
    func stop() {
        stopDisplayTimer()
        cancelNotifications()

        timerState = .idle
        startTime = nil
        pauseTime = nil
        totalPausedDuration = 0
        targetDuration = 0
        tickCount = 0
    }

    /// Reset completo del timer
    func reset() {
        stop()
        onTimerComplete = nil
        onTimerTick = nil
    }

    /// Salta al completamento immediato
    func skipToEnd() {
        guard timerState == .running else { return }

        stopDisplayTimer()
        cancelNotifications()

        timerState = .completed
        onTimerComplete?()
    }

    // MARK: - Display Timer (UI Updates)

    private func startDisplayTimer() {
        stopDisplayTimer()

        // Timer che aggiorna l'UI ogni 0.1 secondi
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Incrementa tickCount per triggherare Observable
                self.tickCount += 1

                // Check se completato
                if self.targetDuration > 0 && self.elapsedTime >= self.targetDuration {
                    self.handleTimerCompletion()
                }

                // Callback per aggiornamento UI
                self.onTimerTick?(self.remainingTime)
            }
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func handleTimerCompletion() {
        stopDisplayTimer()
        timerState = .completed
        onTimerComplete?()
    }

    // MARK: - Notifications

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleNotification(for duration: TimeInterval, type: TimerType) {
        cancelNotifications()

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch type {
        case .rest:
            content.title = "Recupero Completato"
            content.body = "Pronto per la prossima serie!"
        case .tabata:
            content.title = "Tabata Round Completato"
            content.body = "Passa al prossimo esercizio"
        case .emom:
            content.title = "EMOM - Nuovo Minuto"
            content.body = "Inizia il prossimo set"
        case .amrap:
            content.title = "AMRAP Completato"
            content.body = "Tempo scaduto!"
        case .cluster:
            content.title = "Cluster Pause Completata"
            content.body = "Riprendi il cluster"
        case .custom:
            content.title = "Timer Completato"
            content.body = "Tempo scaduto"
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(identifier: "workoutTimer", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["workoutTimer"])
    }

    // MARK: - Formatting Helpers

    /// Formatta tempo in MM:SS
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formatta tempo in HH:MM:SS
    func formatLongTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Specialized Timers

    /// Timer per Tabata (20s lavoro / 10s rest × 8 round)
    func startTabataWorkTimer(workDuration: TimeInterval = 20) {
        startCountdown(duration: workDuration, type: .tabata)
    }

    func startTabataRestTimer(restDuration: TimeInterval = 10) {
        startCountdown(duration: restDuration, type: .tabata)
    }

    /// Timer per EMOM (ogni minuto)
    func startEMOMTimer(minuteDuration: TimeInterval = 60) {
        startCountdown(duration: minuteDuration, type: .emom)
    }

    /// Timer per AMRAP (countdown dal tempo totale)
    func startAMRAPTimer(totalDuration: TimeInterval) {
        startCountdown(duration: totalDuration, type: .amrap)
    }

    /// Timer per Cluster (micro-pause tra cluster)
    func startClusterRestTimer(restDuration: TimeInterval) {
        startCountdown(duration: restDuration, type: .cluster)
    }

    /// Timer per recupero standard tra serie
    func startRestTimer(restDuration: TimeInterval) {
        startCountdown(duration: restDuration, type: .rest)
    }
}

// MARK: - Timer Description Extension
extension TimerType {
    var description: String {
        switch self {
        case .rest:
            return "Recupero"
        case .tabata:
            return "Tabata"
        case .emom:
            return "EMOM"
        case .amrap:
            return "AMRAP"
        case .cluster:
            return "Cluster Pause"
        case .custom:
            return "Timer"
        }
    }

    var icon: String {
        switch self {
        case .rest:
            return "pause.circle.fill"
        case .tabata:
            return "stopwatch.fill"
        case .emom:
            return "timer"
        case .amrap:
            return "infinity.circle.fill"
        case .cluster:
            return "circle.grid.3x3.fill"
        case .custom:
            return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .rest:
            return .blue
        case .tabata:
            return .red
        case .emom:
            return .teal
        case .amrap:
            return .brown
        case .cluster:
            return .yellow
        case .custom:
            return .gray
        }
    }
}
