import SwiftUI
import SwiftData

struct TrainingHomeView: View {
    @Query(sort: [SortDescriptor(\WorkoutCard.createdDate, order: .reverse)]) private var cards: [WorkoutCard]
    @State private var selectedCard: WorkoutCard?
    @State private var recentSessionCard: WorkoutCard?

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView {
                        Label("Nessuna scheda disponibile", systemImage: "stopwatch")
                    } description: {
                        Text("Crea una scheda di allenamento prima di iniziare")
                    }
                } else {
                    List {
                        if let recent = recentSessionCard {
                            Section("Ultima sessione") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(recent.name)
                                        .font(.headline)
                                    Text("\(recent.totalBlocks) blocchi • ~\(recent.estimatedDurationMinutes) min")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Button {
                                        selectedCard = recent
                                    } label: {
                                        Label("Riprendi allenamento", systemImage: "play.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section("Schede disponibili") {
                            ForEach(cards) { card in
                                Button {
                                    recentSessionCard = card
                                    selectedCard = card
                                } label: {
                                    TrainingCardRow(card: card)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Allenamento")
            .navigationDestination(item: $selectedCard) { card in
                WorkoutSessionView(viewModel: WorkoutSessionViewModel(card: card)) { finishedCard in
                    recentSessionCard = finishedCard
                    selectedCard = nil
                }
            }
        }
    }
}

private struct TrainingCardRow: View {
    let card: WorkoutCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(card.name)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(card.cardDescription ?? "Nessuna descrizione")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label("\(card.totalBlocks) blocchi", systemImage: "square.grid.2x2")
                Label("\(card.totalExercises) esercizi", systemImage: "figure.run")
                Label("~\(card.estimatedDurationMinutes)m", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
