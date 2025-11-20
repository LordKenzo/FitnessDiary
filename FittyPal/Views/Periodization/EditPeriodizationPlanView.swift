//
//  EditPeriodizationPlanView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Vista per modificare un piano di periodizzazione esistente
struct EditPeriodizationPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PeriodizationFolder.order) private var folders: [PeriodizationFolder]

    let plan: PeriodizationPlan

    // Form state
    @State private var name: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var primaryProfile: StrengthExpressionType = .maxStrength
    @State private var secondaryProfile: StrengthExpressionType? = nil
    @State private var useSecondaryProfile: Bool = false
    @State private var weeklyFrequency: Int = 3
    @State private var notes: String = ""
    @State private var selectedFolders: [PeriodizationFolder] = []
    @State private var selectedTrainingDays: [Weekday] = []
    @State private var showingWeekdaySelection = false

    var body: some View {
        NavigationStack {
            Form {
                // Sezione Info Base
                basicInfoSection

                // Sezione Organizzazione
                if !folders.isEmpty {
                    organizationSection
                }

                // Sezione Date
                datesSection

                // Sezione Profili Forza
                strengthProfilesSection

                // Sezione Frequenza
                frequencySection

                // Sezione Giorni Allenamento
                trainingDaysSection

                // Sezione Mesocicli
                if !plan.mesocycles.isEmpty {
                    mesocyclesSection
                }

                // Sezione Note
                notesSection
            }
            .navigationTitle("Modifica Piano")
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
                        savePlan()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            loadPlanData()
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section {
            TextField("Nome piano", text: $name)

            HStack {
                Text("Modello")
                    .foregroundStyle(.secondary)
                Spacer()
                Label(plan.periodizationModel.rawValue, systemImage: plan.periodizationModel.icon)
                    .font(.subheadline)
            }
        } header: {
            Text("Informazioni Base")
        } footer: {
            Text("Il modello di periodizzazione non può essere modificato dopo la creazione")
        }
    }

    private var datesSection: some View {
        Section {
            DatePicker("Data inizio", selection: $startDate, displayedComponents: .date)

            DatePicker("Data fine", selection: $endDate, in: startDate..., displayedComponents: .date)

            HStack {
                Text("Durata")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(durationInWeeks) settimane")
                    .fontWeight(.semibold)
            }
        } header: {
            Text("Date")
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
        }
    }

    private var frequencySection: some View {
        Section {
            Stepper("Frequenza: \(weeklyFrequency)x/settimana", value: $weeklyFrequency, in: 1...7)
                .onChange(of: weeklyFrequency) { oldValue, newValue in
                    // Se cambio frequenza, resetto i giorni selezionati
                    if selectedTrainingDays.count != newValue {
                        selectedTrainingDays = []
                    }
                }

            Text(frequencyDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Frequenza Settimanale")
        }
    }

    private var trainingDaysSection: some View {
        Section {
            Button {
                showingWeekdaySelection = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Giorni di Allenamento")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if selectedTrainingDays.isEmpty {
                            Text("Seleziona \(weeklyFrequency) giorni")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if selectedTrainingDays.count != weeklyFrequency {
                            Text("\(selectedTrainingDays.count)/\(weeklyFrequency) giorni selezionati")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            HStack(spacing: 6) {
                                ForEach(selectedTrainingDays) { day in
                                    Text(day.shortName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Pianificazione")
        } footer: {
            Text("Scegli in quali giorni della settimana ti allenerai. Questi giorni saranno validi per tutto il piano.")
        }
        .sheet(isPresented: $showingWeekdaySelection) {
            WeekdaySelectionView(selectedDays: $selectedTrainingDays, requiredCount: weeklyFrequency)
        }
    }

    private var mesocyclesSection: some View {
        Section {
            ForEach(plan.mesocycles.sorted(by: { $0.order < $1.order })) { mesocycle in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mesocycle.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 8) {
                            Label(mesocycle.phaseType.rawValue, systemImage: mesocycle.phaseType.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(mesocycle.durationInWeeks) sett")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text("M\(mesocycle.order)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(mesocycle.phaseType.swiftUIColor)
                        .cornerRadius(6)
                }
            }
        } header: {
            Text("Mesocicli (\(plan.mesocycles.count))")
        } footer: {
            Text("Per riordinare o modificare i mesocicli, usa la vista timeline")
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

    private var organizationSection: some View {
        Section {
            NavigationLink {
                PeriodizationFolderSelectionView(
                    selectedFolders: $selectedFolders,
                    folders: folders
                )
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Folder")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if selectedFolders.isEmpty {
                            Text("Nessuna cartella selezionata")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 6) {
                                ForEach(selectedFolders.prefix(2)) { folder in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(folder.color)
                                            .frame(width: 8, height: 8)
                                        Text(folder.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(folder.color.opacity(0.1))
                                    .clipShape(Capsule())
                                }

                                if selectedFolders.count > 2 {
                                    Text("+\(selectedFolders.count - 2)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Organizzazione")
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !name.isEmpty && endDate >= startDate
    }

    private var durationInWeeks: Int {
        let components = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate)
        return max(1, components.weekOfYear ?? 1)
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

    private func loadPlanData() {
        name = plan.name
        startDate = plan.startDate
        endDate = plan.endDate
        primaryProfile = plan.primaryStrengthProfile
        secondaryProfile = plan.secondaryStrengthProfile
        useSecondaryProfile = plan.secondaryStrengthProfile != nil
        weeklyFrequency = plan.weeklyFrequency
        notes = plan.notes ?? ""
        selectedFolders = plan.folders
        selectedTrainingDays = plan.trainingDays
    }

    // MARK: - Actions

    private func savePlan() {
        plan.name = name
        plan.startDate = startDate
        plan.endDate = endDate
        plan.primaryStrengthProfile = primaryProfile
        plan.secondaryStrengthProfile = useSecondaryProfile ? secondaryProfile : nil
        plan.weeklyFrequency = weeklyFrequency
        plan.notes = notes.isEmpty ? nil : notes
        plan.folders = selectedFolders
        plan.trainingDays = selectedTrainingDays

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: PeriodizationPlan.self, configurations: config) else {
        return Text("Failed to create preview container")
    }

    let plan = PeriodizationPlan(
        name: "Piano Forza 2025",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
        periodizationModel: .linear,
        primaryStrengthProfile: .maxStrength,
        secondaryStrengthProfile: .hypertrophy,
        weeklyFrequency: 4
    )

    container.mainContext.insert(plan)

    return EditPeriodizationPlanView(plan: plan)
        .modelContainer(container)
}
