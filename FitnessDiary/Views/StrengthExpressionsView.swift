//
//  StrengthExpressionsView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI
import SwiftData

struct StrengthExpressionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allParameters: [StrengthExpressionParameters]

    var body: some View {
        List {
            Section {
                Text("Configura i parametri di ogni espressione di forza per ricevere feedback intelligenti durante la creazione degli allenamenti.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Espressioni di Forza") {
                ForEach(StrengthExpressionType.allCases) { type in
                    if let params = getParameters(for: type) {
                        NavigationLink {
                            EditStrengthExpressionView(parameters: params)
                        } label: {
                            StrengthExpressionRow(parameters: params)
                        }
                    }
                }
            }
        }
        .navigationTitle("Espressioni Forza")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeDefaultParametersIfNeeded()
        }
    }

    private func getParameters(for type: StrengthExpressionType) -> StrengthExpressionParameters? {
        allParameters.first(where: { $0.type == type })
    }

    private func initializeDefaultParametersIfNeeded() {
        // Se non ci sono parametri salvati, crea i default per tutti i tipi
        for type in StrengthExpressionType.allCases {
            if !allParameters.contains(where: { $0.type == type }) {
                let defaultParams = StrengthExpressionParameters.defaultParameters(for: type)
                modelContext.insert(defaultParams)
            }
        }
    }
}

struct StrengthExpressionRow: View {
    let parameters: StrengthExpressionParameters

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: parameters.type.icon)
                .font(.title2)
                .foregroundStyle(parameters.type.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(parameters.type.rawValue)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(Int(parameters.loadPercentageMin))-\(Int(parameters.loadPercentageMax))%", systemImage: "gauge.with.dots.needle.67percent")
                    Label("\(parameters.repsMin)-\(parameters.repsMax) reps", systemImage: "repeat")
                    Label("\(parameters.restTimeMinFormatted)-\(parameters.restTimeMaxFormatted)", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EditStrengthExpressionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var parameters: StrengthExpressionParameters

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: parameters.type.icon)
                        .font(.largeTitle)
                        .foregroundStyle(parameters.type.color)
                    Text(parameters.type.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Percentuale di Carico (% 1-RM)") {
                HStack {
                    Text("Minimo")
                    Spacer()
                    TextField("Min %", value: $parameters.loadPercentageMin, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("%")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Massimo")
                    Spacer()
                    TextField("Max %", value: $parameters.loadPercentageMax, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("%")
                        .foregroundStyle(.secondary)
                }

                Text("Range: \(Int(parameters.loadPercentageMin))-\(Int(parameters.loadPercentageMax))% dell'1-RM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Serie") {
                Stepper("Minimo: \(parameters.setsMin)", value: $parameters.setsMin, in: 1...10)
                Stepper("Massimo: \(parameters.setsMax)", value: $parameters.setsMax, in: 1...10)

                Text("Range: \(parameters.setsMin)-\(parameters.setsMax) serie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Ripetizioni") {
                Stepper("Minimo: \(parameters.repsMin)", value: $parameters.repsMin, in: 1...50)
                Stepper("Massimo: \(parameters.repsMax)", value: $parameters.repsMax, in: 1...50)

                Text("Range: \(parameters.repsMin)-\(parameters.repsMax) ripetizioni")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Tempo di Recupero") {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Minimo")
                            Spacer()
                            Text(parameters.restTimeMinFormatted)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $parameters.restTimeMin, in: 30...600, step: 30)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Massimo")
                            Spacer()
                            Text(parameters.restTimeMaxFormatted)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $parameters.restTimeMax, in: 30...600, step: 30)
                    }
                }

                Text("Range: \(parameters.restTimeMinFormatted)-\(parameters.restTimeMaxFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Ripristina Valori di Default") {
                    resetToDefaults()
                }
                .foregroundStyle(.blue)
            }
        }
        .navigationTitle("Modifica Parametri")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fatto") {
                    dismiss()
                }
            }
        }
    }

    private func resetToDefaults() {
        let defaults = StrengthExpressionParameters.defaultParameters(for: parameters.type)
        parameters.loadPercentageMin = defaults.loadPercentageMin
        parameters.loadPercentageMax = defaults.loadPercentageMax
        parameters.setsMin = defaults.setsMin
        parameters.setsMax = defaults.setsMax
        parameters.repsMin = defaults.repsMin
        parameters.repsMax = defaults.repsMax
        parameters.restTimeMin = defaults.restTimeMin
        parameters.restTimeMax = defaults.restTimeMax
    }
}

#Preview {
    NavigationStack {
        StrengthExpressionsView()
    }
    .modelContainer(for: StrengthExpressionParameters.self, inMemory: true)
}
