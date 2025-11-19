import SwiftUI
import SwiftData

struct ClientSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedClients: [Client]
    let clients: [Client]

    @State private var searchText = ""
    @State private var localSelection: Set<UUID>

    init(selectedClients: Binding<[Client]>, clients: [Client]) {
        self._selectedClients = selectedClients
        self.clients = clients
        // Inizializza la selezione locale con i clienti già selezionati
        _localSelection = State(initialValue: Set(selectedClients.wrappedValue.map { $0.id }))
    }

    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        }
        return clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredClients.isEmpty {
                    if clients.isEmpty {
                        ContentUnavailableView {
                            Label(L("clients.no.clients"), systemImage: "person.3")
                        } description: {
                            Text(L("clients.selection.empty.description"))
                        }
                    } else {
                        ContentUnavailableView {
                            Label(L("search.no.results"), systemImage: "magnifyingglass")
                        } description: {
                            Text(L("search.no.results.description"))
                        }
                    }
                } else {
                    Section {
                        ForEach(filteredClients) { client in
                            Button {
                                toggleSelection(for: client)
                            } label: {
                                HStack {
                                    if let profileImage = client.profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundStyle(.gray)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(client.fullName)
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        if let gym = client.gym, !gym.isEmpty {
                                            Text(gym)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if localSelection.contains(client.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.gray.opacity(0.3))
                                            .font(.title3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        if !localSelection.isEmpty {
                            Text(String(format: L("clients.selected.count"), localSelection.count))
                        }
                    }
                }
            }
            .glassScrollBackground()
            .searchable(text: $searchText, prompt: L("clients.search"))
            .navigationTitle(L("clients.assign"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.done")) {
                        saveSelection()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if !localSelection.isEmpty {
                        Button(L("common.deselect.all")) {
                            localSelection.removeAll()
                        }
                    }
                }
            }
        }
        .appScreenBackground()
    }

    private func toggleSelection(for client: Client) {
        if localSelection.contains(client.id) {
            localSelection.remove(client.id)
        } else {
            localSelection.insert(client.id)
        }
    }

    private func saveSelection() {
        // Aggiorna i clienti selezionati basandosi sulla selezione locale
        selectedClients = clients.filter { localSelection.contains($0.id) }
        dismiss()
    }
}

#Preview {
    ClientSelectionView(
        selectedClients: .constant([]),
        clients: []
    )
}
