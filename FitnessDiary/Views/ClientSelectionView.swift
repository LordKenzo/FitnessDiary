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
                            Label("Nessun cliente", systemImage: "person.3")
                        } description: {
                            Text("Crea dei clienti per poter assegnare le schede")
                        }
                    } else {
                        ContentUnavailableView {
                            Label("Nessun risultato", systemImage: "magnifyingglass")
                        } description: {
                            Text("Prova con un termine di ricerca diverso")
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
                            Text("\(localSelection.count) selezionati")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Cerca cliente")
            .navigationTitle("Assegna a Clienti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") {
                        saveSelection()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if !localSelection.isEmpty {
                        Button("Deseleziona Tutto") {
                            localSelection.removeAll()
                        }
                    }
                }
            }
        }
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
