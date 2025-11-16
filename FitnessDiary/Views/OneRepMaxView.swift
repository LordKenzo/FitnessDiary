import SwiftUI
import SwiftData

struct OneRepMaxView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var records: [OneRepMax]

    @State private var editingValues: [Big5Exercise: String] = [:]

    var body: some View {
        List {
            Section {
                ForEach(Big5Exercise.allCases) { exercise in
                    HStack {
                        Image(systemName: exercise.icon)
                            .foregroundStyle(.blue)
                            .frame(width: 30)

                        Text(exercise.rawValue)
                            .font(.subheadline)

                        Spacer()

                        TextField("Kg", text: binding(for: exercise))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)

                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("1RM Stimati")
            } footer: {
                Text("Inserisci i tuoi massimali (1 Rep Max) per i 5 esercizi fondamentali. Questi valori saranno usati per calcolare le percentuali di carico.")
            }
        }
        .navigationTitle("Massimali (1RM)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadEditingValues()
        }
        .onDisappear {
            saveChanges()
        }
    }

    private func binding(for exercise: Big5Exercise) -> Binding<String> {
        Binding(
            get: {
                editingValues[exercise] ?? ""
            },
            set: { newValue in
                editingValues[exercise] = newValue
            }
        )
    }

    private func loadEditingValues() {
        for exercise in Big5Exercise.allCases {
            if let record = records.first(where: { $0.exercise == exercise }) {
                editingValues[exercise] = String(format: "%.1f", record.weight)
            }
        }
    }

    private func saveChanges() {
        for exercise in Big5Exercise.allCases {
            if let text = editingValues[exercise], !text.isEmpty,
               let weight = Double(text.replacingOccurrences(of: ",", with: ".")) {
                // Update or create record
                if let existingRecord = records.first(where: { $0.exercise == exercise }) {
                    existingRecord.weight = weight
                    existingRecord.recordedDate = Date()
                } else {
                    let newRecord = OneRepMax(exercise: exercise, weight: weight)
                    records.append(newRecord)
                    modelContext.insert(newRecord)
                }
            } else {
                // Remove record if text is empty
                if let existingRecord = records.first(where: { $0.exercise == exercise }) {
                    records.removeAll(where: { $0.id == existingRecord.id })
                    modelContext.delete(existingRecord)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OneRepMaxView(records: .constant([]))
    }
    .modelContainer(for: [OneRepMax.self])
}
