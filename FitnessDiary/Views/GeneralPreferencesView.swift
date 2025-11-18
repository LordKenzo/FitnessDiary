import SwiftUI

struct GeneralPreferencesView: View {
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false
    @AppStorage("workoutCountdownSeconds") private var workoutCountdownSeconds = 10
    @AppStorage("cloneLoadEnabled") private var cloneLoadEnabled = true
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        Form {
            Section(L("preferences.section.general")) {
                // Language Picker
                Picker(L("preferences.language"), selection: Binding(
                    get: { localizationManager.currentLanguage },
                    set: { newLanguage in
                        localizationManager.setLanguage(newLanguage)
                    }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.displayName)
                        }
                        .tag(language)
                    }
                }
                .pickerStyle(.menu)

                Toggle(L("preferences.debug.log"), isOn: $debugWorkoutLogEnabled)

                Toggle(L("preferences.clone.load"), isOn: $cloneLoadEnabled)
                    .tint(.blue)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(localized: "preferences.countdown")
                        Spacer()
                        Text(String(format: L("preferences.countdown.seconds"), workoutCountdownSeconds))
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

                Text(localized: "preferences.made.by")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .navigationTitle(L("preferences.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GeneralPreferencesView()
    }
}
