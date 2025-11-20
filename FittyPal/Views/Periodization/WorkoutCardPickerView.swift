//
//  WorkoutCardPickerView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// View per selezionare una WorkoutCard da associare a un TrainingDay
struct WorkoutCardPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutCard.createdDate, order: .reverse) private var allCards: [WorkoutCard]

    let trainingDay: TrainingDay
    let onSelect: (WorkoutCard) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if filteredCards.isEmpty {
                    emptyStateView
                } else {
                    cardsList
                }
            }
            .navigationTitle("Seleziona Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Views

    private var cardsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredCards) { card in
                    WorkoutCardPickerRow(card: card)
                        .onTapGesture {
                            selectCard(card)
                        }
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Nessuna scheda disponibile")
                .font(.headline)

            Text("Crea una scheda prima di associarla a un giorno di allenamento")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var filteredCards: [WorkoutCard] {
        // Filtra solo schede valide (non bozze)
        allCards.filter { !$0.isDraft }
    }

    private func selectCard(_ card: WorkoutCard) {
        onSelect(card)
        dismiss()
    }
}

// MARK: - Workout Card Picker Row

struct WorkoutCardPickerRow: View {
    let card: WorkoutCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let splitType = card.splitType {
                HStack(spacing: 4) {
                    Image(systemName: splitType.icon)
                        .font(.caption2)

                    Text(splitType.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(card.totalExercises) esercizi", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label("\(card.estimatedDurationMinutes) min", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: WorkoutCard.self, configurations: config) else {
        return Text("Failed to create preview container")
    }

    let card = WorkoutCard(
        name: "Upper Body Strength",
        splitType: .upperLower
    )
    container.mainContext.insert(card)

    let day = TrainingDay(date: Date())

    return WorkoutCardPickerView(trainingDay: day) { _ in
        print("Card selected")
    }
    .modelContainer(container)
}
