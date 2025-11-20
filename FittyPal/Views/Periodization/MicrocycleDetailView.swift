//
//  MicrocycleDetailView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Dettaglio microciclo (settimana) con lista giorni e schede associate
struct MicrocycleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let microcycle: Microcycle

    @State private var selectedDay: TrainingDay?
    @State private var showingWorkoutPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Settimana
                weekHeaderSection

                // Progress completamento
                completionProgressSection

                // Lista giorni
                daysListSection
            }
            .padding()
        }
        .navigationTitle("Settimana \(microcycle.order)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Chiudi") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Sections

    private var weekHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Livello carico
            HStack {
                Label(microcycle.loadLevel.rawValue, systemImage: microcycle.loadLevel.icon)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(loadLevelColor)

                Spacer()

                Text("Sett. \(microcycle.weekNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Text(microcycle.loadLevel.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Fattori modulazione
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intensità")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(loadLevelColor)
                        Text("\(Int(microcycle.intensityFactor * 100))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(loadLevelColor)
                        Text("\(Int(microcycle.volumeFactor * 100))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Progressione")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("+\(String(format: "%.1f", microcycle.loadProgressionPercentage * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }

            // Date
            HStack {
                Label(formatDate(microcycle.startDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label(formatDate(microcycle.endDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notes = microcycle.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(loadLevelColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var completionProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Completamento")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(microcycle.completedDays)/\(microcycle.totalPlannedDays) allenamenti")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: microcycle.completionPercentage / 100.0)
                .tint(loadLevelColor)
        }
    }

    private var daysListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Giorni della Settimana")
                .font(.headline)
                .fontWeight(.bold)

            if microcycle.trainingDays.isEmpty {
                emptyDaysView
            } else {
                ForEach(microcycle.sortedTrainingDays) { day in
                    TrainingDayCardView(day: day)
                }
            }
        }
    }

    private var emptyDaysView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Nessun giorno generato")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Helpers

    private var loadLevelColor: Color {
        switch microcycle.loadLevel {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Training Day Card View

/// Card per singolo giorno di allenamento
struct TrainingDayCardView: View {
    @Environment(\.modelContext) private var modelContext
    let day: TrainingDay

    @State private var showingWorkoutPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header giorno
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.dayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(formatDate(day.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if day.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                } else if day.isRestDay {
                    Label("Riposo", systemImage: "moon.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                } else if day.isPast {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }

            // Scheda associata
            if !day.isRestDay {
                if let workout = day.workoutCard {
                    WorkoutCardPreview(workout: workout, day: day)
                } else {
                    Button {
                        showingWorkoutPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)

                            Text("Associa scheda")
                                .font(.subheadline)
                                .foregroundStyle(.blue)

                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

            // Note
            if let notes = day.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(day.isToday ? Color.accentColor.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(day.isToday ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Workout Card Preview

/// Preview compatta della scheda associata
struct WorkoutCardPreview: View {
    let workout: WorkoutCard
    let day: TrainingDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let splitType = workout.splitType {
                        HStack(spacing: 4) {
                            Image(systemName: splitType.icon)
                                .font(.caption2)

                            Text(splitType.rawValue)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Statistiche scheda
            HStack(spacing: 16) {
                Label("\(workout.totalExercises) esercizi", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Microcycle.self, configurations: config)

    let microcycle = Microcycle(
        order: 1,
        weekNumber: 1,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!,
        loadLevel: .high
    )

    container.mainContext.insert(microcycle)

    return NavigationStack {
        MicrocycleDetailView(microcycle: microcycle)
    }
    .modelContainer(container)
}
