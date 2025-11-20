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
        .sheet(item: $selectedMesocycle) { mesocycle in
            NavigationStack {
                MesocycleDetailView(mesocycle: mesocycle)
            }
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
            Text("Timeline Mesocicli")
                .font(.headline)
                .fontWeight(.bold)

            if plan.mesocycles.isEmpty {
                emptyStateView
            } else {
                ForEach(plan.mesocycles.sorted(by: { $0.order < $1.order })) { mesocycle in
                    MesocycleBarView(mesocycle: mesocycle)
                        .onTapGesture {
                            selectedMesocycle = mesocycle
                        }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Nessun mesociclo generato")
                .font(.headline)

            Text("Genera i mesocicli per iniziare la periodizzazione")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
}

// MARK: - Mesocycle Bar View

/// Vista istogramma per singolo mesociclo
struct MesocycleBarView: View {
    let mesocycle: Mesocycle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header con numero e nome
            HStack {
                Text("M\(mesocycle.order)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(phaseColor)
                    .cornerRadius(6)

                Text(mesocycle.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Barra visuale con informazioni
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(phaseColor.opacity(0.2))
                    .frame(height: 60)

                // Progress overlay
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(phaseColor.opacity(0.4))
                        .frame(width: geometry.size.width * (mesocycle.progressPercentage() / 100.0))
                }
                .frame(height: 60)

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
            .frame(height: 60)

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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var phaseColor: Color {
        switch mesocycle.phaseType {
        case .accumulation:
            return .blue
        case .intensification:
            return .orange
        case .transformation:
            return .purple
        case .deload:
            return .green
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PeriodizationPlan.self, configurations: config)

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
