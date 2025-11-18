//
//  SettingsView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import SwiftUI
import SwiftData

struct SettingsView: View {
    let bluetoothManager: BluetoothHeartRateManager
    @Query private var profiles: [UserProfile]
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section(L("settings.section.general")) {
                    NavigationLink {
                        GeneralPreferencesView()
                    } label: {
                        Label(L("settings.general.preferences"), systemImage: "slider.horizontal.3")
                    }
                }

                Section(L("settings.section.account")) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Label(L("settings.profile"), systemImage: "person.circle")
                    }
                }

                Section(L("settings.section.clients")) {
                    NavigationLink {
                        ClientListView()
                    } label: {
                        Label(L("settings.clients.management"), systemImage: "person.3")
                    }
                }

                Section(L("settings.section.monitoring")) {
                    NavigationLink {
                        HeartRateMonitorView(bluetoothManager: bluetoothManager)
                    } label: {
                        Label(L("settings.heart.rate"), systemImage: "heart.circle")
                    }

                    NavigationLink {
                        StrengthExpressionsView()
                    } label: {
                        Label(L("settings.strength.expressions"), systemImage: "bolt.fill")
                    }
                }

                Section(L("settings.section.library")) {
                    NavigationLink {
                        MuscleListView()
                    } label: {
                        Label(L("settings.muscles"), systemImage: "figure.arms.open")
                    }

                    NavigationLink {
                        EquipmentListView()
                    } label: {
                        Label(L("settings.equipment"), systemImage: "dumbbell")
                    }

                    NavigationLink {
                        ExerciseListView()
                    } label: {
                        Label(L("settings.exercises"), systemImage: "figure.strengthtraining.traditional")
                    }
                }
            }
            .navigationTitle(L("settings.title"))
        }
    }
}

#Preview {
    SettingsView(bluetoothManager: BluetoothHeartRateManager())
        .modelContainer(for: [UserProfile.self, Muscle.self, Equipment.self, Exercise.self, Client.self, StrengthExpressionParameters.self], inMemory: true)
}
