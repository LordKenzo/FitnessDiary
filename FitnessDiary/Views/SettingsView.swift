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
    
    var body: some View {
        NavigationStack {
            List {
                Section("Generali") {
                    NavigationLink {
                        GeneralSettingsView()
                    } label: {
                        Label("Impostazioni Generali", systemImage: "gearshape")
                    }
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
