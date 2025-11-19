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
        ScrollView {
            VStack(spacing: 24) {
                GlassSectionCard(
                    title: "Espressioni di Forza",
                    subtitle: "Personalizza i range per guidare carichi e recuperi",
                    iconName: "bolt.fill"
                ) {
                    Text("Configura i parametri di ogni espressione di forza per ricevere feedback intelligenti durante la creazione degli allenamenti.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GlassSectionCard(
                    title: "Preset disponibili",
                    iconName: "list.bullet.rectangle"
                ) {
                    ForEach(StrengthExpressionType.allCases) { type in
                        if let params = getParameters(for: type) {
                            NavigationLink {
                                EditStrengthExpressionView(parameters: params)
                            } label: {
                                GlassListRow(
                                    title: type.rawValue,
                                    subtitle: summary(for: params),
                                    iconName: type.icon,
                                    iconTint: type.color
                                ) {
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("Espressioni Forza")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeDefaultParametersIfNeeded()
        }
        .appScreenBackground()
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
        .glassScrollBackground()
        .appScreenBackground()
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

private func summary(for parameters: StrengthExpressionParameters) -> String {
    let load = "\(Int(parameters.loadPercentageMin))-\(Int(parameters.loadPercentageMax))%"
    let reps = "\(parameters.repsMin)-\(parameters.repsMax) reps"
    let rest = parameters.restTimeMinFormatted == parameters.restTimeMaxFormatted
        ? parameters.restTimeMinFormatted
        : "\(parameters.restTimeMinFormatted)-\(parameters.restTimeMaxFormatted)"
    return "\(load) • \(reps) • \(rest)"
}

#Preview {
    NavigationStack {
        StrengthExpressionsView()
    }
    .modelContainer(for: StrengthExpressionParameters.self, inMemory: true)
}
