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
                matchesOwner = card.assignedTo.isEmpty
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
        filteredCards.filter { $0.folder == nil }
    }

    private func cards(for folder: WorkoutFolder) -> [WorkoutCard] {
        filteredCards.filter { $0.folder?.id == folder.id }
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
                    // Schede senza folder
                    if !cardsWithoutFolder.isEmpty {
                        Section {
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
                        } header: {
                            Text("Senza Folder")
                        }
                    }

                    // Schede organizzate per folder
                    ForEach(folders) { folder in
                        let folderCards = cards(for: folder)
                        if !folderCards.isEmpty {
                            Section {
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
                            } header: {
                                HStack {
                                    Circle()
                                        .fill(folder.color)
                                        .frame(width: 12, height: 12)
                                    Text(folder.name)
                                    Spacer()
                                    Button {
                                        selectedFolder = folder
                                    } label: {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
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
                        selectedClient = client
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
            HStack {
                Text(card.name)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: card.assignedTo.isEmpty ? "person.fill" : "person.circle.fill")
                        .font(.caption)
                    Text(card.assignmentText)
                        .font(.caption)
                }
                .foregroundStyle(card.assignedTo.isEmpty ? .green : .blue)
            }

            if let description = card.cardDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(card.totalExercises)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(card.totalSets) serie", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(card.createdDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutCardListView()
        .modelContainer(for: [WorkoutCard.self, WorkoutFolder.self, Client.self])
}
