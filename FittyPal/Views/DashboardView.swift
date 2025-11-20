import SwiftUI
import SwiftData

struct DashboardView: View {
    private let calendar = Calendar.current
    @Query private var storedSessionLogs: [WorkoutSessionLog]
    @Query private var muscles: [Muscle]
    @Query private var equipment: [Equipment]
    @AppStorage("dashboardWorkoutsCount") private var dashboardWorkoutsCount = 14
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddExercise = false
    @State private var showThemeSelection = false
    @State private var workoutToRepeat: WorkoutCard?

    init() {}

    private var sessionLogs: [WorkoutSessionLog] {
        storedSessionLogs.sorted { $0.date > $1.date }
    }

    private var recentSessions: [WorkoutSessionLog] {
        Array(sessionLogs.prefix(dashboardWorkoutsCount))
    }

    private var focusMuscles: [String] {
        var muscleFrequency: [String: Int] = [:]

        for session in recentSessions {
            guard let card = session.card else { continue }
            for block in card.blocks {
                for item in block.exerciseItems {
                    guard let exercise = item.exercise else { continue }
                    for muscle in exercise.primaryMuscles {
                        muscleFrequency[muscle.name, default: 0] += 2
                    }
                    for muscle in exercise.secondaryMuscles {
                        muscleFrequency[muscle.name, default: 0] += 1
                    }
                }
            }
        }

        return muscleFrequency
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }

