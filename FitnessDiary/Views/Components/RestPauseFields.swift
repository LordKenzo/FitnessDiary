import SwiftUI

/// Componente per gestire i parametri Rest-Pause
struct RestPauseFields: View {
    @Binding var set: WorkoutSetData

    var body: some View {
        VStack(spacing: 8) {
            // Numero di pause
            HStack(spacing: 16) {
                Text("Pause")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Stepper {
                    HStack(spacing: 4) {
                        Text("\(set.restPauseCount ?? 2)")
                            .font(.subheadline)
                        Text("pause")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } onIncrement: {
                    set.restPauseCount = min(5, (set.restPauseCount ?? 2) + 1)
                } onDecrement: {
                    set.restPauseCount = max(1, (set.restPauseCount ?? 2) - 1)
                }
                .frame(width: 120)

                Spacer()
            }

            // Durata pause
            HStack(spacing: 16) {
                Text("Durata")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 4) {
                    TextField("Sec", value: Binding(
                        get: {
                            if let duration = set.restPauseDuration {
                                return Int(duration)
                            }
                            return 15
                        },
                        set: { newValue in
                            set.restPauseDuration = TimeInterval(min(30, max(5, newValue)))
                        }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("sec (5-30)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Descrizione rest-pause se valida
            if let description = set.restPauseDescription {
                HStack(spacing: 16) {
                    Spacer()
                        .frame(width: 60)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Spacer()
                }
            }
        }
    }
}
