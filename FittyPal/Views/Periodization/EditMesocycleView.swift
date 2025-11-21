//
//  EditMesocycleView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Vista per modificare le proprietà di un mesociclo
struct EditMesocycleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mesocycle: Mesocycle

    // Form state
    @State private var name: String = ""
    @State private var phaseType: PhaseType = .accumulation
    @State private var focusStrengthProfile: StrengthExpressionType = .maxStrength
    @State private var loadWeeks: Int = 3
    @State private var deloadWeeks: Int = 1
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Sezione Info Base
                basicInfoSection

                // Sezione Fase
                phaseSection

                // Sezione Durata
                durationSection

                // Sezione Note
                notesSection
            }
            .navigationTitle("Modifica Mesociclo")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveMesocycle()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            loadMesocycleData()
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section {
            TextField("Nome mesociclo", text: $name)

            HStack {
                Text("Ordine")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("M\(mesocycle.order)")
                    .fontWeight(.semibold)
            }
        } header: {
            Text("Informazioni Base")
        }
    }

    private var phaseSection: some View {
        Section {
            Picker("Tipo Fase", selection: $phaseType) {
                ForEach(PhaseType.allCases, id: \.self) { phase in
                    Label(phase.rawValue, systemImage: phase.icon)
                        .tag(phase)
                }
            }

            Text(phaseType.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Focus Forza", selection: $focusStrengthProfile) {
                ForEach(StrengthExpressionType.allCases, id: \.self) { profile in
                    Text(profile.rawValue).tag(profile)
                }
            }
        } header: {
            Text("Fase e Focus")
        }
    }

    private var durationSection: some View {
        Section {
            Stepper("Settimane carico: \(loadWeeks)", value: $loadWeeks, in: 2...6)

            Stepper("Settimane scarico: \(deloadWeeks)", value: $deloadWeeks, in: 1...3)

            HStack {
                Text("Durata totale")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(totalWeeks) settimane")
                    .fontWeight(.semibold)
            }
        } header: {
            Text("Durata")
        } footer: {
            Text("Il mesociclo deve avere almeno 1 settimana di scarico (RF3)")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Note (opzionale)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Note")
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !name.isEmpty && loadWeeks >= 2 && deloadWeeks >= 1
    }

    private var totalWeeks: Int {
        loadWeeks + deloadWeeks
    }

    private func loadMesocycleData() {
        name = mesocycle.name
        phaseType = mesocycle.phaseType
        focusStrengthProfile = mesocycle.focusStrengthProfile
        loadWeeks = mesocycle.loadWeeks
        deloadWeeks = mesocycle.deloadWeeks
        notes = mesocycle.notes ?? ""
    }

    // MARK: - Actions

    private func saveMesocycle() {
        mesocycle.name = name
        mesocycle.phaseType = phaseType
        mesocycle.focusStrengthProfile = focusStrengthProfile
        mesocycle.loadWeeks = loadWeeks
        mesocycle.deloadWeeks = deloadWeeks
        mesocycle.notes = notes.isEmpty ? nil : notes

        // Ricalcola date se durata cambia
        let newDuration = loadWeeks + deloadWeeks
        if mesocycle.durationInWeeks != newDuration {
            mesocycle.endDate = Calendar.current.date(
                byAdding: .weekOfYear,
                value: newDuration,
                to: mesocycle.startDate
            ) ?? mesocycle.endDate
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Mesocycle.self, configurations: config) else {
        return Text("Failed to create preview container")
    }

    let mesocycle = Mesocycle(
        order: 1,
        name: "Accumulation Block",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())!,
        phaseType: .accumulation,
        focusStrengthProfile: .maxStrength,
        loadWeeks: 3,
        deloadWeeks: 1
    )

    container.mainContext.insert(mesocycle)

    return EditMesocycleView(mesocycle: mesocycle)
        .modelContainer(container)
}
