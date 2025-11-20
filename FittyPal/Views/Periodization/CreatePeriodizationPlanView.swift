//
//  CreatePeriodizationPlanView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Vista per creare un piano di periodizzazione
/// RF1: L'utente inserisce data inizio, durata, profili forza, frequenza e modello
struct CreatePeriodizationPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Opzionale: crea per cliente o per utente
    let userProfile: UserProfile?
    let client: Client?

    // Form state
    @State private var name: String = ""
    @State private var startDate: Date = Date()
    @State private var durationWeeks: Int = 12
    @State private var periodizationModel: PeriodizationModel = .linear
    @State private var primaryProfile: StrengthExpressionType = .maxStrength
    @State private var secondaryProfile: StrengthExpressionType? = nil
    @State private var useSecondaryProfile: Bool = false
    @State private var weeklyFrequency: Int = 3
    @State private var notes: String = ""

    // Template
    @State private var useTemplate: Bool = false
    @State private var selectedTemplate: PeriodizationTemplate? = nil

    // Generazione
    @State private var autoGenerate: Bool = true
    @State private var mesocycleDurationWeeks: Int = 4

    // Navigation
    @State private var createdPlan: PeriodizationPlan?
    @State private var navigateToTimeline = false

    init(userProfile: UserProfile? = nil, client: Client? = nil) {
        self.userProfile = userProfile
        self.client = client
    }

    var body: some View {
        NavigationStack {
            Form {
                // Sezione Template
                templateSection

                // Sezione Info Base
                basicInfoSection

                // Sezione Durata
                durationSection

                // Sezione Modello
                modelSection

                // Sezione Profili Forza
                strengthProfilesSection

                // Sezione Frequenza
                frequencySection

                // Sezione Generazione
                generationSection

                // Sezione Note
                notesSection
            }
            .navigationTitle("Nuovo Piano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
                        createPlan()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationDestination(isPresented: $navigateToTimeline) {
                if let plan = createdPlan {
                    PeriodizationTimelineView(plan: plan)
                }
            }
        }
    }

    // MARK: - Sections

    private var templateSection: some View {
        Section {
            Toggle("Usa template", isOn: $useTemplate)

            if useTemplate {
                // TODO: Picker per selezionare template
                Text("Template disponibili: in arrivo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Template")
        }
    }

    private var basicInfoSection: some View {
        Section {
            TextField("Nome piano", text: $name)
                .disabled(useTemplate && selectedTemplate != nil)

            if let user = userProfile {
                HStack {
                    Text("Utente")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(user.name)
                }
            } else if let client = client {
                HStack {
                    Text("Cliente")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(client.fullName)
                }
            }
        } header: {
            Text("Informazioni Base")
        }
    }

    private var durationSection: some View {
        Section {
            DatePicker("Data inizio", selection: $startDate, displayedComponents: .date)

            Stepper("Durata: \(durationWeeks) settimane", value: $durationWeeks, in: 4...52, step: 4)

            HStack {
                Text("Data fine stimata")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatDate(estimatedEndDate))
                    .fontWeight(.semibold)
            }
        } header: {
            Text("Durata")
        } footer: {
            Text("Il piano durerà circa \(durationWeeks) settimane (\(estimatedMesocycles) mesocicli)")
        }
    }

    private var modelSection: some View {
        Section {
            Picker("Modello", selection: $periodizationModel) {
                ForEach(PeriodizationModel.allCases, id: \.self) { model in
                    Label(model.rawValue, systemImage: model.icon)
                        .tag(model)
                }
            }

            Text(periodizationModel.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Modello di Periodizzazione")
        }
    }

    private var strengthProfilesSection: some View {
        Section {
            Picker("Profilo primario", selection: $primaryProfile) {
                ForEach(StrengthExpressionType.allCases, id: \.self) { profile in
                    Text(profile.rawValue).tag(profile)
                }
            }

            Toggle("Profilo secondario", isOn: $useSecondaryProfile)

            if useSecondaryProfile {
                Picker("Secondario", selection: $secondaryProfile) {
                    Text("Nessuno").tag(nil as StrengthExpressionType?)

                    ForEach(StrengthExpressionType.allCases.filter { $0 != primaryProfile }, id: \.self) { profile in
                        Text(profile.rawValue).tag(profile as StrengthExpressionType?)
                    }
                }
            }
        } header: {
            Text("Profili di Forza")
        } footer: {
            Text("Il profilo primario sarà il focus principale. Il secondario verrà alternato nei blocchi (modello a blocchi).")
        }
    }

    private var frequencySection: some View {
        Section {
            Stepper("Frequenza: \(weeklyFrequency)x/settimana", value: $weeklyFrequency, in: 1...7)

            Text(frequencyDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Frequenza Settimanale")
        }
    }

    private var generationSection: some View {
        Section {
            Toggle("Genera struttura automaticamente", isOn: $autoGenerate)

            if autoGenerate {
                Stepper("Mesociclo: \(mesocycleDurationWeeks) settimane", value: $mesocycleDurationWeeks, in: 3...6)

                Text("Verrà generata la struttura completa con mesocicli, microcicli e giorni")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Generazione")
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
        !name.isEmpty && durationWeeks >= 4
    }

    private var estimatedEndDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: startDate) ?? startDate
    }

    private var estimatedMesocycles: Int {
        max(1, durationWeeks / mesocycleDurationWeeks)
    }

    private var frequencyDescription: String {
        switch weeklyFrequency {
        case 1:
            return "1 allenamento a settimana (maintenance)"
        case 2:
            return "2 allenamenti (es. Upper/Lower)"
        case 3:
            return "3 allenamenti (es. Full Body 3x)"
        case 4:
            return "4 allenamenti (es. Upper/Lower 2x)"
        case 5:
            return "5 allenamenti (frequenza alta)"
        case 6:
            return "6 allenamenti (Push/Pull/Legs 2x)"
        case 7:
            return "7 allenamenti (tutti i giorni)"
        default:
            return "\(weeklyFrequency) allenamenti"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func createPlan() {
        let plan = PeriodizationPlan(
            name: name,
            startDate: startDate,
            endDate: estimatedEndDate,
            periodizationModel: periodizationModel,
            primaryStrengthProfile: primaryProfile,
            secondaryStrengthProfile: useSecondaryProfile ? secondaryProfile : nil,
            weeklyFrequency: weeklyFrequency,
            notes: notes.isEmpty ? nil : notes,
            userProfile: userProfile,
            client: client
        )

        modelContext.insert(plan)

        // Genera struttura se richiesto
        if autoGenerate {
            let generator = PeriodizationGenerator()
            let _ = generator.generateCompletePlan(plan)
        }

        // Salva
        try? modelContext.save()

        // Naviga alla timeline
        createdPlan = plan
        navigateToTimeline = true
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PeriodizationPlan.self, configurations: config)

    return CreatePeriodizationPlanView()
        .modelContainer(container)
}
