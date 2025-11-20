//
//  PeriodizationPlanListView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//
import SwiftUI
import SwiftData

/// Vista principale lista piani di periodizzazione
struct PeriodizationPlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PeriodizationPlan.startDate, order: .reverse) private var allPlans: [PeriodizationPlan]
    @Query(sort: \PeriodizationFolder.order) private var folders: [PeriodizationFolder]
    @State private var showingCreatePlan = false
    @State private var selectedPlan: PeriodizationPlan?
    @State private var showingAddFolder = false
    @State private var selectedFolder: PeriodizationFolder?
    @State private var expandedFolders: Set<UUID> = []
    private static let noFolderID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    private var plansWithoutFolder: [PeriodizationPlan] {
        allPlans.filter { $0.hasNoFolders }
    }

    private func plans(for folder: PeriodizationFolder) -> [PeriodizationPlan] {
        allPlans.filter { $0.isInFolder(folder) }
    }

    var body: some View {
        NavigationStack {
            AppBackgroundView {
                ScrollView {
                    VStack(spacing: 22) {
                        if allPlans.isEmpty {
                            GlassEmptyStateCard(
                                systemImage: "calendar.badge.checkmark",
                                title: "Nessun Piano di Periodizzazione",
                                description: "Crea il tuo primo piano per organizzare l'allenamento nel tempo"
                            ) {
                                Button("Crea Piano") {
                                    showingCreatePlan = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            ForEach(folders) { folder in
                                let folderPlans = plans(for: folder)
                                if !folderPlans.isEmpty {
                                    FolderDisclosureCard(
                                        title: folder.name,
                                        count: folderPlans.count,
                                        color: folder.color,
                                        isExpanded: binding(for: folder.id),
                                        onEditFolder: { selectedFolder = folder }
                                    ) {
                                        ForEach(folderPlans) { plan in
                                            NavigationLink(destination: PeriodizationTimelineView(plan: plan)) {
                                                PlanRow(
                                                    plan: plan,
                                                    onEdit: { selectedPlan = plan },
                                                    onDelete: { deletePlan(plan) }
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            if !plansWithoutFolder.isEmpty {
                                FolderDisclosureCard(
                                    title: "Senza Folder",
                                    count: plansWithoutFolder.count,
                                    color: .gray.opacity(0.4),
                                    isExpanded: binding(for: Self.noFolderID)
                                ) {
                                    ForEach(plansWithoutFolder) { plan in
                                        NavigationLink(destination: PeriodizationTimelineView(plan: plan)) {
                                            PlanRow(
                                                plan: plan,
                                                onEdit: { selectedPlan = plan },
                                                onDelete: { deletePlan(plan) }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .background(Color.clear)
                .navigationTitle("Periodizzazione")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        if !folders.isEmpty {
                            foldersManagementButton()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingCreatePlan = true
                            } label: {
                                Label("Nuovo Piano", systemImage: "calendar.badge.plus")
                            }
                            Button {
                                showingAddFolder = true
                            } label: {
                                Label("Nuovo Folder", systemImage: "folder.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingCreatePlan) {
                    CreatePeriodizationPlanView()
                }
                .sheet(item: $selectedPlan) { plan in
                    EditPeriodizationPlanView(plan: plan)
                }
                .sheet(isPresented: $showingAddFolder) {
                    AddPeriodizationFolderView()
                }
                .sheet(item: $selectedFolder) { folder in
                    EditPeriodizationFolderView(folder: folder)
                }
            }
        }
    }

    // MARK: - Actions
    private func deletePlan(_ plan: PeriodizationPlan) {
        modelContext.delete(plan)
        try? modelContext.save()
    }

    private func binding(for folderID: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedFolders.contains(folderID) },
            set: { isExpanded in
                if isExpanded {
                    expandedFolders.insert(folderID)
                } else {
                    expandedFolders.remove(folderID)
                }
            }
        )
    }

    @ViewBuilder
    private func foldersManagementButton() -> some View {
        Menu {
            Button {
                showingAddFolder = true
            } label: {
                Label("Nuovo Folder", systemImage: "folder.badge.plus")
            }

            if !folders.isEmpty {
                Divider()
                ForEach(folders) { folder in
                    Button {
                        selectedFolder = folder
                    } label: {
                        HStack {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 10, height: 10)
                            Text(folder.name)
                        }
                    }
                }
            }
        } label: {
            Label("Folder", systemImage: "folder")
        }
    }
}

// MARK: - Plan Row
/// Row per visualizzare un piano nella lista
private struct PlanRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let plan: PeriodizationPlan
    var onEdit: () -> Void
    var onDelete: () -> Void

    private var isActive: Bool {
        plan.isCurrentlyActive()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Text(plan.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                if isActive {
                    Text("ATTIVO")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 8) {
                Label(plan.periodizationModel.rawValue, systemImage: plan.periodizationModel.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Info Profilo
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(plan.primaryStrengthProfile.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                if let secondary = plan.secondaryStrengthProfile {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secondario")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(secondary.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Frequenza")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(plan.weeklyFrequency)x/sett")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            Divider()

            // Progress e Date
            VStack(spacing: 8) {
                HStack {
                    Text(formatDate(plan.startDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatDate(plan.endDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(plan.durationInWeeks) settimane")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if isActive {
                    HStack {
                        ProgressView(value: plan.progressPercentage() / 100.0)
                            .tint(.blue)
                        Text("\(Int(plan.progressPercentage()))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }

            // Stats mesocicli
            if !plan.mesocycles.isEmpty {
                HStack(spacing: 12) {
                    Label("\(plan.mesocycles.count) mesocicli", systemImage: "square.stack.3d.up")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    let totalMicrocycles = plan.mesocycles.reduce(0) { $0 + $1.microcycles.count }
                    if totalMicrocycles > 0 {
                        Label("\(totalMicrocycles) settimane", systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Mostra folder se il piano è in più folder
            if !plan.folders.isEmpty {
                HStack(spacing: 4) {
                    ForEach(plan.folders.prefix(3)) { folder in
                        HStack(spacing: 2) {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 8, height: 8)
                            Text(folder.name)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(folder.color.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    if plan.folders.count > 3 {
                        Text("+\(plan.folders.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.stroke(for: colorScheme), lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Modifica", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Elimina", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                    .padding(6)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Folder Disclosure Card
private struct FolderDisclosureCard<Content: View>: View {
    let title: String
    let count: Int
    let color: Color
    @Binding var isExpanded: Bool
    var onEditFolder: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 12) {
                content()
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text("\(count) piani")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                }

                Spacer()

                if let onEditFolder {
                    Button(action: onEditFolder) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .dashboardCardStyle()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: PeriodizationPlan.self, configurations: config) else {
        return Text("Failed to create preview container")
    }
    // Piano esempio 1 (attivo)
    let plan1 = PeriodizationPlan(
        name: "Forza Massimale 2025",
        startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
        endDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
        periodizationModel: .linear,
        primaryStrengthProfile: .maxStrength,
        secondaryStrengthProfile: .speedStrength,
        weeklyFrequency: 4,
        isActive: true
    )
    // Piano esempio 2 (passato)
    let plan2 = PeriodizationPlan(
        name: "Ipertrofia Estate",
        startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
        endDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
        periodizationModel: .block,
        primaryStrengthProfile: .hypertrophy,
        weeklyFrequency: 5,
        isActive: false
    )
    container.mainContext.insert(plan1)
    container.mainContext.insert(plan2)
    return NavigationStack {
        PeriodizationPlanListView()
    }
    .modelContainer(container)
}
