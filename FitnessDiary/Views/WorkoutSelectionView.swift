//
//  WorkoutSelectionView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI
import SwiftData

struct WorkoutSelectionView: View {
    @Environment(\.modelContext) private var modelContext

    // Query per schede workout assegnate
    @Query(filter: #Predicate<WorkoutCard> { card in
        card.isAssignedToMe || !card.assignedTo.isEmpty
    }, sort: \WorkoutCard.name)
    private var assignedCards: [WorkoutCard]

    // Query per sessioni in corso
    @Query(filter: #Predicate<WorkoutSession> { session in
        !session.isCompleted
    })
    private var activeSessions: [WorkoutSession]

    // Query per clienti (per selezione opzionale)
    @Query(sort: \Client.firstName)
    private var clients: [Client]

    // State
    @State private var selectedClient: Client?
    @State private var showingClientPicker = false
    @State private var searchText = ""
    @State private var navigateToActiveWorkout = false
    @State private var currentSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con selezione cliente opzionale
                clientSelectionHeader

                // Resume workout alert se esiste sessione in corso
                if let activeSession = activeSessions.first {
                    resumeWorkoutBanner(activeSession)
                }

                // Lista schede disponibili
                if filteredCards.isEmpty {
                    emptyState
                } else {
                    workoutCardsList
                }
            }
            .navigationTitle("Inizia Allenamento")
            .navigationDestination(isPresented: $navigateToActiveWorkout) {
                if let session = currentSession {
                    ActiveWorkoutView(session: session)
                }
            }
            .searchable(text: $searchText, prompt: "Cerca scheda...")
        }
    }

    // MARK: - Client Selection Header

    private var clientSelectionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Allenamento per:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showingClientPicker = true
            } label: {
                HStack {
                    Image(systemName: selectedClient == nil ? "person.circle" : "person.circle.fill")
                        .font(.title3)
                        .foregroundStyle(selectedClient == nil ? .secondary : .blue)

                    Text(selectedClient?.fullName ?? "Me Stesso")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .sheet(isPresented: $showingClientPicker) {
            ClientPickerSheet(selectedClient: $selectedClient, clients: clients)
        }
    }

    // MARK: - Resume Workout Banner

    private func resumeWorkoutBanner(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Allenamento in corso")
                        .font(.headline)

                    Text("\(session.workoutCard.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Iniziato \(formatRelativeTime(session.startDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    resumeWorkout(session)
                } label: {
                    Text("Riprendi")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    abandonWorkout(session)
                } label: {
                    Text("Abbandona")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Workout Cards List

    private var workoutCardsList: some View {
        List {
            ForEach(filteredCards) { card in
                WorkoutCardRow(card: card) {
                    startWorkout(card: card)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nessuna Scheda Assegnata", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Crea una scheda nella tab 'Schede' e assegnala a te stesso o a un cliente per iniziare")
        }
    }

    // MARK: - Filtered Cards

    private var filteredCards: [WorkoutCard] {
        var cards = assignedCards

        // Filtra per cliente se selezionato
        if let client = selectedClient {
            cards = cards.filter { $0.assignedTo.contains(where: { $0.id == client.id }) }
        } else {
            // Se nessun cliente selezionato, mostra solo schede assegnate a me
            cards = cards.filter { $0.isAssignedToMe }
        }

        // Filtra per ricerca
        if !searchText.isEmpty {
            cards = cards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Escludi bozze
        cards = cards.filter { !$0.isDraft }

        return cards
    }

    // MARK: - Actions

    private func startWorkout(card: WorkoutCard) {
        // Crea nuova WorkoutSession
        let session = WorkoutSession(
            workoutCard: card,
            client: selectedClient
        )

        modelContext.insert(session)

        do {
            try modelContext.save()
            currentSession = session
            navigateToActiveWorkout = true
        } catch {
            print("⚠️ Failed to save workout session: \(error)")
        }
    }

    private func resumeWorkout(_ session: WorkoutSession) {
        currentSession = session
        navigateToActiveWorkout = true
    }

    private func abandonWorkout(_ session: WorkoutSession) {
        // Salva come CompletedWorkout (incompleto)
        let completedWorkout = CompletedWorkout.fromSession(session)
        modelContext.insert(completedWorkout)

        // Rimuovi la sessione
        modelContext.delete(session)

        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to abandon workout: \(error)")
        }
    }

    // MARK: - Helpers

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Workout Card Row

struct WorkoutCardRow: View {
    let card: WorkoutCard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(.headline)

                        Text(card.assignmentText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }

                // Statistiche scheda
                HStack(spacing: 16) {
                    Label("\(card.totalBlocks)", systemImage: "square.stack.3d.up")
                    Label("\(card.totalExercises)", systemImage: "figure.strengthtraining.traditional")
                    Label("\(card.totalSets)", systemImage: "list.number")
                    Label("\(card.estimatedDurationMinutes)min", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Descrizione se presente
                if let description = card.cardDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Client Picker Sheet

struct ClientPickerSheet: View {
    @Binding var selectedClient: Client?
    let clients: [Client]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Opzione "Me Stesso"
                Button {
                    selectedClient = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        Text("Me Stesso")
                            .font(.headline)

                        Spacer()

                        if selectedClient == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Lista clienti
                Section("Clienti") {
                    ForEach(clients) { client in
                        Button {
                            selectedClient = client
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)

                                Text(client.fullName)
                                    .font(.headline)

                                Spacer()

                                if selectedClient?.id == client.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Seleziona Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutSelectionView()
        .modelContainer(for: [WorkoutCard.self, WorkoutSession.self, Client.self], inMemory: true)
}
