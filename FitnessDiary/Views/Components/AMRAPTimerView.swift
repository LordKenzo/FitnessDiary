//
//  AMRAPTimerView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI

/// Timer specializzato per AMRAP (As Many Reps/Rounds As Possible)
/// Countdown timer per eseguire il massimo numero di reps/round nel tempo dato
struct AMRAPTimerView: View {
    let totalDuration: TimeInterval  // Durata totale AMRAP (es. 10 minuti)
    let exerciseCount: Int  // Numero esercizi nel circuito

    @State private var timerManager = WorkoutTimerManager()
    @State private var roundsCompleted: Int = 0

    var onComplete: (() -> Void)?
    var onRoundComplete: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerView

            // Main countdown timer
            mainTimerView

            // Round counter
            roundCounterView

            // Quick stats
            statsView

            // Controls
            controlsView
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.brown.opacity(0.2), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .onAppear {
            startAMRAP()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.brown)

                    Text("AMRAP")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text("As Many Rounds As Possible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Durata Totale")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(timerManager.formatTime(totalDuration))
                    .font(.headline)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Main Timer

    private var mainTimerView: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 25)

                // Progress circle (decrementing)
                Circle()
                    .trim(from: 0, to: 1 - timerManager.progress)
                    .stroke(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 25, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerManager.progress)

                // Inner content
                VStack(spacing: 8) {
                    Text("TEMPO RIMANENTE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(timerManager.formatTime(timerManager.remainingTime))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(timerColor)

                    if timerManager.remainingTime < 30 {
                        Text("SPRINT FINALE!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .opacity(timerManager.remainingTime < 10 ? 1.0 : 0.7)
                    }
                }
            }
            .frame(width: 280, height: 280)

            // Time elapsed
            HStack {
                Text("Tempo Trascorso:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(timerManager.formatTime(timerManager.elapsedTime))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Round Counter

    private var roundCounterView: some View {
        VStack(spacing: 12) {
            Text("Round Completati")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                Button {
                    if roundsCompleted > 0 {
                        roundsCompleted -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                }
                .disabled(roundsCompleted == 0)

                Text("\(roundsCompleted)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 100)
                    .foregroundStyle(.brown)

                Button {
                    roundsCompleted += 1
                    onRoundComplete?()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                }
            }

            Text("Tap + ogni volta che completi un round")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Stats

    private var statsView: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Ritmo",
                value: pacePerRound,
                unit: "sec/round",
                icon: "speedometer"
            )

            StatCard(
                title: "Esercizi",
                value: "\(exerciseCount)",
                unit: "per round",
                icon: "figure.run"
            )

            StatCard(
                title: "Totale",
                value: "\(roundsCompleted * exerciseCount)",
                unit: "esercizi",
                icon: "checkmark.circle"
            )
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
                .tint(.brown)
            }

            Button {
                finishEarly()
            } label: {
                Label("Termina", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Computed Properties

    private var timerColor: Color {
        let remaining = timerManager.remainingTime

        if remaining < 10 {
            return .red
        } else if remaining < 30 {
            return .orange
        } else {
            return .brown
        }
    }

    private var gradientColors: [Color] {
        let remaining = timerManager.remainingTime

        if remaining < 10 {
            return [.red, .orange]
        } else if remaining < 30 {
            return [.orange, .yellow]
        } else {
            return [.brown, .orange]
        }
    }

    private var pacePerRound: String {
        guard roundsCompleted > 0 else { return "--" }

        let elapsed = timerManager.elapsedTime
        let pace = elapsed / Double(roundsCompleted)

        return String(format: "%.0f", pace)
    }

    // MARK: - Timer Logic

    private func startAMRAP() {
        timerManager.startAMRAPTimer(totalDuration: totalDuration)
        timerManager.onTimerComplete = {
            onComplete?()
        }
    }

    private func finishEarly() {
        timerManager.stop()
        onComplete?()
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.brown)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    AMRAPTimerView(
        totalDuration: 600,  // 10 minutes
        exerciseCount: 4
    )
    .padding()
}
