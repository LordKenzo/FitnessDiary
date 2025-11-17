import SwiftUI

struct GeneralPreferencesView: View {
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false
    @AppStorage("workoutCountdownSeconds") private var workoutCountdownSeconds = 10
    @AppStorage("cloneLoadEnabled") private var cloneLoadEnabled = true

    var body: some View {
        Form {
            Section("Preferenze Generali") {
                Toggle("Genera Sequenza Allenamento", isOn: $debugWorkoutLogEnabled)

                Toggle("Clona automaticamente il carico", isOn: $cloneLoadEnabled)
                    .tint(.blue)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Countdown iniziale")
                        Spacer()
                        Text("\(workoutCountdownSeconds) sec")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: Binding(
                            get: { Double(workoutCountdownSeconds) },
                            set: { workoutCountdownSeconds = Int($0) }
                        ),
                        in: 0...120,
                        step: 1
                    )
                }

                Text("Made with ❤️ by Lorenzo Franceschini")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Preferenze Generali")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GeneralPreferencesView()
    }
}
