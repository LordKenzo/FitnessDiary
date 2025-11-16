import SwiftUI

/// Componente per gestire i parametri Cluster Set
struct ClusterFields: View {
    @Binding var set: WorkoutSetData

    var body: some View {
        VStack(spacing: 8) {
            // Cluster Size
            HStack(spacing: 16) {
                Text("Cluster")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Reps", value: $set.clusterSize, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("reps/cluster")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Cluster Rest Time
            HStack(spacing: 16) {
                Text("Pausa")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Sec", value: Binding(
                        get: {
                            if let rest = set.clusterRestTime {
                                return Int(rest)
                            }
                            return 15
                        },
                        set: { newValue in
                            set.clusterRestTime = TimeInterval(min(60, max(15, newValue)))
                        }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("sec (15-60)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Progressione carico
            HStack(spacing: 16) {
                Text("Tipo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Picker("", selection: Binding(
                    get: { set.clusterProgression ?? .constant },
                    set: { set.clusterProgression = $0 }
                )) {
                    ForEach(ClusterLoadProgression.allCases, id: \.self) { progression in
                        Label(progression.rawValue, systemImage: progression.icon).tag(progression)
                    }
                }
                .pickerStyle(.menu)

                Spacer()
            }

            // Percentuale minima
            HStack(spacing: 16) {
                Text("Min %")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("%", value: Binding(
                        get: { set.clusterMinPercentage ?? 80 },
                        set: { set.clusterMinPercentage = min(100, max(50, $0)) }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("% 1RM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Percentuale massima
            HStack(spacing: 16) {
                Text("Max %")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("%", value: Binding(
                        get: { set.clusterMaxPercentage ?? 95 },
                        set: { set.clusterMaxPercentage = min(100, max(50, $0)) }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("% 1RM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Visualizzazione percentuali calcolate
            if let percentages = set.clusterLoadPercentages() {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carichi:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            ForEach(Array(percentages.enumerated()), id: \.offset) { index, pct in
                                Text("\(Int(pct))%")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                if index < percentages.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }

            // Descrizione cluster se valida
            if let description = set.clusterDescription {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Spacer()
                }
            }

            // Validazione: cluster non può essere > ripetizioni
            if let totalReps = set.reps, let clusterSize = set.clusterSize, clusterSize > totalReps {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Il cluster non può essere maggiore delle ripetizioni")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                }
            }
        }
    }
}
