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

                // Preview section showing how reps will be grouped during execution
                Section {
                    executionGroupsPreview
                } header: {
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(.purple)
                        Text("Anteprima Esecuzione")
                    }
                } footer: {
                    Text("Così verranno raggruppate le ripetizioni durante l'allenamento. Ripetizioni consecutive con stesso carico e stessa pausa vengono confermate insieme. I carichi mostrati sono esempi basati su 100kg.")
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

    // MARK: - Execution Preview

    private var executionGroupsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Create temporary method to test grouping
            let tempConfigs = repConfigurations.map { state in
                CustomRepConfiguration(
                    id: state.id,
                    repOrder: state.repOrder,
                    loadPercentage: state.loadPercentage,
                    restAfterRep: state.restAfterRep
                )
            }

            let tempMethod = CustomTrainingMethod(
                name: "Preview",
                repConfigurations: tempConfigs
            )

            let groups = tempMethod.createRepGroups(baseLoad: 100.0)

            if groups.isEmpty {
                Text("Configura le ripetizioni per vedere l'anteprima")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    GroupPreviewCard(group: group, groupNumber: index + 1)
                }
            }
        }
    }

    // MARK: - Data Management

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

// MARK: - Group Preview Card

struct GroupPreviewCard: View {
    let group: RepGroup
    let groupNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Group header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text("Gruppo \(groupNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }

                Spacer()

                Text(group.repRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Group details
            HStack(alignment: .top, spacing: 12) {
                // Load info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Carico")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Text("\(group.formattedLoad) kg")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if group.loadPercentage != 0 {
                            Text("(\(group.formattedLoadPercentage))")
                                .font(.caption)
                                .foregroundColor(group.loadPercentage > 0 ? .green : .red)
                        }
                    }
                }

                Divider()

                // Rest info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Pausa dopo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(formatRestTime(group.restAfterGroup))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(10)
    }

    private func formatRestTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        if seconds == 0 {
            return "Nessuna"
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

#Preview("New Method") {
    NavigationStack {
        EditCustomMethodView()
            .modelContainer(for: [CustomTrainingMethod.self], inMemory: true)
    }
}

#Preview("Edit Method") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
        container = try ModelContainer(for: CustomTrainingMethod.self, configurations: config)
    } catch {
        fatalError("Failed to create ModelContainer for preview: \(error)")
    }

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
