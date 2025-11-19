import SwiftUI

/// Componente per gestire i campi ripetizioni e carico (kg/% 1RM)
struct RepsAndLoadFields: View {
    @Binding var set: WorkoutSetData
    let oneRepMax: Double?
    let targetParameters: StrengthExpressionParameters?

    // Validazione del carico rispetto all'obiettivo
    private var loadPercentage: Double? {
        guard let oneRepMax = oneRepMax else { return nil }
        if let weight = set.weight, set.loadType == .absolute, oneRepMax > 0 {
            return (weight / oneRepMax) * 100.0
        } else if let percentage = set.percentageOfMax, set.loadType == .percentage {
            return percentage
        }
        return nil
    }

    private var isLoadOutOfRange: Bool {
        guard let params = targetParameters, let loadPct = loadPercentage else { return false }
        return !params.isLoadInRange(loadPct)
    }

    private var areRepsOutOfRange: Bool {
        guard let params = targetParameters, let reps = set.reps else { return false }
        return !params.areRepsInRange(reps)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Prima riga: Rip + Toggle Kg/%
            HStack(spacing: 16) {
                Spacer()
                    .frame(width: 60)

                HStack(spacing: 4) {
                    TextField("Rip", value: $set.reps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("rip")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if areRepsOutOfRange {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Picker("", selection: $set.loadType) {
                    Text("Kg").tag(LoadType.absolute)
                    Text("% 1RM").tag(LoadType.percentage)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            // Seconda riga: Campo input + valore calcolato
            HStack(spacing: 16) {
                Spacer()
                    .frame(width: 60)

                Spacer()
                    .frame(width: 54) // Allinea con campo Rip

                if set.loadType == .absolute {
                    HStack(spacing: 4) {
                        TextField(
                            "Kg",
                            value: Binding(
                                get: { set.weight },
                                set: { newValue in
                                    set.weight = newValue
                                }
                            ),
                            format: .number
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Mostra percentuale calcolata se disponibile 1RM
                    if let oneRepMax = oneRepMax, let weight = set.weight, oneRepMax > 0 {
                        let percentage = (weight / oneRepMax) * 100.0
                        HStack(spacing: 4) {
                            Text("→ \(Int(percentage))%")
                                .font(.caption)
                                .foregroundStyle(isLoadOutOfRange ? .yellow : .blue)

                            if isLoadOutOfRange {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        TextField(
                            "%",
                            value: Binding(
                                get: { set.percentageOfMax },
                                set: { newValue in
                                    set.percentageOfMax = newValue
                                }
                            ),
                            format: .number
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Mostra kg calcolati se disponibile 1RM
                    if let oneRepMax = oneRepMax, let percentage = set.percentageOfMax {
                        let weight = (percentage / 100.0) * oneRepMax
                        HStack(spacing: 4) {
                            Text("→ \(String(format: "%.1f", weight)) kg")
                                .font(.caption)
                                .foregroundStyle(isLoadOutOfRange ? .yellow : .blue)

                            if isLoadOutOfRange {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    } else if set.percentageOfMax != nil {
                        Text("⚠️ 1RM non impostato")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}
