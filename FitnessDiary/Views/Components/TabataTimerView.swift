//
//  TabataTimerView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI

/// Timer specializzato per protocollo Tabata
/// 8 esercizi × (workDuration lavoro + restDuration recupero) × rounds
struct TabataTimerView: View {
    let workDuration: TimeInterval  // Default: 20s
    let restDuration: TimeInterval  // Default: 10s
    let totalRounds: Int  // Default: 8
    let recoveryBetweenRounds: TimeInterval?  // Recupero tra i round

    @State private var timerManager = WorkoutTimerManager()
    @State private var currentRound: Int = 1
    @State private var currentExercise: Int = 1
    @State private var isWorkPhase: Bool = true
    @State private var isRecoveryPhase: Bool = false

    var onComplete: (() -> Void)?
    var onRoundComplete: ((Int) -> Void)?
    var onExerciseChange: ((Int) -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView

            // Main timer display
            mainTimerView

            // Progress indicators
            progressView

            // Controls
            controlsView
        }
        .padding()
        .background(currentPhaseColor.opacity(0.1))
        .cornerRadius(16)
        .onAppear {
            startTabata()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Tabata Protocol")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Round")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(currentRound) / \(totalRounds)")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("Esercizio")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(currentExercise) / 8")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("Fase")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(currentPhaseText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(currentPhaseColor)
                }
            }
        }
    }

    // MARK: - Main Timer

    private var mainTimerView: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 20)

            // Progress circle
            Circle()
                .trim(from: 0, to: timerManager.progress)
                .stroke(currentPhaseColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerManager.progress)

            // Time remaining
            VStack(spacing: 8) {
                Text(timerManager.formatTime(timerManager.remainingTime))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(currentPhaseColor)

                Text(currentPhaseText.uppercased())
                    .font(.headline)
                    .foregroundStyle(currentPhaseColor.opacity(0.8))
            }
        }
        .frame(width: 280, height: 280)
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: 12) {
            // Exercise progress
            VStack(alignment: .leading, spacing: 6) {
                Text("Esercizi completati")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(1...8, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index < currentExercise ? Color.green : Color(.systemGray5))
                            .frame(height: 8)
                    }
                }
            }

            // Round progress
            VStack(alignment: .leading, spacing: 6) {
                Text("Round completati")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(1...totalRounds, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index < currentRound ? Color.blue : Color(.systemGray5))
                            .frame(height: 8)
                    }
                }
            }
        }
    }

    // MARK: - Controls

    private var controlsView: some View {
        HStack(spacing: 12) {
            if timerManager.timerState == .running {
                Button {
                    timerManager.pause()
                } label: {
                    Label("Pausa", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else if timerManager.timerState == .paused {
                Button {
                    timerManager.resume()
                } label: {
                    Label("Riprendi", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Button {
                skipPhase()
            } label: {
                Label("Salta", systemImage: "forward.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Computed Properties

    private var currentPhaseColor: Color {
        if isRecoveryPhase {
            return .purple
        } else if isWorkPhase {
            return .red
        } else {
            return .blue
        }
    }

    private var currentPhaseText: String {
        if isRecoveryPhase {
            return "Recupero Round"
        } else if isWorkPhase {
            return "Lavoro"
        } else {
            return "Riposo"
        }
    }

    // MARK: - Timer Logic

    private func startTabata() {
        startWorkPhase()
    }

    private func startWorkPhase() {
        isWorkPhase = true
        isRecoveryPhase = false

        timerManager.startTabataWorkTimer(workDuration: workDuration)
        timerManager.onTimerComplete = {
            startRestPhase()
        }
    }

    private func startRestPhase() {
        isWorkPhase = false
        isRecoveryPhase = false

        timerManager.startTabataRestTimer(restDuration: restDuration)
        timerManager.onTimerComplete = {
            moveToNextExercise()
        }
    }

    private func startRecoveryPhase() {
        isWorkPhase = false
        isRecoveryPhase = true

        timerManager.startCountdown(
            duration: recoveryBetweenRounds ?? 60,
            type: .tabata
        )
        timerManager.onTimerComplete = {
            moveToNextRound()
        }
    }

    private func moveToNextExercise() {
        currentExercise += 1
        onExerciseChange?(currentExercise)

        // Se abbiamo finito tutti gli 8 esercizi
        if currentExercise > 8 {
            // Check se ci sono altri round
            if currentRound < totalRounds {
                if let _ = recoveryBetweenRounds {
                    // Inizia recovery tra round
                    startRecoveryPhase()
                } else {
                    // Passa direttamente al prossimo round
                    moveToNextRound()
                }
            } else {
                // Tabata completato!
                onComplete?()
            }
        } else {
            // Prossimo esercizio dello stesso round
            startWorkPhase()
        }
    }

    private func moveToNextRound() {
        currentRound += 1
        currentExercise = 1
        onRoundComplete?(currentRound)

        if currentRound <= totalRounds {
            startWorkPhase()
        } else {
            onComplete?()
        }
    }

    private func skipPhase() {
        timerManager.skipToEnd()
    }
}

#Preview {
    TabataTimerView(
        workDuration: 20,
        restDuration: 10,
        totalRounds: 2,
        recoveryBetweenRounds: 60
    )
    .padding()
}
