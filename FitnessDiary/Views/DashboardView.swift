import SwiftUI

struct DashboardView: View {
    private let metricCards: [MetricCard] = [
        .init(title: "Sessioni", value: "12", subtitle: "Ultimi 30 giorni", icon: "calendar.circle"),
        .init(title: "Esercizi", value: "96", subtitle: "Ultimo mese", icon: "dumbbell"),
        .init(title: "Volume", value: "42k kg", subtitle: "Stimato", icon: "chart.bar.fill"),
        .init(title: "Durata", value: "18 h", subtitle: "Tempo totale", icon: "clock.fill")
    ]

    private let focusMuscles = ["Petto", "Dorso", "Gambe e Glutei", "Core", "Spalle"]
    private let quickActions = [
        QuickAction(title: "Inizia Allenamento", icon: "play.circle.fill", tint: .green),
        QuickAction(title: "Registra Manualmente", icon: "square.and.pencil", tint: .orange),
        QuickAction(title: "Imposta Obiettivo", icon: "target", tint: .purple)
    ]
    private let weeklyTrend: [CGFloat] = [4, 3, 5, 2, 4, 5, 6]

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
            .navigationTitle("Dashboard")
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bentornato!")
                .font(.largeTitle.bold())
            Text("Qui troverai un riepilogo rapido dei tuoi allenamenti e suggerimenti personalizzati.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Divider()
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Prossimo obiettivo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("4 sessioni questa settimana")
                        .font(.headline)
                    ProgressView(value: 0.5)
                        .tint(.blue)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("3 giorni")
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
            sectionHeader(title: "Trend settimanale", subtitle: "Sessioni completate")
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
            sectionHeader(title: "Muscoli in focus", subtitle: "Basato sugli ultimi allenamenti")
            FlowLayout(tags: focusMuscles)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Azioni rapide", subtitle: "Tutto a portata di tap")
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
                            Text("Disponibile a breve")
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
            sectionHeader(title: "Insight futuri", subtitle: "Presto vedrai dati dettagliati")
            Text("In questa sezione potrai trovare analisi approfondite: distribuzione dei muscoli allenati, progressi di RPE e durata media per sessione.")
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
}
