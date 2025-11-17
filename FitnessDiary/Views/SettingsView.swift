//
//  SettingsView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false
    @AppStorage("workoutCountdownSeconds") private var workoutCountdownSeconds = 10

    var body: some View {
        NavigationStack {
            List {
                Section("Preferenze Generali") {
                    Toggle("Debug Sequenza Allenamento", isOn: $debugWorkoutLogEnabled)

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

                Section("Account") {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Label("Profilo", systemImage: "person.circle")
                    }
                }

                Section("Clienti") {
                    NavigationLink {
                        ClientListView()
                    } label: {
                        Label("Gestione Clienti", systemImage: "person.3")
                    }
                }

                Section("Monitoraggio") {
                    NavigationLink {
                        HeartRateMonitorView()
                    } label: {
                        Label("Heart Rate", systemImage: "heart.circle")
                    }

                    NavigationLink {
                        StrengthExpressionsView()
                    } label: {
                        Label("Espressioni Forza", systemImage: "bolt.fill")
                    }
                }
                
                Section("Libreria") {
                    NavigationLink {
                        MuscleListView()
                    } label: {
                        Label("Muscoli", systemImage: "figure.arms.open")
                    }

                    NavigationLink {
                        EquipmentListView()
                    } label: {
                        Label("Attrezzi", systemImage: "dumbbell")
                    }

                    NavigationLink {
                        ExerciseListView()
                    } label: {
                        Label("Esercizi", systemImage: "figure.strengthtraining.traditional")
                    }
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, Muscle.self, Equipment.self, Exercise.self, Client.self, StrengthExpressionParameters.self], inMemory: true)
}
