//
//  PeriodizationTimelineView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Vista timeline della periodizzazione con istogrammi mesocicli navigabili
/// Feature: scorrere il tempo con istogrammi mesocicli → clic apre microcicli → clic apre giorni
struct PeriodizationTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    let plan: PeriodizationPlan

    @State private var selectedMesocycle: Mesocycle?
    @State private var showingMesocycleDetail = false
    @State private var isGenerating = false
    @State private var showingEditPlan = false
    @State private var editMode: EditMode = .inactive
    @State private var editingMesocycle: Mesocycle?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Piano
                planHeaderSection

                // Progress Bar Piano
                planProgressSection

                // Timeline Mesocicli
                mesocyclesTimelineSection
            }
            .padding()
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.large)
        .appScreenBackground()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !plan.mesocycles.isEmpty {
                    Button(editMode == .active ? "Fine" : "Modifica") {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditPlan = true
                } label: {
                    Label("Modifica Piano", systemImage: "pencil")
                }
            }
        }
        .sheet(item: $selectedMesocycle) { mesocycle in
            NavigationStack {
                MesocycleDetailView(mesocycle: mesocycle)
            }
        }
        .sheet(isPresented: $showingEditPlan) {
            EditPeriodizationPlanView(plan: plan)
        }
        .sheet(item: $editingMesocycle) { mesocycle in
            EditMesocycleView(mesocycle: mesocycle)
        }
    }

    // MARK: - Sections

    private var planHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(plan.periodizationModel.rawValue, systemImage: plan.periodizationModel.icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if plan.isActive {
                    Label("Attivo", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Primario")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(plan.primaryStrengthProfile.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Frequenza")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(plan.weeklyFrequency)x/settimana")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            Divider()

            HStack {
                Label(formatDate(plan.startDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(formatDate(plan.endDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(plan.durationInWeeks) settimane")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notes = plan.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var planProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progresso Piano")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(plan.progressPercentage()))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: plan.progressPercentage() / 100.0)
                .tint(.blue)
        }
    }

    private var mesocyclesTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Timeline Mesocicli")
                    .font(.headline)
                    .fontWeight(.bold)

                if editMode == .active {
                    Spacer()
                    Text("Trascina per riordinare")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if plan.mesocycles.isEmpty {
                emptyStateView
            } else if editMode == .active {
                // Edit mode: List con drag-and-drop
                List {
                    ForEach(sortedMesocycles) { mesocycle in
                        MesocycleBarView(mesocycle: mesocycle, editMode: true)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                editingMesocycle = mesocycle
                            }
                    }
                    .onMove(perform: moveMesocycles)
                }
                .listStyle(.plain)
                .listRowSpacing(12)
                .frame(height: CGFloat(sortedMesocycles.count) * 165 + 40)
                .environment(\.editMode, .constant(.active))
                .scrollDisabled(true)
            } else {
                // View mode: lista normale navigabile
                ForEach(sortedMesocycles) { mesocycle in
                    MesocycleBarView(mesocycle: mesocycle, editMode: false)
                        .onTapGesture {
                            selectedMesocycle = mesocycle
                        }
                }
            }
        }
    }

    private var sortedMesocycles: [Mesocycle] {
        plan.mesocycles.sorted(by: { $0.order < $1.order })
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Nessun mesociclo generato")
                .font(.headline)

            Text("Genera i mesocicli per iniziare la periodizzazione")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                generateMesocycles()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }
                    Text(isGenerating ? "Generazione..." : "Genera Mesocicli")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .disabled(isGenerating)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func generateMesocycles() {
        isGenerating = true

        // Usa Task per Swift Concurrency invece di DispatchQueue
        Task { @MainActor in
            // SwiftData richiede main actor, esegui la generazione
            let generator = PeriodizationGenerator()
            let _ = generator.generateCompletePlan(plan)

            // Salva il contesto
            try? modelContext.save()
            isGenerating = false
        }
    }

    private func moveMesocycles(from source: IndexSet, to destination: Int) {
        var mesocycles = sortedMesocycles
        mesocycles.move(fromOffsets: source, toOffset: destination)

        // Aggiorna l'order di ogni mesociclo
        for (index, mesocycle) in mesocycles.enumerated() {
            mesocycle.order = index + 1
        }

        // Salva
        try? modelContext.save()
    }
}

// MARK: - Mesocycle Bar View

/// Vista istogramma per singolo mesociclo
struct MesocycleBarView: View {
    let mesocycle: Mesocycle
    var editMode: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header con numero e nome
            HStack(spacing: 12) {
                Text("M\(mesocycle.order)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(phaseColor)
                    .cornerRadius(8)

                Text(mesocycle.name)
                    .font(.body)
                    .fontWeight(.semibold)

                Spacer()

                if editMode {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            // Barra visuale con informazioni
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(phaseColor.opacity(0.2))
                    .frame(height: 80)

                // Progress overlay
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(phaseColor.opacity(0.4))
                        .frame(width: geometry.size.width * (mesocycle.progressPercentage() / 100.0))
                }
                .frame(height: 80)

                // Contenuto
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(mesocycle.phaseType.rawValue, systemImage: mesocycle.phaseType.icon)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(phaseColor)

                        Text(mesocycle.focusStrengthProfile.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(mesocycle.durationInWeeks) settimane")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if mesocycle.isCurrentlyActive() {
                            Label("In corso", systemImage: "circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 80)

            // Info aggiuntive
            HStack(spacing: 12) {
                Label("\(mesocycle.loadWeeks) carico", systemImage: "arrow.up")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label("\(mesocycle.deloadWeeks) scarico", systemImage: "arrow.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(mesocycle.progressPercentage()))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var phaseColor: Color {
        mesocycle.phaseType.swiftUIColor
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

    return NavigationStack {
        PeriodizationTimelineView(plan: plan)
    }
    .modelContainer(container)
}
