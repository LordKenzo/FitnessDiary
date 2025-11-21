import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutSessionLog.date, order: .reverse)])
    private var logs: [WorkoutSessionLog]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        List {
            if logs.isEmpty {
                ContentUnavailableView {
                    Label("Nessun allenamento", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Completa un allenamento e salvalo per creare lo storico.")
                }
            } else {
                ForEach(logs) { log in
                    NavigationLink {
                        WorkoutSessionDetailView(log: log)
                    } label: {
                        WorkoutHistoryRow(log: log, formatter: dateFormatter)
                    }
                }
                .onDelete(perform: deleteLogs)
            }
        }
        .glassScrollBackground()
        .navigationTitle(L("workout.history.title"))
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }
    }
}

private struct WorkoutHistoryRow: View {
    let log: WorkoutSessionLog
    let formatter: DateFormatter

    private var durationText: String {
        let minutes = Int(log.durationSeconds) / 60
        let seconds = Int(log.durationSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(log.mood.emoji)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.cardName)
                        .font(.headline)
                    Text(formatter.string(from: log.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Label(durationText, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let rpe = log.rpe {
                        Label("RPE \(rpe)", systemImage: "gauge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(for: WorkoutSessionLog.self, inMemory: true)
}
