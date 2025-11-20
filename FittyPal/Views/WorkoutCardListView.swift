import SwiftUI
import SwiftData

struct WorkoutCardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutCard.name) private var allCards: [WorkoutCard]
    @Query(sort: \WorkoutFolder.order) private var folders: [WorkoutFolder]
    @Query(sort: \Client.firstName) private var clients: [Client]
    @State private var showingAddCard = false
    @State private var selectedCard: WorkoutCard?
    @State private var searchText = ""
    @State private var showingAddFolder = false
    @State private var selectedFolder: WorkoutFolder?
    @State private var filterOwner: FilterOwner = .all
    @State private var selectedClient: Client?
    @State private var expandedFolders: Set<UUID> = []
    @State private var showingDeletionAlert = false
    @State private var deletionAlertMessage = ""
    @State private var cardToDelete: WorkoutCard?
    @ObservedObject private var localizationManager = LocalizationManager.shared
    private static let noFolderID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    @MainActor
    enum FilterOwner: CaseIterable {
        case all
        case mine
        case client

        var localizedName: String {
            switch self {
            case .all: return L("cards.filter.all")
            case .mine: return L("cards.filter.mine")
            case .client: return L("cards.filter.client")
            }
        }
    }

    private var filteredCards: [WorkoutCard] {
        allCards.filter { card in
            let matchesSearch = searchText.isEmpty || card.name.localizedCaseInsensitiveContains(searchText)
            let matchesOwner: Bool
            switch filterOwner {
            case .all:
                matchesOwner = true
            case .mine:
                matchesOwner = card.isAssignedToMe
            case .client:
                if let selectedClient = selectedClient {
                    matchesOwner = card.assignedTo.contains(where: { $0.id == selectedClient.id })
                } else {
                    matchesOwner = !card.assignedTo.isEmpty
                }
            }
            return matchesSearch && matchesOwner
        }
    }

    private var cardsWithoutFolder: [WorkoutCard] {
        filteredCards.filter { $0.hasNoFolders }
    }

    private func cards(for folder: WorkoutFolder) -> [WorkoutCard] {
        filteredCards.filter { $0.isInFolder(folder) }
    }

    var body: some View {
        NavigationStack {
            AppBackgroundView {
                ScrollView {
                    VStack(spacing: 22) {
                        if allCards.isEmpty {
                            GlassEmptyStateCard(
                                systemImage: "doc.text",
                                title: L("cards.no.cards"),
                                description: L("cards.no.cards.description")
                            ) {
                                Button(L("cards.create")) {
                                    showingAddCard = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            ForEach(folders) { folder in
                                let folderCards = cards(for: folder)
                                if !folderCards.isEmpty {
                                    FolderDisclosureCard(
                                        title: folder.name,
                                        count: folderCards.count,
                                        color: folder.color,
                                        isExpanded: binding(for: folder.id),
                                        onEditFolder: { selectedFolder = folder }
                                    ) {
                                        ForEach(folderCards) { card in
                                            WorkoutCardRow(
                                                card: card,
                                                onEdit: { selectedCard = card },
                                                onDelete: { deleteCard(card) }
                                            )
                                            .onTapGesture { selectedCard = card }
                                        }
                                    }
                                }
                            }
                            if !cardsWithoutFolder.isEmpty {
                                FolderDisclosureCard(
                                    title: "Senza Folder",
                                    count: cardsWithoutFolder.count,
                                    color: .gray.opacity(0.4),
                                    isExpanded: binding(for: Self.noFolderID)
                                ) {
                                    ForEach(cardsWithoutFolder) { card in
                                        WorkoutCardRow(
                                            card: card,
                                            onEdit: { selectedCard = card },
                                            onDelete: { deleteCard(card) }
                                        )
                                        .onTapGesture { selectedCard = card }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .background(Color.clear)
                .searchable(text: $searchText, prompt: L("cards.search"))
                .navigationTitle("Schede")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        ownerFilterMenu()
                        if !folders.isEmpty {
                            foldersManagementButton()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingAddCard = true
                            } label: {
                                Label("Nuova Scheda", systemImage: "doc.text")
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
                .sheet(isPresented: $showingAddCard) {
                    AddWorkoutCardView(folders: folders, clients: clients)
                }
                .sheet(item: $selectedCard) { card in
                    EditWorkoutCardView(card: card, folders: folders, clients: clients)
                }
                .sheet(isPresented: $showingAddFolder) {
                    AddFolderView()
                }
                .sheet(item: $selectedFolder) { folder in
                    EditFolderView(folder: folder)
                }
                .alert("Impossibile Eliminare", isPresented: $showingDeletionAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(deletionAlertMessage)
                }
            }
        }
    }




    private func deleteCard(_ card: WorkoutCard) {
        // Verifica se la scheda è assegnata a clienti
        if !card.assignedTo.isEmpty {
            let clientNames = card.assignedTo.map { $0.fullName }.joined(separator: ", ")
            deletionAlertMessage = "Impossibile eliminare la scheda \"\(card.name)\" perché è assegnata ai seguenti clienti: \(clientNames)"
            showingDeletionAlert = true
            return
        }

        // Verifica se la scheda è usata in periodizzazioni attive
        let descriptor = FetchDescriptor<TrainingDay>()
        if let trainingDays = try? modelContext.fetch(descriptor) {
            // Trova i giorni che usano questa scheda
            let daysUsingCard = trainingDays.filter { $0.workoutCard?.id == card.id }

            if !daysUsingCard.isEmpty {
                // Trova le periodizzazioni attive che contengono questi giorni
                var activePlanNames: [String] = []

                for day in daysUsingCard {
                    if let microcycle = day.microcycle,
                       let mesocycle = microcycle.mesocycle,
                       let plan = mesocycle.plan,
                       plan.isCurrentlyActive() {
                        if !activePlanNames.contains(plan.name) {
                            activePlanNames.append(plan.name)
                        }
                    }
                }

                if !activePlanNames.isEmpty {
                    let planList = activePlanNames.joined(separator: ", ")
                    deletionAlertMessage = "Impossibile eliminare la scheda \"\(card.name)\" perché è utilizzata nelle seguenti periodizzazioni attive: \(planList)"
                    showingDeletionAlert = true
                    return
                }
            }
        }

        // Se tutti i controlli passano, elimina la scheda
        modelContext.delete(card)
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
    private func ownerFilterMenu() -> some View {
        Menu {
            ForEach(FilterOwner.allCases, id: \.self) { owner in
                Button(action: {
                    filterOwner = owner
                    if owner != .client {
                        selectedClient = nil
                    }
                }) {
                    Label(owner.localizedName, systemImage: filterOwner == owner ? "checkmark" : "")
                }
            }

            if filterOwner == .client && !clients.isEmpty {
                Divider()
                ForEach(clients) { client in
                    Button(action: {
                        // Toggle: se clicco sul cliente già selezionato, torna a "tutti"
                        if selectedClient?.id == client.id {
                            filterOwner = .all
                            selectedClient = nil
                        } else {
                            selectedClient = client
                        }
                    }) {
                        Label(client.fullName, systemImage: selectedClient?.id == client.id ? "checkmark" : "person")
                    }
                }
            }
        } label: {
            Label(filterOwner == .client && selectedClient != nil ? selectedClient!.fullName : filterOwner.localizedName,
                  systemImage: "person.crop.circle")
        }
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

struct WorkoutCardRow: View {
    let card: WorkoutCard
    var onEdit: () -> Void
    var onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(card.name)
                    .font(.headline)

                if card.isDraft {
                    Text("BOZZA")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                } else {
                    Text("PRONTA")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if let description = card.cardDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Label("\(card.totalBlocks) blocchi", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("~\(card.estimatedDurationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Label("\(card.totalExercises) esercizi", systemImage: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(card.totalSets) serie", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Mostra folder se la scheda è in più folder
            if !card.folders.isEmpty {
                HStack(spacing: 4) {
                    ForEach(card.folders.prefix(3)) { folder in
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
                    if card.folders.count > 3 {
                        Text("+\(card.folders.count - 3)")
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
                Button(L("common.edit")) {
                    onEdit()
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(L("common.delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                    .padding(6)
            }
        }
    }
}

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
                    Text("\(count) schede")
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
    WorkoutCardListView()
        .modelContainer(for: [WorkoutCard.self, WorkoutFolder.self, Client.self])
}
