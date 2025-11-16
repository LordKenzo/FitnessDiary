//
//  WorkoutHistoryView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext

    // Query per allenamenti completati (ordinati dal più recente)
    @Query(sort: \CompletedWorkout.completedDate, order: .reverse)
    private var completedWorkouts: [CompletedWorkout]

    // Query per clienti (per filtri)
    @Query(sort: \Client.firstName)
    private var clients: [Client]

    // Query per schede (per filtri)
    @Query(sort: \WorkoutCard.name)
    private var workoutCards: [WorkoutCard]

    // State
    @State private var searchText = ""
    @State private var selectedClient: Client?
    @State private var selectedCard: WorkoutCard?
    @State private var showingFilters = false
    @State private var selectedWorkout: CompletedWorkout?
    @State private var showingDetail = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary stats header
                if !filteredWorkouts.isEmpty {
                    summaryStatsHeader
                    Divider()
                }

                // Workouts list
                if filteredWorkouts.isEmpty {
                    emptyState
                } else {
                    workoutsList
                }
            }
            .navigationTitle("Storico Allenamenti")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Cerca allenamento...")
            .sheet(isPresented: $showingFilters) {
                FiltersSheet(
                    selectedClient: $selectedClient,
                    selectedCard: $selectedCard,
                    clients: clients,
                    cards: workoutCards
                )
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }

    // MARK: - Summary Stats Header

    private var summaryStatsHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                StatBox(
                    title: "Totale",
                    value: "\(filteredWorkouts.count)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )

                StatBox(
                    title: "Questa Settimana",
                    value: "\(workoutsThisWeek)",
                    icon: "calendar.circle.fill",
                    color: .green
                )

                StatBox(
                    title: "Tempo Totale",
                    value: totalActiveTime,
                    icon: "clock.fill",
                    color: .orange
                )

                StatBox(
                    title: "Media Durata",
                    value: averageDuration,
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }

    // MARK: - Workouts List

    private var workoutsList: some View {
        List {
            ForEach(groupedWorkouts.keys.sorted(by: >), id: \.self) { date in
                Section {
                    ForEach(groupedWorkouts[date] ?? []) { workout in
                        WorkoutHistoryRow(workout: workout)
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                    }
                    .onDelete { indexSet in
                        deleteWorkouts(at: indexSet, in: groupedWorkouts[date] ?? [])
                    }
                } header: {
                    Text(formatSectionDate(date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nessun Allenamento", systemImage: "figure.run.circle")
        } description: {
            if hasActiveFilters {
                Text("Nessun allenamento trovato con i filtri selezionati")
            } else {
                Text("Gli allenamenti completati appariranno qui")
            }
        } actions: {
            if hasActiveFilters {
                Button("Rimuovi Filtri") {
                    clearFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Filtered & Grouped Workouts

    private var filteredWorkouts: [CompletedWorkout] {
        var workouts = completedWorkouts

        // Filter by client
        if let client = selectedClient {
            workouts = workouts.filter { $0.client?.id == client.id }
        }

        // Filter by card
        if let card = selectedCard {
            workouts = workouts.filter { $0.workoutCard.id == card.id }
        }

        // Filter by search
        if !searchText.isEmpty {
            workouts = workouts.filter {
                $0.workoutCard.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return workouts
    }

    private var groupedWorkouts: [String: [CompletedWorkout]] {
        Dictionary(grouping: filteredWorkouts) { workout in
            Calendar.current.startOfDay(for: workout.completedDate).description
        }
    }

    // MARK: - Computed Stats

    private var workoutsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return filteredWorkouts.filter { $0.completedDate >= weekAgo }.count
    }

    private var totalActiveTime: String {
        let total = filteredWorkouts.reduce(0) { $0 + $1.activeDuration }
        let hours = Int(total) / 3600
        if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(total) / 60
            return "\(minutes)m"
        }
    }

    private var averageDuration: String {
        guard !filteredWorkouts.isEmpty else { return "--" }
        let avg = filteredWorkouts.reduce(0) { $0 + $1.activeDuration } / Double(filteredWorkouts.count)
        let minutes = Int(avg) / 60
        return "\(minutes)m"
    }

    private var hasActiveFilters: Bool {
        selectedClient != nil || selectedCard != nil
    }

    // MARK: - Actions

    private func clearFilters() {
        selectedClient = nil
        selectedCard = nil
    }

    private func deleteWorkouts(at offsets: IndexSet, in workouts: [CompletedWorkout]) {
        for index in offsets {
            modelContext.delete(workouts[index])
        }

        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to delete workout: \(error)")
        }
    }

    private func formatSectionDate(_ dateString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            return dateString
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Oggi"
        } else if calendar.isDateInYesterday(date) {
            return "Ieri"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }
    }
}

// MARK: - Workout History Row

struct WorkoutHistoryRow: View {
    let workout: CompletedWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutCard.name)
                        .font(.headline)

                    if let client = workout.client {
                        Text(client.fullName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Completion badge
                if workout.wasCompletelyFinished {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }

            // Stats
            HStack(spacing: 16) {
                Label(workout.shortDuration, systemImage: "clock")
                Label("\(workout.totalSetsCompleted)/\(workout.totalSetsPlanned)", systemImage: "list.number")

                if let rpe = workout.averageRPE {
                    Label(String(format: "RPE %.1f", rpe), systemImage: "heart.fill")
                }

                if let rating = workout.overallRating {
                    HStack(spacing: 2) {
                        ForEach(0..<Int(rating), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.yellow)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Notes preview
            if let notes = workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Box Component

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(minWidth: 120)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Filters Sheet

struct FiltersSheet: View {
    @Binding var selectedClient: Client?
    @Binding var selectedCard: WorkoutCard?

    let clients: [Client]
    let cards: [WorkoutCard]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Cliente") {
                    Picker("Cliente", selection: $selectedClient) {
                        Text("Tutti").tag(nil as Client?)
                        ForEach(clients) { client in
                            Text(client.fullName).tag(client as Client?)
                        }
                    }
                }

                Section("Scheda") {
                    Picker("Scheda", selection: $selectedCard) {
                        Text("Tutte").tag(nil as WorkoutCard?)
                        ForEach(cards) { card in
                            Text(card.name).tag(card as WorkoutCard?)
                        }
                    }
                }

                Section {
                    Button("Rimuovi Tutti i Filtri") {
                        selectedClient = nil
                        selectedCard = nil
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filtri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Workout Detail View

struct WorkoutDetailView: View {
    let workout: CompletedWorkout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header info
                    headerSection

                    Divider()

                    // Performance by exercise
                    performanceSection

                    Divider()

                    // Stats
                    statsSection

                    // Notes
                    if let notes = workout.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                }
                .padding()
            }
            .navigationTitle(workout.workoutCard.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(workout.formattedDate)
                        .font(.subheadline)
                }

                Spacer()

                if let client = workout.client {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Cliente")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(client.fullName)
                            .font(.subheadline)
                    }
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Durata")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(workout.formattedDuration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Serie")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(workout.totalSetsCompleted) / \(workout.totalSetsPlanned)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                if let rpe = workout.averageRPE {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RPE Medio")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(String(format: "%.1f", rpe))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance per Esercizio")
                .font(.headline)

            ForEach(Array(workout.performancesByExercise().keys.sorted()), id: \.self) { exerciseName in
                let performances = workout.performancesByExercise()[exerciseName] ?? []

                VStack(alignment: .leading, spacing: 8) {
                    Text(exerciseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(performances.enumerated()), id: \.offset) { index, performance in
                        HStack {
                            Text("Serie \(index + 1):")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(performance.performanceDescription)
                                .font(.caption)

                            Spacer()

                            if let rpe = performance.rpe {
                                Text("RPE \(String(format: "%.1f", rpe))")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiche")
                .font(.headline)

            HStack(spacing: 12) {
                if let avgWeight = workout.averageWeight {
                    StatDetailBox(
                        title: "Peso Medio",
                        value: String(format: "%.1f kg", avgWeight),
                        icon: "scalemass"
                    )
                }

                if let avgReps = workout.averageReps {
                    StatDetailBox(
                        title: "Reps Medie",
                        value: String(format: "%.1f", avgReps),
                        icon: "number"
                    )
                }

                StatDetailBox(
                    title: "Kg Totali",
                    value: String(format: "%.0f kg", workout.totalWeightLifted),
                    icon: "arrow.up.circle"
                )
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note")
                .font(.headline)

            Text(notes)
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct StatDetailBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    WorkoutHistoryView()
        .modelContainer(for: [CompletedWorkout.self, Client.self, WorkoutCard.self], inMemory: true)
}
