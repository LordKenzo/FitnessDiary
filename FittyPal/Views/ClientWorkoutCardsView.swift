import SwiftUI
import SwiftData

struct ClientWorkoutCardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [WorkoutCard]
    let client: Client

    var assignedCards: [WorkoutCard] {
        allCards.filter { card in
            card.assignedTo.contains(where: { $0.id == client.id })
        }.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        List {
            if assignedCards.isEmpty {
                ContentUnavailableView {
                    Label("Nessuna Scheda", systemImage: "list.bullet.clipboard")
                } description: {
                    Text("Non ci sono schede assegnate a \(client.fullName)")
                }
            } else {
                ForEach(assignedCards) { card in
                    NavigationLink {
                        ClientWorkoutCardDetailView(card: card, client: client)
                    } label: {
                        WorkoutCardRowForClient(card: card)
                    }
                }
            }
        }
        .navigationTitle("Schede di \(client.firstName)")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}

struct WorkoutCardRowForClient: View {
    let card: WorkoutCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.name)
                .font(.headline)

            if let description = card.cardDescription {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                Label("\(card.totalBlocks) bl.", systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(card.totalExercises) es.", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(card.totalSets) serie", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("~\(card.estimatedDurationMinutes) min", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ClientWorkoutCardDetailView: View {
    let card: WorkoutCard
    let client: Client

    var body: some View {
        List {
            headerSection
            statsSection
            blocksSection
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(card.name)
                    .font(.title2)
                    .bold()

                if let description = card.cardDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var statsSection: some View {
        Section {
            HStack {
                Label("Blocchi", systemImage: "square.stack.3d.up")
                Spacer()
                Text("\(card.totalBlocks)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Esercizi", systemImage: "figure.strengthtraining.traditional")
                Spacer()
                Text("\(card.totalExercises)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Serie totali", systemImage: "number")
                Spacer()
                Text("\(card.totalSets)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Durata stimata", systemImage: "clock")
                Spacer()
                Text("~\(card.estimatedDurationMinutes) min")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Riepilogo")
        }
    }

    private var blocksSection: some View {
        ForEach(Array(card.blocks.enumerated()), id: \.element.id) { index, block in
            if block.blockType == .rest {
                Section {
                    HStack {
                        Label("Durata", systemImage: "clock")
                        Spacer()
                        Text(block.formattedRestTime ?? "--")
                            .fontWeight(.medium)
                    }
                } header: {
                    Label("Riposo", systemImage: "moon.zzz.fill")
                        .foregroundStyle(.orange)
                }
            } else {
                Section {
                    ForEach(block.exerciseItems) { exerciseItem in
                        NavigationLink {
                            ClientWorkoutExerciseDetailView(
                                exerciseItem: exerciseItem,
                                client: client
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                if let exercise = exerciseItem.exercise {
                                    Text(exercise.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }

                                if block.blockType == .simple {
                                    Text("\(exerciseItem.sets.count) serie")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        if block.blockType == .method, let method = block.methodType {
                            Image(systemName: method.icon)
                                .foregroundStyle(method.color)
                            Text(method.rawValue)
                        } else {
                            Text("Blocco \(index + 1)")
                        }

                        if block.blockType == .method {
                            Text("• \(block.globalSets) serie")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct ClientWorkoutExerciseDetailView: View {
    let exerciseItem: WorkoutExerciseItem
    let client: Client

    var oneRepMax: Double? {
        guard let exercise = exerciseItem.exercise,
              let big5 = exercise.big5Exercise else { return nil }
        return client.getOneRepMax(for: big5)
    }

    var body: some View {
        List {
            Section("Esercizio") {
                if let exercise = exerciseItem.exercise {
                    Text(exercise.name)
                        .font(.headline)
                }
            }

            if let oneRM = oneRepMax,
               let exercise = exerciseItem.exercise,
               let big5 = exercise.big5Exercise {
                Section("Massimale Cliente") {
                    HStack {
                        Text(big5.rawValue)
                        Spacer()
                        Text("\(String(format: "%.1f", oneRM)) kg")
                            .foregroundStyle(.blue)
                            .bold()
                    }
                }
            }

            Section("Serie") {
                ForEach(exerciseItem.sets) { set in
                    HStack(spacing: 16) {
                        Text("Serie \(set.order + 1)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .leading)

                        if set.setType == .reps {
                            HStack(spacing: 4) {
                                if let reps = set.reps {
                                    Text("\(reps)")
                                    Text("rip")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if set.actualLoadType == .absolute {
                                if let weight = set.weight {
                                    HStack(spacing: 4) {
                                        Text("\(String(format: "%.1f", weight))")
                                        Text("kg")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    // Mostra percentuale se disponibile 1RM
                                    if let oneRM = oneRepMax, oneRM > 0 {
                                        let percentage = (weight / oneRM) * 100.0
                                        Text("(\(Int(percentage))%)")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            } else {
                                if let percentage = set.percentageOfMax {
                                    HStack(spacing: 4) {
                                        Text("\(Int(percentage))")
                                        Text("%")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    // Mostra kg se disponibile 1RM
                                    if let oneRM = oneRepMax {
                                        let weight = (percentage / 100.0) * oneRM
                                        Text("(\(String(format: "%.1f", weight)) kg)")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        } else {
                            if let duration = set.duration {
                                let minutes = Int(duration) / 60
                                let seconds = Int(duration) % 60
                                if minutes > 0 {
                                    Text("\(minutes)m \(seconds)s")
                                } else {
                                    Text("\(seconds)s")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Dettaglio Esercizio")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutCard.self, Client.self, configurations: config)

    let client = Client(firstName: "Mario", lastName: "Rossi")
    container.mainContext.insert(client)

    return NavigationStack {
        ClientWorkoutCardsView(client: client)
    }
    .modelContainer(container)
}
