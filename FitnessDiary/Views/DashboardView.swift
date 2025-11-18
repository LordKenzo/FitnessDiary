import SwiftUI
import SwiftData

struct DashboardView: View {
    private let calendar = Calendar.current
    @Query private var storedSessionLogs: [WorkoutSessionLog]
    @ObservedObject private var localizationManager = LocalizationManager.shared

    init() {}

    private var sessionLogs: [WorkoutSessionLog] {
        storedSessionLogs.sorted { $0.date > $1.date }
    }

    private var focusMuscles: [String] {
        [
            L("muscle.chest"),
            L("muscle.back"),
            L("muscle.legs"),
            L("muscle.core"),
            L("muscle.shoulders")
        ]
    }

    private var quickActions: [QuickAction] {
        [
            QuickAction(title: L("quick.action.start.workout"), icon: "play.circle.fill", tint: .green),
            QuickAction(title: L("quick.action.manual.log"), icon: "square.and.pencil", tint: .orange),
            QuickAction(title: L("quick.action.set.goal"), icon: "target", tint: .purple)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    heroHeader

                    metricGrid

                    trendSection

                    focusSection

                    quickActionsSection

                    placeholderInsights
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L("dashboard.title"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(localized: "dashboard.greeting")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(heroHeadline)
                    .font(.largeTitle.bold())
            }

            if let latest = sessionLogs.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localized: "dashboard.last.session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .center, spacing: 12) {
                        Text(latest.mood.emoji)
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(latest.cardName)
                                .font(.headline)
                            Text(dateFormatter.string(from: latest.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(latest.notes.isEmpty ? L("dashboard.no.notes") : "\"\(latest.notes)\"")
                                .font(.footnote.italic())
                                .lineLimit(2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let rpe = latest.rpe {
                            VStack(spacing: 2) {
                                Text(localized: "workout.rpe")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(rpe)")
                                    .font(.headline)
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                Divider()
            } else {
                Text(localized: "dashboard.empty.sessions")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Divider()
            }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localized: "dashboard.weekly.goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: L("dashboard.sessions.count"), sessionsThisWeek, weeklyGoal))
                        .font(.headline)
                    ProgressView(value: min(weeklyProgress, 1))
                        .tint(.blue)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(localized: "dashboard.streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: L("dashboard.streak.days"), currentStreak))
                        .font(.title2.bold())
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            ForEach(metricCards) { card in
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: card.icon)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(card.value)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text(card.title)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(card.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                .background(card.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("section.weekly.trend"), subtitle: L("section.weekly.trend.subtitle"))
            ActivitySparkline(values: weeklyTrend)
                .frame(height: 120)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("section.focus.muscles"), subtitle: L("section.focus.muscles.subtitle"))
            FlowLayout(tags: focusMuscles)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("section.quick.actions"), subtitle: L("section.quick.actions.subtitle"))
            ForEach(Array(quickActions.enumerated()), id: \.element.id) { index, action in
                Button {
                    // Future integration point
                } label: {
                    HStack {
                        Image(systemName: action.icon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(action.tint)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(.headline)
                            Text(localized: "quick.action.coming.soon")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                if index < quickActions.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var placeholderInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("section.future.insights"), subtitle: L("section.future.insights.subtitle"))
            Text(localized: "section.future.insights.description")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var metricCards: [MetricCard] {
        [
            MetricCard(
                title: L("metrics.sessions"),
                value: "\(sessionsLast30Days.count)",
                subtitle: L("metrics.sessions.subtitle"),
                icon: "calendar.circle"
            ),
            MetricCard(
                title: L("metrics.duration"),
                value: durationFormatter.string(from: totalDurationLast30Days) ?? "0h",
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

    private var sessionsLast30Days: [WorkoutSessionLog] {
        guard let threshold = calendar.date(byAdding: .day, value: -30, to: .now) else { return [] }
        return sessionLogs.filter { $0.date >= threshold }
    }

    private var totalDurationLast30Days: TimeInterval {
        sessionsLast30Days.reduce(0) { $0 + $1.durationSeconds }
    }

    private var averageRPEString: String {
        let recentRPE = sessionsLast30Days.compactMap(\.rpe)
        guard !recentRPE.isEmpty else { return "—" }
        let average = Double(recentRPE.reduce(0, +)) / Double(recentRPE.count)
        return String(format: "%.1f", average)
    }

    private var dominantMood: WorkoutMood? {
        let counts = sessionsLast30Days.reduce(into: [:]) { partialResult, log in
            partialResult[log.mood, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
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
        switch sessionsLast30Days.count {
        case 0:
            return L("dashboard.hero.ready")
        case 1:
            return L("dashboard.hero.sessions.one")
        default:
            return String(format: L("dashboard.hero.sessions.many"), sessionsLast30Days.count)
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

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.subheadline.weight(.medium))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: WorkoutSessionLog.self, inMemory: true)
}
