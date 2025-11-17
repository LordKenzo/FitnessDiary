import SwiftUI

struct WorkoutDebugLogView: View {
    private let blocks: [WorkoutBlock]
    @State private var selectedFormat: WorkoutSheetFormat = .verbose
    private var logEntries: [String] { WorkoutDebugLogBuilder.buildLog(for: blocks, format: selectedFormat) }
    private var logText: String { logEntries.joined(separator: "\n") }

    init(blocks: [WorkoutBlock]) {
        self.blocks = blocks.sorted { $0.order < $1.order }
    }

    init(blockData: [WorkoutBlockData]) {
        let ordered = blockData.sorted { $0.order < $1.order }
        self.blocks = ordered.map { WorkoutBlockHelper.workoutBlockToModel($0) }
    }

    var body: some View {
        List {
            Section {
                Picker("Formato", selection: $selectedFormat) {
                    ForEach(WorkoutSheetFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            if logEntries.isEmpty {
                ContentUnavailableView {
                    Label("Nessun blocco", systemImage: "list.bullet.rectangle")
                } description: {
                    Text("Aggiungi almeno un blocco per generare il log di debug.")
                }
            } else {
                ForEach(Array(logEntries.enumerated()), id: \.offset) { index, entry in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(entry)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Log Allenamento")
        .toolbar {
            if !logEntries.isEmpty {
                ShareLink(item: logText) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    let exercise = Exercise(
        name: "Panca Piana",
        biomechanicalStructure: .multiJoint,
        trainingRole: .fundamental,
        primaryMetabolism: .anaerobic,
        category: .training
    )

    let item = WorkoutExerciseItem(order: 0, exercise: exercise, sets: [], notes: nil, restTime: 120)
    item.sets.append(WorkoutSet(order: 0, setType: .reps, reps: 10))
    item.sets.append(WorkoutSet(order: 1, setType: .reps, reps: 8))

    let block = WorkoutBlock(order: 0, blockType: .simple, globalSets: 2, globalRestTime: 90, exerciseItems: [item])

    return NavigationStack {
        WorkoutDebugLogView(blocks: [block])
    }
}
