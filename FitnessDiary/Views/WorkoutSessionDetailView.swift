import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    let log: WorkoutSessionLog
    @Query private var profiles: [UserProfile]
    
    private var userProfile: UserProfile? { profiles.first }
    private var analytics: WorkoutSummaryMetrics? {
        guard let card = log.card else { return nil }
        return WorkoutSummaryMetrics(card: card, userProfile: userProfile)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: log.date)
    }
    
    private var durationText: String {
        let minutes = Int(log.durationSeconds) / 60
        let seconds = Int(log.durationSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        List {
            heroSection
            
            if let analytics {
                metricsSection(analytics: analytics)
                distributionSection(analytics: analytics)
                exerciseSection(analytics: analytics)
            } else {
                missingAnalyticsSection
            }
            
            if !log.notes.isEmpty {
                Section("Note") {
                    Text(log.notes)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(log.cardName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var heroSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(log.mood.emoji)
                        .font(.largeTitle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.cardName)
                            .font(.headline)
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let rpe = log.rpe {
                        Label("RPE \(rpe)", systemImage: "gauge")
                            .font(.caption)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func metricsSection(analytics: WorkoutSummaryMetrics) -> some View {
        Section("Metriche principali") {
            WorkoutDetailMetricRow(icon: "clock", title: "Durata", value: durationText)
            
            if analytics.hasTonnage {
                WorkoutDetailMetricRow(
                    icon: "dumbbell.fill",
                    title: "Tonnellaggio",
                    value: "\(formatTonnage(analytics.tonnage)) kg"
                )
            }
            
            if analytics.hasCardioDuration {
                WorkoutDetailMetricRow(
                    icon: "figure.run",
                    title: "Durata cardio",
                    value: formatDuration(analytics.cardioDuration)
                )
            }
            
            if analytics.exerciseCount > 0 {
                WorkoutDetailMetricRow(
                    icon: "list.number",
                    title: "Esercizi totali",
                    value: "\(analytics.exerciseCount)"
                )
            }
        }
    }
    
    @ViewBuilder
    private func distributionSection(analytics: WorkoutSummaryMetrics) -> some View {
        if analytics.upperBodyCount > 0 || analytics.lowerBodyCount > 0 {
            Section("Distribuzione per distretto") {
                if analytics.upperBodyCount > 0 {
                    WorkoutDetailMetricRow(
                        icon: WorkoutBodyRegion.upper.icon,
                        title: WorkoutBodyRegion.upper.title,
                        value: "\(analytics.upperBodyCount)"
                    )
                }
                if analytics.lowerBodyCount > 0 {
                    WorkoutDetailMetricRow(
                        icon: WorkoutBodyRegion.lower.icon,
                        title: WorkoutBodyRegion.lower.title,
                        value: "\(analytics.lowerBodyCount)"
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func exerciseSection(analytics: WorkoutSummaryMetrics) -> some View {
        if !analytics.exerciseBreakdown.isEmpty {
            Section("Dettaglio esercizi") {
                ForEach(analytics.exerciseBreakdown) { breakdown in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(breakdown.exerciseName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(breakdown.region.title)
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                        
                        HStack(spacing: 12) {
                            if breakdown.tonnage > 0 {
                                Label("\(formatTonnage(breakdown.tonnage)) kg", systemImage: "scalemass")
                            }
                            if breakdown.totalSets > 0 {
                                Label("\(breakdown.totalSets) serie", systemImage: "number")
                            }
                            if breakdown.totalReps > 0 {
                                Label("\(breakdown.totalReps) rip", systemImage: "repeat")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var missingAnalyticsSection: some View {
        Section {
            ContentUnavailableView(
                "Dati non disponibili",
                systemImage: "questionmark.circle",
                description: Text("La scheda associata è stata eliminata, quindi non è possibile generare il dettaglio degli esercizi.")
            )
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }
    
    private func formatTonnage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 1
        formatter.groupingSeparator = Locale.current.groupingSeparator
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}

private struct WorkoutDetailMetricRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview("Workout detail") {
    WorkoutSessionDetailPreview()
}

private struct WorkoutSessionDetailPreview: View {
    private let container: ModelContainer
    private let log: WorkoutSessionLog
    
    init() {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: WorkoutSessionLog.self, WorkoutCard.self, Exercise.self,
            configurations: configuration
        )
        
        let exercise = Exercise(name: "Panca Piana", category: .training)
        let set = WorkoutSet(
            order: 0,
            setType: .reps,
            reps: 8,
            weight: 80,
            duration: nil,
            notes: nil,
            loadType: .absolute,
            percentageOfMax: nil
        )
        let item = WorkoutExerciseItem(order: 0, exercise: exercise, sets: [set])
        let block = WorkoutBlock(
            order: 0,
            blockType: .simple,
            methodType: nil,
            globalSets: 3,
            globalRestTime: 120,
            notes: nil,
            exerciseItems: [item]
        )
        let card = WorkoutCard(name: "Forza A", blocks: [block])
        let log = WorkoutSessionLog(
            card: card,
            cardName: card.name,
            notes: "Ottime sensazioni",
            mood: .happy,
            rpe: 7,
            durationSeconds: 3600
        )
        
        container.mainContext.insert(exercise)
        container.mainContext.insert(card)
        container.mainContext.insert(log)
        self.log = log
    }
    
    var body: some View {
        NavigationStack {
            WorkoutSessionDetailView(log: log)
        }
        .modelContainer(container)
    }
}
