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

    enum FilterOwner: String, CaseIterable {
        case all = "Tutte"
        case mine = "Mio"
        case client = "Cliente"
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
            List {
                if allCards.isEmpty {
                    ContentUnavailableView {
                        Label("Nessuna scheda", systemImage: "doc.text")
                    } description: {
                        Text("Crea la tua prima scheda di allenamento")
                    } actions: {
                        Button("Crea Scheda") {
                            showingAddCard = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    // Schede organizzate per folder (collassabili)
                    ForEach(folders) { folder in
                        let folderCards = cards(for: folder)
                        if !folderCards.isEmpty {
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedFolders.contains(folder.id) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedFolders.insert(folder.id)
                                        } else {
                                            expandedFolders.remove(folder.id)
                                        }
                                    }
                                )
                            ) {
                                ForEach(folderCards) { card in
                                    WorkoutCardRow(card: card)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedCard = card
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                deleteCard(card)
                                            } label: {
                                                Label("Elimina", systemImage: "trash")
                                            }
                                            Button {
                                                selectedCard = card
                                            } label: {
                                                Label("Modifica", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                }
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(folder.color)
                                        .frame(width: 12, height: 12)
                                    Text(folder.name)
                                        .font(.headline)
                                    Text("(\(folderCards.count))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button {
                                        selectedFolder = folder
                                    } label: {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                    .onTapGesture {
                                        selectedFolder = folder
                                    }
                                }
                            }
                        }
                    }

                    // Schede senza folder (in basso)
                    if !cardsWithoutFolder.isEmpty {
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedFolders.contains(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!) },
                                set: { isExpanded in
                                    let noFolderUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                                    if isExpanded {
                                        expandedFolders.insert(noFolderUUID)
                                    } else {
                                        expandedFolders.remove(noFolderUUID)
                                    }
                                }
                            )
                        ) {
                            ForEach(cardsWithoutFolder) { card in
                                WorkoutCardRow(card: card)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedCard = card
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteCard(card)
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                        Button {
                                            selectedCard = card
                                        } label: {
                                            Label("Modifica", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        } label: {
                            HStack {
                                Text("Senza Folder")
                                    .font(.headline)
                                Text("(\(cardsWithoutFolder.count))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Cerca scheda")
            .navigationTitle("Schede")
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
        }
    }

    private func deleteCard(_ card: WorkoutCard) {
        modelContext.delete(card)
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
                    Label(owner.rawValue, systemImage: filterOwner == owner ? "checkmark" : "")
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
            Label(filterOwner == .client && selectedClient != nil ? selectedClient!.fullName : filterOwner.rawValue,
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutCardListView()
        .modelContainer(for: [WorkoutCard.self, WorkoutFolder.self, Client.self])
}
