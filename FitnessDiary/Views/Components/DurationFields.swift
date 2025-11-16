import SwiftUI

/// Componente per gestire i campi durata (minuti e secondi)
struct DurationFields: View {
    @Binding var set: WorkoutSetData

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
                .frame(width: 60)

            HStack(spacing: 4) {
                TextField("Minuti", value: Binding(
                    get: {
                        if let duration = set.duration {
                            return Int(duration) / 60
                        }
                        return 0
                    },
                    set: { newMinutes in
                        let seconds = set.duration.map { Int($0) % 60 } ?? 0
                        set.duration = TimeInterval(newMinutes * 60 + seconds)
                    }
                ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                Text("min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                TextField("Secondi", value: Binding(
                    get: {
                        if let duration = set.duration {
                            return Int(duration) % 60
                        }
                        return 0
                    },
                    set: { newSeconds in
                        let minutes = set.duration.map { Int($0) / 60 } ?? 0
                        set.duration = TimeInterval(minutes * 60 + newSeconds)
                    }
                ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                Text("sec")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
