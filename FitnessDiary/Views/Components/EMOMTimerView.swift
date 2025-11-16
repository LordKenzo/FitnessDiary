//
//  EMOMTimerView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI

/// Timer specializzato per EMOM (Every Minute On the Minute)
/// Esegui X reps all'inizio di ogni minuto per Y minuti totali
struct EMOMTimerView: View {
    let minuteDuration: TimeInterval  // Default: 60s
    let totalMinutes: Int  // Numero totale di minuti
    let exerciseCount: Int  // Numero di esercizi nel circuito

    @State private var timerManager = WorkoutTimerManager()
    @State private var currentMinute: Int = 1
    @State private var currentExercise: Int = 1

    var onComplete: (() -> Void)?
    var onMinuteStart: ((Int) -> Void)?
    var onExerciseChange: ((Int) -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerView

            // Main timer display
            mainTimerView

            // Exercise indicator
            exerciseIndicatorView

            // Progress bar
            progressBarView

            // Controls
            controlsView
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.2), Color.teal.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .onAppear {
            startEMOM()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .font(.title3)

                Text("EMOM Protocol")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minuto Corrente")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(currentMinute) / \(totalMinutes)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.teal)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tempo Rimanente")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(timerManager.formatTime(timerManager.remainingTime))
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(timerManager.remainingTime < 10 ? .red : .primary)
                }
            }
        }
    }

    // MARK: - Main Timer

    private var mainTimerView: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))

            // Progress fill
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.teal, Color.teal.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * timerManager.progress)
            }

            // Timer text
            VStack(spacing: 12) {
                Text(timerManager.formatTime(timerManager.remainingTime))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

                if timerManager.remainingTime < 10 {
                    Text("PREPARATI!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .opacity(timerManager.remainingTime < 5 ? 1.0 : 0.7)
                }
            }
        }
        .frame(height: 180)
    }

    // MARK: - Exercise Indicator

    private var exerciseIndicatorView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Esercizio Corrente")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(currentExercise) / \(exerciseCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Exercise dots
            HStack(spacing: 8) {
                ForEach(1...exerciseCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentExercise ? Color.teal : Color(.systemGray4))
                        .frame(width: index == currentExercise ? 20 : 16, height: index == currentExercise ? 20 : 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: index == currentExercise ? 3 : 0)
                        )
                        .animation(.spring(response: 0.3), value: currentExercise)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Progress Bar

    private var progressBarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progresso Totale")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(Double(currentMinute - 1) / Double(totalMinutes) * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.teal)
                        .frame(width: geometry.size.width * Double(currentMinute - 1) / Double(totalMinutes))
                }
            }
            .frame(height: 8)
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
                .tint(.teal)
            }

            Button {
                skipToNextMinute()
            } label: {
                Label("Prossimo Minuto", systemImage: "forward.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Timer Logic

    private func startEMOM() {
        startNewMinute()
    }

    private func startNewMinute() {
        // Trigger minute start callback
        onMinuteStart?(currentMinute)

        // Update current exercise (rotate through exercises)
        currentExercise = ((currentMinute - 1) % exerciseCount) + 1
        onExerciseChange?(currentExercise)

        // Start timer for this minute
        timerManager.startEMOMTimer(minuteDuration: minuteDuration)
        timerManager.onTimerComplete = {
            moveToNextMinute()
        }
    }

    private func moveToNextMinute() {
        currentMinute += 1

        if currentMinute <= totalMinutes {
            startNewMinute()
        } else {
            // EMOM completed!
            onComplete?()
        }
    }

    private func skipToNextMinute() {
        timerManager.stop()
        moveToNextMinute()
    }
}

#Preview {
    EMOMTimerView(
        minuteDuration: 60,
        totalMinutes: 10,
        exerciseCount: 3
    )
    .padding()
}
