//
//  EditCustomMethodView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

struct EditCustomMethodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Editing existing method or creating new one
    let method: CustomTrainingMethod?

    @State private var name: String = ""
    @State private var numberOfReps: Int = 6
    @State private var repConfigurations: [RepConfigurationState] = []

    init(method: CustomTrainingMethod? = nil) {
        self.method = method
    }

    var body: some View {
        Form {
            Section {
                TextField("Nome Metodo", text: $name)
                    .font(.body)
            } header: {
                Text("Informazioni Base")
            } footer: {
                Text("Dai un nome descrittivo al tuo metodo di allenamento.")
            }

            Section {
                Stepper("Ripetizioni: \(numberOfReps)", value: $numberOfReps, in: 1...20)
                    .onChange(of: numberOfReps) { oldValue, newValue in
                        updateRepConfigurations(oldCount: oldValue, newCount: newValue)
                    }
            } header: {
                Text("Numero di Ripetizioni")
            } footer: {
                Text("Seleziona quante ripetizioni avrà ogni serie con questo metodo.")
            }

            if !repConfigurations.isEmpty {
                Section {
                    ForEach($repConfigurations) { $config in
                        RepConfigurationRow(config: $config)
                    }
                } header: {
                    Text("Configurazione Ripetizioni")
                } footer: {
                    Text("Imposta la percentuale di carico (relativa alla prima rep) e la pausa dopo ogni ripetizione.")
                }
            }
        }
        .navigationTitle(method == nil ? "Nuovo Metodo" : "Modifica Metodo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annulla") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Salva") {
                    saveMethod()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            loadMethodData()
        }
    }

    private func loadMethodData() {
        if let method = method {
            name = method.name
            numberOfReps = method.totalReps
            repConfigurations = method.repConfigurations
                .sorted(by: { $0.repOrder < $1.repOrder })
                .map { RepConfigurationState(from: $0) }
        } else {
            // Initialize with default configurations
            repConfigurations = (1...numberOfReps).map { order in
                RepConfigurationState(
                    id: UUID(),
                    repOrder: order,
                    loadPercentage: 0.0,
                    restAfterRep: 0.0
                )
            }
        }
    }

    private func updateRepConfigurations(oldCount: Int, newCount: Int) {
        if newCount > oldCount {
            // Add new configurations
            let newConfigs = ((oldCount + 1)...newCount).map { order in
                RepConfigurationState(
                    id: UUID(),
                    repOrder: order,
                    loadPercentage: 0.0,
                    restAfterRep: 0.0
                )
            }
            repConfigurations.append(contentsOf: newConfigs)
        } else if newCount < oldCount {
            // Remove configurations from the end
            repConfigurations = Array(repConfigurations.prefix(newCount))
        }
    }

    private func saveMethod() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let existingMethod = method {
            // Update existing method
            existingMethod.name = trimmedName
            existingMethod.lastModifiedAt = Date()

            // Remove old configurations
            existingMethod.repConfigurations.forEach { config in
                modelContext.delete(config)
            }

            // Create new configurations
            let newConfigs = repConfigurations.map { state in
                CustomRepConfiguration(
                    id: UUID(),
                    repOrder: state.repOrder,
                    loadPercentage: state.loadPercentage,
                    restAfterRep: state.restAfterRep
                )
            }
            existingMethod.repConfigurations = newConfigs
        } else {
            // Create new method
            let newMethod = CustomTrainingMethod(
                name: trimmedName,
                repConfigurations: repConfigurations.map { state in
                    CustomRepConfiguration(
                        id: UUID(),
                        repOrder: state.repOrder,
                        loadPercentage: state.loadPercentage,
                        restAfterRep: state.restAfterRep
                    )
                }
            )
            modelContext.insert(newMethod)
        }

        dismiss()
    }
}

// State wrapper for rep configuration to use in @State
struct RepConfigurationState: Identifiable {
    let id: UUID
    var repOrder: Int
    var loadPercentage: Double
    var restAfterRep: TimeInterval

    init(id: UUID = UUID(), repOrder: Int, loadPercentage: Double, restAfterRep: TimeInterval) {
        self.id = id
        self.repOrder = repOrder
        self.loadPercentage = loadPercentage
        self.restAfterRep = restAfterRep
    }

    init(from config: CustomRepConfiguration) {
        self.id = config.id
        self.repOrder = config.repOrder
        self.loadPercentage = config.loadPercentage
        self.restAfterRep = config.restAfterRep
    }

    var formattedLoadPercentage: String {
        if loadPercentage > 0 {
            return "+\(Int(loadPercentage))%"
        } else if loadPercentage < 0 {
            return "\(Int(loadPercentage))%"
        } else {
            return "0%"
        }
    }

    var formattedRestTime: String {
        let seconds = Int(restAfterRep)
        if seconds == 0 {
            return "Nessuna pausa"
        } else if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
}

struct RepConfigurationRow: View {
    @Binding var config: RepConfigurationState

    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 16) {
                // Load percentage slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Carico")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(config.formattedLoadPercentage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Slider(value: $config.loadPercentage, in: -50...100, step: 5)
                        .tint(.accentColor)
                }
                .padding(.vertical, 4)

                // Rest time slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pausa")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(config.formattedRestTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Slider(value: $config.restAfterRep, in: 0...240, step: 5)
                        .tint(.accentColor)
                }
                .padding(.vertical, 4)
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text("Rep \(config.repOrder)")
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                if !isExpanded {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(config.formattedLoadPercentage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(config.formattedRestTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview("New Method") {
    NavigationStack {
        EditCustomMethodView()
            .modelContainer(for: [CustomTrainingMethod.self], inMemory: true)
    }
}

#Preview("Edit Method") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CustomTrainingMethod.self, configurations: config)

    let method = CustomTrainingMethod(
        name: "Metodo Test",
        repConfigurations: [
            CustomRepConfiguration(repOrder: 1, loadPercentage: 0, restAfterRep: 0),
            CustomRepConfiguration(repOrder: 2, loadPercentage: 5, restAfterRep: 10),
            CustomRepConfiguration(repOrder: 3, loadPercentage: 5, restAfterRep: 10),
            CustomRepConfiguration(repOrder: 4, loadPercentage: -15, restAfterRep: 15),
            CustomRepConfiguration(repOrder: 5, loadPercentage: -15, restAfterRep: 15),
            CustomRepConfiguration(repOrder: 6, loadPercentage: 30, restAfterRep: 20),
        ]
    )
    container.mainContext.insert(method)

    return NavigationStack {
        EditCustomMethodView(method: method)
            .modelContainer(container)
    }
}
