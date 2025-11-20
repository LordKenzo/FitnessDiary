//
//  MicrocycleDetailView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

/// Dettaglio microciclo (settimana) con lista giorni e schede associate
struct MicrocycleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let microcycle: Microcycle

    @State private var selectedDay: TrainingDay?
    @State private var showingEditParameters = false
    @State private var showCalendarLayout = false
    @State private var sourceDayForDuplication: TrainingDay?
    @State private var showingDuplicateSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Settimana
                weekHeaderSection

                // Progress completamento
                completionProgressSection

                // Statistiche volume settimanale
                weeklyVolumeSection

                // Lista giorni
                daysListSection
            }
            .padding()
        }
        .navigationTitle("Settimana \(microcycle.order)")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditParameters = true
                    } label: {
                        Label("Modifica Parametri", systemImage: "slider.horizontal.3")
                    }

                    Divider()

                    Picker("Vista", selection: $showCalendarLayout) {
                        Label("Lista", systemImage: "list.bullet")
                            .tag(false)
                        Label("Calendario", systemImage: "calendar")
                            .tag(true)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Chiudi") {
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedDay) { day in
            WorkoutCardPickerView(trainingDay: day) { card in
                assignWorkoutToDay(card: card, day: day)
            }
        }
        .sheet(isPresented: $showingEditParameters) {
            EditMicrocycleView(microcycle: microcycle)
        }
        .sheet(isPresented: $showingDuplicateSheet) {
            if let sourceDay = sourceDayForDuplication {
                DuplicateWorkoutCardView(
                    sourceDay: sourceDay,
                    microcycle: microcycle
                )
            }
        }
    }

    // MARK: - Actions

    private func assignWorkoutToDay(card: WorkoutCard, day: TrainingDay) {
        day.workoutCard = card
        try? modelContext.save()
    }

    // MARK: - Sections

    private var weekHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Livello carico
            HStack {
                Label(microcycle.loadLevel.rawValue, systemImage: microcycle.loadLevel.icon)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(loadLevelColor)

                Spacer()

                Text("Sett. \(microcycle.weekNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Text(microcycle.loadLevel.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Fattori modulazione
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intensità")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(loadLevelColor)
                        Text("\(Int(microcycle.intensityFactor * 100))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(loadLevelColor)
                        Text("\(Int(microcycle.volumeFactor * 100))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Progressione")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("+\(String(format: "%.1f", microcycle.loadProgressionPercentage * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }

            // Date
            HStack {
                Label(formatDate(microcycle.startDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label(formatDate(microcycle.endDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notes = microcycle.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(loadLevelColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var completionProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Completamento")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(microcycle.completedDays)/\(microcycle.totalPlannedDays) allenamenti")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: microcycle.completionPercentage / 100.0)
                .tint(loadLevelColor)
        }
    }

    private var weeklyVolumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Volume Settimanale")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if !microcycle.hasAllWorkoutsAssigned {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("\(microcycle.assignedWorkoutCount)/\(microcycle.totalPlannedDays) schede")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            if microcycle.hasAnyWorkoutAssigned {
                // Statistiche aggregate
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Serie Totali")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("\(microcycle.totalWeeklySets)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Esercizi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text("\(microcycle.totalWeeklyExercises)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Durata Tot.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("\(microcycle.totalWeeklyDurationMinutes)m")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }

                Divider()

                // Visualizzazione barre volume giornaliero
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distribuzione Volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VolumeBarChartView(trainingDays: microcycle.sortedTrainingDays)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nessuna scheda assegnata")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Associa schede ai giorni di allenamento per vedere le statistiche")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var daysListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Giorni della Settimana")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    showCalendarLayout.toggle()
                } label: {
                    Image(systemName: showCalendarLayout ? "list.bullet" : "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            if microcycle.trainingDays.isEmpty {
                emptyDaysView
            } else {
                if showCalendarLayout {
                    CalendarGridView(trainingDays: microcycle.sortedTrainingDays) { day in
                        selectedDay = day
                    }
                } else {
                    ForEach(microcycle.sortedTrainingDays) { day in
                        TrainingDayCardView(day: day, onSelectWorkout: {
                            selectedDay = day
                        }, onDuplicate: {
                            sourceDayForDuplication = day
                            showingDuplicateSheet = true
                        })
                    }
                }
            }
        }
    }

    private var emptyDaysView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Nessun giorno generato")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Helpers

    private var loadLevelColor: Color {
        microcycle.loadLevel.swiftUIColor
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Training Day Card View

/// Card per singolo giorno di allenamento
struct TrainingDayCardView: View {
    @Environment(\.modelContext) private var modelContext
    let day: TrainingDay
    let onSelectWorkout: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header giorno
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.dayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(formatDate(day.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if day.completed {
                    Button {
                        markIncomplete()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Completato")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else if day.isRestDay {
                    Label("Riposo", systemImage: "moon.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                } else if day.isPast && !day.completed {
                    Button {
                        markComplete()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Saltato")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                    }
                } else if !day.isRestDay {
                    Button {
                        markComplete()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.blue)
                            Text("Completa")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

            // Scheda associata
            if !day.isRestDay {
                if let workout = day.workoutCard {
                    WorkoutCardPreview(workout: workout, day: day)
                } else {
                    Button {
                        onSelectWorkout()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)

                            Text("Associa scheda")
                                .font(.subheadline)
                                .foregroundStyle(.blue)

                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

            // Note
            if let notes = day.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(day.isToday ? Color.accentColor.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(day.isToday ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contextMenu {
            if !day.isRestDay {
                if let workout = day.workoutCard {
                    Button {
                        onDuplicate()
                    } label: {
                        Label("Duplica su altri giorni", systemImage: "doc.on.doc")
                    }

                    Button(role: .destructive) {
                        day.workoutCard = nil
                        try? modelContext.save()
                    } label: {
                        Label("Rimuovi scheda", systemImage: "trash")
                    }
                }

                Divider()

                if day.completed {
                    Button {
                        markIncomplete()
                    } label: {
                        Label("Segna come non completato", systemImage: "xmark.circle")
                    }
                } else {
                    Button {
                        markComplete()
                    } label: {
                        Label("Segna come completato", systemImage: "checkmark.circle")
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }

    private func markComplete() {
        day.markCompleted()
        try? modelContext.save()
    }

    private func markIncomplete() {
        day.markIncomplete()
        try? modelContext.save()
    }
}

// MARK: - Calendar Grid View

/// Vista a griglia calendario dei giorni di allenamento
struct CalendarGridView: View {
    @Environment(\.modelContext) private var modelContext
    let trainingDays: [TrainingDay]
    let onSelectWorkout: (TrainingDay) -> Void

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(trainingDays) { day in
                CalendarDayCard(day: day, onSelectWorkout: {
                    onSelectWorkout(day)
                })
            }
        }
    }
}

/// Card compatta per vista calendario
struct CalendarDayCard: View {
    @Environment(\.modelContext) private var modelContext
    let day: TrainingDay
    let onSelectWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.shortDayName.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(formatDayNumber(day.date))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if day.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                } else if day.isRestDay {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.secondary)
                } else if day.isPast {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Divider()

            // Content
            if day.isRestDay {
                HStack {
                    Image(systemName: "moon.zzz")
                        .foregroundStyle(.secondary)
                    Text("Riposo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let workout = day.workoutCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label("\(workout.totalSets)", systemImage: "chart.bar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Label("\(workout.totalExercises)", systemImage: "figure.strengthtraining.traditional")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    onSelectWorkout()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.blue)
                        Text("Aggiungi")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(day.isToday ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(day.isToday ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contextMenu {
            if !day.isRestDay {
                if day.workoutCard != nil {
                    Button(role: .destructive) {
                        day.workoutCard = nil
                        try? modelContext.save()
                    } label: {
                        Label("Rimuovi scheda", systemImage: "trash")
                    }
                }

                Divider()

                if day.completed {
                    Button {
                        day.markIncomplete()
                        try? modelContext.save()
                    } label: {
                        Label("Segna come non completato", systemImage: "xmark.circle")
                    }
                } else {
                    Button {
                        day.markCompleted()
                        try? modelContext.save()
                    } label: {
                        Label("Segna come completato", systemImage: "checkmark.circle")
                    }
                }
            }
        }
    }

    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
}

// MARK: - Volume Bar Chart View

/// Visualizzazione a barre del volume giornaliero
struct VolumeBarChartView: View {
    let trainingDays: [TrainingDay]

    private var maxSets: Int {
        trainingDays
            .filter { !$0.isRestDay }
            .compactMap { $0.workoutCard?.totalSets }
            .max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(trainingDays) { day in
                VStack(spacing: 4) {
                    // Barra
                    if day.isRestDay {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 32, height: 4)
                            .cornerRadius(2)
                    } else if let workout = day.workoutCard {
                        let sets = workout.totalSets
                        let height = max(16.0, CGFloat(sets) / CGFloat(maxSets) * 80.0)

                        Rectangle()
                            .fill(day.completed ? Color.green : Color.blue)
                            .frame(width: 32, height: height)
                            .cornerRadius(4)
                            .overlay(
                                Text("\(sets)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            )
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 32, height: 16)
                            .cornerRadius(4)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            )
                    }

                    // Label giorno
                    Text(day.shortDayName.prefix(3).uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(day.isToday ? .blue : .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Workout Card Preview

/// Preview compatta della scheda associata
struct WorkoutCardPreview: View {
    let workout: WorkoutCard
    let day: TrainingDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let splitType = workout.splitType {
                        HStack(spacing: 4) {
                            Image(systemName: splitType.icon)
                                .font(.caption2)

                            Text(splitType.rawValue)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()


            }

            // Statistiche scheda
            HStack(spacing: 16) {
                Label("\(workout.totalExercises) esercizi", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Duplicate Workout Card View

/// Vista per duplicare una scheda su più giorni
struct DuplicateWorkoutCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let sourceDay: TrainingDay
    let microcycle: Microcycle

    @State private var selectedDays: Set<UUID> = []

    private var availableDays: [TrainingDay] {
        microcycle.sortedTrainingDays.filter { day in
            !day.isRestDay && day.id != sourceDay.id
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header info
                if let workout = sourceDay.workoutCard {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .font(.title2)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Duplica Scheda")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text(workout.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Seleziona i giorni su cui copiare la scheda")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    .background(Color.blue.opacity(0.1))
                }

                // Lista giorni
                List {
                    Section {
                        ForEach(availableDays) { day in
                            Button {
                                if selectedDays.contains(day.id) {
                                    selectedDays.remove(day.id)
                                } else {
                                    selectedDays.insert(day.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    // Checkbox
                                    ZStack {
                                        Circle()
                                            .stroke(selectedDays.contains(day.id) ? Color.blue : Color.gray, lineWidth: 2)
                                            .frame(width: 24, height: 24)

                                        if selectedDays.contains(day.id) {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.blue)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(day.dayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)

                                            if day.completed {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.green)
                                            }
                                        }

                                        Text(formatDate(day.date))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if let existingWorkout = day.workoutCard {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Scheda attuale")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text(existingWorkout.name)
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Giorni Disponibili (\(availableDays.count))")
                    } footer: {
                        if !selectedDays.isEmpty {
                            Text("La scheda verrà copiata su \(selectedDays.count) giorni. Le schede esistenti verranno sostituite.")
                        }
                    }
                }
                .glassScrollBackground()
            }
            .navigationTitle("Duplica Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Duplica") {
                        duplicateWorkout()
                    }
                    .disabled(selectedDays.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .appScreenBackground()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }

    private func duplicateWorkout() {
        guard let workout = sourceDay.workoutCard else { return }

        for dayID in selectedDays {
            if let day = microcycle.trainingDays.first(where: { $0.id == dayID }) {
                day.workoutCard = workout
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Microcycle.self, configurations: config) else {
        return Text("Failed to create preview container")
    }

    let microcycle = Microcycle(
        order: 1,
        weekNumber: 1,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!,
        loadLevel: .high
    )

    container.mainContext.insert(microcycle)

    return NavigationStack {
        MicrocycleDetailView(microcycle: microcycle)
    }
    .modelContainer(container)
}
