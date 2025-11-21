//
//  MesocycleDetailView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Dettaglio mesociclo con istogrammi microcicli navigabili
struct MesocycleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let mesocycle: Mesocycle

    @State private var selectedMicrocycle: Microcycle?
    @State private var showingMicrocycleDetail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Mesociclo
                mesocycleHeaderSection

                // Progress
                progressSection

                // Microcicli Timeline
                microcyclesSection
            }
            .padding()
        }
        .navigationTitle(mesocycle.name)
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Chiudi") {
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedMicrocycle) { microcycle in
            NavigationStack {
                MicrocycleDetailView(microcycle: microcycle)
            }
        }
    }

    // MARK: - Sections

    private var mesocycleHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tipo fase
            HStack {
                Label(mesocycle.phaseType.rawValue, systemImage: mesocycle.phaseType.icon)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(phaseColor)

                Spacer()

                Text("M\(mesocycle.order)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(phaseColor)
                    .cornerRadius(8)
            }

            Text(mesocycle.phaseType.description)
                .font(.caption)

            Divider()

            // Info principali
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus")
                        .font(.caption)
                    Text(mesocycle.focusStrengthProfile.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Durata")
                        .font(.caption)
                    Text("\(mesocycle.durationInWeeks) settimane")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carico")
                        .font(.caption)
                    Text("\(mesocycle.loadWeeks) settimane")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Scarico")
                        .font(.caption)
                    Text("\(mesocycle.deloadWeeks) settimana")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            // Date
            HStack {
                Label(formatDate(mesocycle.startDate), systemImage: "calendar")
                    .font(.caption)

                Image(systemName: "arrow.right")
                    .font(.caption2)

                Label(formatDate(mesocycle.endDate), systemImage: "calendar")
                    .font(.caption)
            }

            if let notes = mesocycle.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(phaseColor.opacity(0.2))
        .cornerRadius(12)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progresso Mesociclo")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(mesocycle.progressPercentage()))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: mesocycle.progressPercentage() / 100.0)
                .tint(phaseColor)
        }
    }

    private var microcyclesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settimane (Microcicli)")
                .font(.headline)
                .fontWeight(.bold)

            if mesocycle.microcycles.isEmpty {
                emptyMicrocyclesView
            } else {
                ForEach(mesocycle.sortedMicrocycles) { microcycle in
                    MicrocycleBarView(microcycle: microcycle)
                        .onTapGesture {
                            selectedMicrocycle = microcycle
                        }
                }
            }
        }
    }

    private var emptyMicrocyclesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Nessun microciclo generato")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Helpers

    private var phaseColor: Color {
        mesocycle.phaseType.color
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        //formatter.locale = Locale(identifier: "it_IT")
        formatter.locale = Locale.current
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Microcycle Bar View

/// Vista istogramma per singolo microciclo (settimana)
struct MicrocycleBarView: View {
    let microcycle: Microcycle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Settimana \(microcycle.order)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

            }

            // Barra visuale
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(loadLevelColor.opacity(0.2))
                    .frame(height: 50)

                // Progress
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(loadLevelColor.opacity(0.5))
                        .frame(width: geometry.size.width * (microcycle.progressPercentage() / 100.0))
                }
                .frame(height: 50)

                // Contenuto
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: microcycle.loadLevel.icon)
                                .font(.caption)

                            Text(microcycle.loadLevel.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(loadLevelColor)

                        Text("\(microcycle.completedDays)/\(microcycle.totalPlannedDays) allenamenti")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("I:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(Int(microcycle.intensityFactor * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        HStack(spacing: 4) {
                            Text("V:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(Int(microcycle.volumeFactor * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 50)

            // Date
            HStack {
                Text(formatDateRange(start: microcycle.startDate, end: microcycle.endDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if microcycle.isCurrentlyActive() {
                    Label("In corso", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else if microcycle.progressPercentage() >= 100 {
                    Label("Completata", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var loadLevelColor: Color {
        microcycle.loadLevel.color
    }

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        // formatter.locale = Locale(identifier: "it_IT")
        formatter.locale = Locale.current
        formatter.dateFormat = "dd MMM"

        let startString = formatter.string(from: start)
        let endString = formatter.string(from: end)

        return "\(startString) - \(endString)"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Mesocycle.self, configurations: config) else {
        return Text("Failed to create preview container")
    }

    let mesocycle = Mesocycle(
        order: 1,
        name: "Mesociclo 1 - Accumulo",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())!,
        phaseType: .accumulation,
        focusStrengthProfile: .hypertrophy,
        loadWeeks: 3,
        deloadWeeks: 1
    )

    container.mainContext.insert(mesocycle)

    return NavigationStack {
        MesocycleDetailView(mesocycle: mesocycle)
    }
    .modelContainer(container)
}
