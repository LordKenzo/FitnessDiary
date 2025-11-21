//
//  EditMicrocycleView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Vista per modificare parametri di un microciclo
struct EditMicrocycleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let microcycle: Microcycle

    @State private var loadLevel: LoadLevel
    @State private var intensityFactor: Double
    @State private var volumeFactor: Double
    @State private var loadProgressionPercentage: Double
    @State private var notes: String

    init(microcycle: Microcycle) {
        self.microcycle = microcycle
        _loadLevel = State(initialValue: microcycle.loadLevel)
        _intensityFactor = State(initialValue: microcycle.intensityFactor)
        _volumeFactor = State(initialValue: microcycle.volumeFactor)
        _loadProgressionPercentage = State(initialValue: microcycle.loadProgressionPercentage)
        _notes = State(initialValue: microcycle.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Info Header
                headerSection

                // Load Level
                loadLevelSection

                // Intensity Factor
                intensitySection

                // Volume Factor
                volumeSection

                // Progression
                progressionSection

                // Impact Preview
                previewSection

                // Notes
                notesSection
            }
            .navigationTitle("Modifica Microciclo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveMicrocycle()
                    }
                    .fontWeight(.semibold)
                }
            }
            .appScreenBackground()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Settimana \(microcycle.weekNumber)")
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()

                    if microcycle.isDeloadWeek {
                        Text("SCARICO")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Label(formatDate(microcycle.startDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("→")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(formatDate(microcycle.endDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let mesocycle = microcycle.mesocycle {
                    HStack {
                        Circle()
                            .fill(mesocycle.phaseType.color)
                            .frame(width: 8, height: 8)
                        Text(mesocycle.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var loadLevelSection: some View {
        Section {
            Picker("Tipo Settimana", selection: $loadLevel) {
                ForEach(LoadLevel.allCases, id: \.self) { level in
                    HStack {
                        Text(level.rawValue)
                        Spacer()
                        if level == .low {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundStyle(.orange)
                        } else if level == .high {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .tag(level)
                }
            }
            .onChange(of: loadLevel) { oldValue, newValue in
                // Auto-adjust factors when changing load level
                intensityFactor = newValue.defaultIntensityFactor
                volumeFactor = newValue.defaultVolumeFactor
            }

            Text(loadLevelDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Tipo di Carico")
        }
    }

    private var intensitySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Intensità")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(intensityFactor * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(intensityColor)
                }

                Slider(value: $intensityFactor, in: 0.5...1.2, step: 0.05)
                    .tint(intensityColor)

                HStack {
                    Text("50%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("120%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(intensityDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Fattore Intensità")
        } footer: {
            Text("Modifica le percentuali di carico utilizzate negli esercizi. 100% = carico normale.")
        }
    }

    private var volumeSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Volume")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(volumeFactor * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(volumeColor)
                }

                Slider(value: $volumeFactor, in: 0.5...1.2, step: 0.05)
                    .tint(volumeColor)

                HStack {
                    Text("50%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("120%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(volumeDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Fattore Volume")
        } footer: {
            Text("Modifica il numero di serie e ripetizioni. 100% = volume normale.")
        }
    }

    private var progressionSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progressione Carico")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Incremento rispetto alla settimana precedente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Stepper(
                    "\(String(format: "%.1f", loadProgressionPercentage * 100))%",
                    value: $loadProgressionPercentage,
                    in: 0...0.1,
                    step: 0.005
                )
                .font(.headline)
                .fontWeight(.bold)
            }
        } header: {
            Text("Progressione")
        } footer: {
            Text("Incremento automatico dei carichi settimana su settimana. Tipico: 2.5% per principianti, 1-2% per avanzati.")
        }
    }

    private var previewSection: some View {
        Section {
            VStack(spacing: 12) {
                PreviewRow(
                    icon: "scalemass.fill",
                    iconColor: intensityColor,
                    title: "Carico Esempio",
                    subtitle: intensityPreviewExample
                )

                Divider()

                PreviewRow(
                    icon: "number",
                    iconColor: volumeColor,
                    title: "Volume Esempio",
                    subtitle: volumePreviewExample
                )

                if loadProgressionPercentage > 0 {
                    Divider()

                    PreviewRow(
                        icon: "arrow.up.right",
                        iconColor: .blue,
                        title: "Progressione",
                        subtitle: "Carico aumenta di \(String(format: "%.1f", loadProgressionPercentage * 100))% ogni settimana"
                    )
                }
            }
        } header: {
            Text("Anteprima Impatto")
        } footer: {
            Text("Questi fattori modulano automaticamente i parametri delle schede assegnate ai giorni di allenamento.")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Note (opzionale)", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Note")
        }
    }

    // MARK: - Helpers

    private var loadLevelDescription: String {
        switch loadLevel {
        case .high:
            return "Settimana ad alto carico, massimo stress allenante"
        case .medium:
            return "Settimana a carico medio, bilanciamento tra stress e recupero"
        case .low:
            return "Settimana di scarico, focus su recupero e adattamento"
        }
    }

    private var intensityDescription: String {
        if intensityFactor < 0.7 {
            return "Intensità molto bassa - Ideale per recupero attivo"
        } else if intensityFactor < 0.85 {
            return "Intensità ridotta - Scarico leggero"
        } else if intensityFactor < 1.0 {
            return "Intensità moderata - Mantenimento"
        } else if intensityFactor == 1.0 {
            return "Intensità standard - Programma base"
        } else if intensityFactor < 1.1 {
            return "Intensità elevata - Progressione"
        } else {
            return "Intensità molto alta - Peak week"
        }
    }

    private var volumeDescription: String {
        if volumeFactor < 0.7 {
            return "Volume molto ridotto - Scarico profondo"
        } else if volumeFactor < 0.85 {
            return "Volume ridotto - Deload"
        } else if volumeFactor < 1.0 {
            return "Volume moderato - Mantenimento"
        } else if volumeFactor == 1.0 {
            return "Volume standard - Programma base"
        } else if volumeFactor < 1.1 {
            return "Volume aumentato - Accumulo"
        } else {
            return "Volume molto alto - Overreaching"
        }
    }

    private var intensityPreviewExample: String {
        let baseLoad = 100.0
        let adjustedLoad = baseLoad * intensityFactor
        return "Squat: \(Int(adjustedLoad))kg invece di 100kg"
    }

    private var volumePreviewExample: String {
        let baseSets = 5
        let baseReps = 10
        let adjustedSets = max(1, Int(Double(baseSets) * volumeFactor))
        let adjustedReps = max(1, Int(Double(baseReps) * volumeFactor))
        return "Squat: \(adjustedSets)×\(adjustedReps) invece di 5×10"
    }

    private var intensityColor: Color {
        if intensityFactor < 0.8 {
            return .orange
        } else if intensityFactor < 1.0 {
            return .yellow
        } else if intensityFactor == 1.0 {
            return .green
        } else {
            return .red
        }
    }

    private var volumeColor: Color {
        if volumeFactor < 0.8 {
            return .orange
        } else if volumeFactor < 1.0 {
            return .yellow
        } else if volumeFactor == 1.0 {
            return .green
        } else {
            return .blue
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func saveMicrocycle() {
        microcycle.loadLevel = loadLevel
        microcycle.intensityFactor = intensityFactor
        microcycle.volumeFactor = volumeFactor
        microcycle.loadProgressionPercentage = loadProgressionPercentage
        microcycle.notes = notes.isEmpty ? nil : notes

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview Row Component

private struct PreviewRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(subtitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Microcycle.self, configurations: config) else {
        return Text("Failed to create preview container")
    }

    let microcycle = Microcycle(
        order: 1,
        weekNumber: 1,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        loadLevel: .high,
        intensityFactor: 1.0,
        volumeFactor: 1.0
    )

    container.mainContext.insert(microcycle)

    return EditMicrocycleView(microcycle: microcycle)
        .modelContainer(container)
}