    private var quickActions: [QuickAction] {
        [
            QuickAction(title: L("quick.action.repeat.workout"), icon: "arrow.clockwise.circle.fill", tint: .blue),
            QuickAction(title: L("quick.action.create.exercise"), icon: "plus.circle.fill", tint: .green),
            QuickAction(title: L("quick.action.set.theme"), icon: "paintbrush.fill", tint: .purple)
        ]
    }

    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localizationManager.currentLanguage.rawValue)
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        NavigationStack {
            AppBackgroundView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        heroHeader
                        metricGrid
                        trendSection
                        focusSection
                        quickActionsSection
                        insightsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .background(Color.clear)
                .navigationTitle(L("dashboard.title"))
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
        .onAppear {
            // Request location for weather
            if !locationManager.isAuthorized {
                locationManager.requestPermission()
            } else {
                locationManager.requestLocation()
            }
        }
    }




    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localized: "dashboard.greeting")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(heroHeadline)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            if let latest = sessionLogs.first {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized: "dashboard.last.session")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    
                    HStack(alignment: .center, spacing: 14) {
                        Text(latest.mood.emoji)
                            .font(.system(size: 44))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(latest.cardName)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.85))
                            
                            Text(dateFormatter.string(from: latest.date))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.85))
                            
                            Text(latest.notes.isEmpty ? L("dashboard.no.notes") : "\"\(latest.notes)\"")
                                .font(.footnote.italic())
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        if let rpe = latest.rpe {
                            VStack(spacing: 4) {
                                Text(localized: "workout.rpe")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.85))
                                
                                Text("\(rpe)")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .transition(.opacity)
            } else {
                Text(localized: "dashboard.empty.sessions")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            Divider()
                .overlay(colorScheme == .dark ? Color.white.opacity(0.2) : Color.primary.opacity(0.2))
            
            HStack(alignment: .bottom, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localized: "dashboard.weekly.goal")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    
                    Text(String(format: L("dashboard.sessions.count"), sessionsThisWeek, weeklyGoal))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    
                    ProgressView(value: min(weeklyProgress, 1))
                        .tint(colorScheme == .dark ? .white : .primary)
                        .scaleEffect(x: 1, y: 1.1, anchor: .center)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(localized: "dashboard.streak")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    
                    Text(String(format: L("dashboard.streak.days"), currentStreak))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding(24)
        .background(
            AppTheme.heroGradient(for: colorScheme)
                .opacity(colorScheme == .dark ? 1 : 0.95)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.primary.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: AppTheme.shadow(for: colorScheme), radius: 30, y: 18)
    }


    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            ForEach(metricCards) { card in
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: card.icon)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(card.value)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(card.title)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                    Text(card.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160, alignment: .topLeading) // ⬅️ minHeight e maxHeight uguali
                .background(card.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: card.shadow, radius: 18, y: 12)
            }
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: L("section.weekly.trend"), subtitle: L("section.weekly.trend.subtitle"))
            ActivitySparkline(values: weeklyTrend)
                .frame(height: 120)
        }
        .dashboardCardStyle()
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: L("section.focus.muscles"), subtitle: L("section.focus.muscles.subtitle"))
            FlowLayout(tags: focusMuscles)
        }
        .dashboardCardStyle()
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(title: L("section.quick.actions"), subtitle: L("section.quick.actions.subtitle"))
            ForEach(Array(quickActions.enumerated()), id: \.element.id) { index, action in
                Group {
                    if index == 0 {
                        // Ripeti ultimo allenamento
                        Button {
                            if let lastCard = sessionLogs.first?.card {
                                workoutToRepeat = lastCard
                            }
                        } label: {
                            quickActionRow(action: action, index: index)
                        }
                        .disabled(sessionLogs.first?.card == nil)
                        .opacity(sessionLogs.first?.card == nil ? 0.5 : 1)
                    } else if index == 1 {
                        // Crea esercizio
                        Button {
                            showAddExercise = true
                        } label: {
                            quickActionRow(action: action, index: index)
                        }
                    } else {
                        // Imposta tema
                        NavigationLink(destination: ThemeSelectionView()) {
                            quickActionRow(action: action, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if index < quickActions.count - 1 {
                    Divider()
                        .overlay(AppTheme.stroke(for: colorScheme))
                }
            }
        }
        .dashboardCardStyle()
        .sheet(isPresented: $showAddExercise) {
            NavigationStack {
                AddExerciseView(muscles: muscles, equipment: equipment)
            }
        }
        .sheet(item: $workoutToRepeat) { card in
            NavigationStack {
                WorkoutCardDetailSheet(card: card)
            }
        }
    }

    private func quickActionRow(action: QuickAction, index: Int) -> some View {
        HStack(spacing: 14) {
            LinearGradient(colors: [action.tint.opacity(0.9), action.tint.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask {
                    Image(systemName: action.icon)
                        .font(.system(size: 24, weight: .bold))
                }
                .frame(width: 52, height: 52)
                .background(action.tint.opacity(colorScheme == .dark ? 0.25 : 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.headline)
                if index == 0 && sessionLogs.first?.card == nil {
                    Text(localized: "quick.action.no.workouts")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))
        }
        .padding(.vertical, 10)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(title: L("section.insights"), subtitle: L("section.insights.subtitle"))

            VStack(spacing: 16) {
                insightRow(
                    icon: "waveform.path.ecg",
                    title: L("insight.avg.rpe"),
                    value: averageRPEString,
                    tint: .orange
                )

                Divider()
                    .overlay(AppTheme.stroke(for: colorScheme))

                insightRow(
                    icon: "scalemass.fill",
                    title: L("insight.tonnage"),
                    value: String(format: "%.0f kg", totalTonnage),
                    tint: .blue
                )

                Divider()
                    .overlay(AppTheme.stroke(for: colorScheme))

                weatherInsightRow

                Divider()
                    .overlay(AppTheme.stroke(for: colorScheme))

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        LinearGradient(
                            colors: [Color.purple.opacity(0.9), Color.pink.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 22, weight: .bold))
                        }
                        .frame(width: 40, height: 40)

                        Text(L("insight.motivation"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                    }

                    Text(motivationalQuote)
                        .font(.callout.italic())
                        .foregroundStyle(.primary)
                        .padding(.leading, 52)
                }
            }
        }
        .dashboardCardStyle()
    }

    private func insightRow(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            LinearGradient(
                colors: [tint.opacity(0.9), tint.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.subtleText(for: colorScheme))

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }

    private var weatherInsightRow: some View {
        HStack(spacing: 12) {
            // Icon/Emoji
            ZStack {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.9), Color.cyan.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 40, height: 40)

                Text(weatherService.getWeatherEmoji())
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("insight.weather"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.subtleText(for: colorScheme))

                if weatherService.isLoading {
                    Text(L("common.loading"))
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                } else if let _ = weatherService.currentWeather {
                    HStack(spacing: 4) {
                        Text(weatherService.getTemperatureString())
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        Text(weatherService.getWorkoutSuggestion().emoji)
                            .font(.title3)
                    }
                } else if !locationManager.isAuthorized {
                    Text(L("insight.weather.location.denied"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text(L("insight.weather.placeholder"))
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Workout suggestion chip
            if let _ = weatherService.currentWeather, !weatherService.isLoading {
                let suggestion = weatherService.getWorkoutSuggestion()
                VStack(spacing: 2) {
                    Text(suggestion.emoji)
                        .font(.title2)
                    Text(suggestionShortText(suggestion))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(suggestionColor(suggestion).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func suggestionShortText(_ suggestion: WorkoutSuggestion) -> String {
        switch suggestion {
        case .outdoor: return L("workout.suggestion.outdoor.short")
        case .indoor: return L("workout.suggestion.indoor.short")
        case .caution: return L("workout.suggestion.caution.short")
        }
    }

    private func suggestionColor(_ suggestion: WorkoutSuggestion) -> Color {
        switch suggestion {
        case .outdoor: return .green
        case .indoor: return .blue
        case .caution: return .orange
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))
        }
    }

    private var metricCards: [MetricCard] {
        [
            MetricCard(
                title: L("metrics.sessions"),
                value: "\(recentSessions.count)",
                subtitle: String(format: L("metrics.sessions.recent"), dashboardWorkoutsCount),
                icon: "calendar.circle"
            ),
            MetricCard(
                title: L("metrics.duration"),
                value: durationFormatter.string(from: totalDurationRecent) ?? "0h",
                subtitle: L("metrics.duration.subtitle"),
                icon: "clock.fill"
            ),
            MetricCard(
                title: L("metrics.avg.rpe"),
                value: averageRPEString,
                subtitle: L("metrics.avg.rpe.subtitle"),
                icon: "waveform.path.ecg"
            ),
            MetricCard(
                title: L("metrics.mood"),
                value: dominantMood?.emoji ?? "🙂",
                subtitle: dominantMood?.title ?? L("metrics.mood.subtitle"),
                icon: "face.smiling"
            )
        ]
    }

    private var totalDurationRecent: TimeInterval {
        recentSessions.reduce(0) { $0 + $1.durationSeconds }
    }

    private var averageRPEString: String {
        let recentRPE = recentSessions.compactMap(\.rpe)
        guard !recentRPE.isEmpty else { return "—" }
        let average = Double(recentRPE.reduce(0, +)) / Double(recentRPE.count)
        return String(format: "%.1f", average)
    }

    private var dominantMood: WorkoutMood? {
        let counts = recentSessions.reduce(into: [:]) { partialResult, log in
            partialResult[log.mood, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private var totalTonnage: Double {
        var tonnage: Double = 0
        for session in recentSessions {
            guard let card = session.card else { continue }
            for block in card.blocks {
                for item in block.exerciseItems {
                    for set in item.sets {
                        if let weight = set.weight, let reps = set.reps {
                            tonnage += weight * Double(reps)
                        }
                    }
                }
            }
        }
        return tonnage
    }

    private var motivationalQuote: String {
        let quotes = [
            L("quote.progress"),
            L("quote.consistency"),
            L("quote.strength"),
            L("quote.discipline"),
            L("quote.mindset"),
            L("quote.journey"),
            L("quote.commitment"),
            L("quote.perseverance")
        ]
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 1
        return quotes[dayOfYear % quotes.count]
    }

    private var weeklyTrend: [CGFloat] {
        var trend: [CGFloat] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) else { continue }
            let count = sessionLogs.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            trend.append(CGFloat(count))
        }
        return trend
    }

    private var sessionsThisWeek: Int {
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)) else {
            return 0
        }
        return sessionLogs.filter { $0.date >= startOfWeek }.count
    }

    private var weeklyGoal: Int { 4 }

    private var weeklyProgress: Double {
        guard weeklyGoal > 0 else { return 0 }
        return Double(sessionsThisWeek) / Double(weeklyGoal)
    }

    private var heroHeadline: String {
        switch recentSessions.count {
        case 0:
            return L("dashboard.hero.ready")
        case 1:
            return L("dashboard.hero.sessions.one")
        default:
            return String(format: L("dashboard.hero.sessions.many"), recentSessions.count)
        }
    }

    private var currentStreak: Int {
        guard !sessionLogs.isEmpty else { return 0 }
        var streak = 0
        var currentDay = calendar.startOfDay(for: .now)
        var sessionDays: Set<Date> = []
        sessionLogs.forEach { log in
            sessionDays.insert(calendar.startOfDay(for: log.date))
        }

        if !sessionDays.contains(currentDay) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDay), sessionDays.contains(yesterday) else {
                return 0
            }
            currentDay = yesterday
        }

        while sessionDays.contains(currentDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
            currentDay = previousDay
        }
        return streak
    }
}

private struct MetricCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var gradient: LinearGradient {
        let colors: [Color]
        switch icon {
        case "calendar.circle":
            colors = [.blue, .mint]
        case "dumbbell":
            colors = [.orange, .pink]
        case "chart.bar.fill":
            colors = [.purple, .indigo]
        default:
            colors = [.green, .teal]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var shadow: Color {
        switch icon {
        case "calendar.circle":
            return .blue.opacity(0.45)
        case "clock.fill":
            return .green.opacity(0.45)
        case "waveform.path.ecg":
            return .orange.opacity(0.45)
        case "face.smiling":
            return .yellow.opacity(0.45)
        default:
            return .gray.opacity(0.45)
        }
    }
}

private struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
}

private struct ActivitySparkline: View {
    let values: [CGFloat]

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            let maxValue = values.max() ?? 1
            let stepX = width / CGFloat(max(values.count - 1, 1))

            Path { path in
                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalized = value / maxValue
                    let y = height - (normalized * height)
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: width, y: height))
            }
            .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .padding(.vertical)
    }
}

private struct FlowLayout: View {
    let tags: [String]
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.subheadline.weight(.medium))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppTheme.chipBackground(for: colorScheme))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Workout Card Detail Sheet
private struct WorkoutCardDetailSheet: View {
    let card: WorkoutCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.name)
                        .font(.title.bold())

                    if let description = card.cardDescription {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                // Stats
                HStack(spacing: 16) {
                    StatBadge(icon: "list.bullet", value: "\(card.totalExercises)", label: "Esercizi")
                    StatBadge(icon: "repeat", value: "\(card.totalSets)", label: "Serie")
                    StatBadge(icon: "clock", value: "\(card.estimatedDurationMinutes) min", label: "Durata")
                }

                Divider()

                // Blocks preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Blocchi Allenamento")
                        .font(.headline)

                    ForEach(Array(card.blocks.enumerated()), id: \.element.id) { index, block in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "number.square.fill")
                                    .foregroundStyle(.blue)
                                Text(block.blockType.rawValue)
                                    .font(.subheadline.weight(.medium))

                                if let method = block.methodType {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text(method.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text("\(block.exerciseItems.count) esercizi • \(block.globalSets) serie")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.chipBackground(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Divider()

                // Call to action
                VStack(spacing: 12) {
                    Text("Per eseguire questo allenamento, vai alla tab Allenamento")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button {
                        dismiss()
                    } label: {
                        Label("Chiudi", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .navigationTitle("Dettagli Allenamento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.chipBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: WorkoutSessionLog.self, inMemory: true)
}
