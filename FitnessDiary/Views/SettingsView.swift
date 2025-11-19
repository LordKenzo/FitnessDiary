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

                Section(L("settings.section.legal")) {
                    if let privacyURL = SupportResources.privacyPolicyURL {
                        Link(destination: privacyURL) {
                            Label(L("settings.legal.privacy"), systemImage: "lock.shield")
                        }
                    }

                    if let termsURL = SupportResources.termsOfUseURL {
                        Link(destination: termsURL) {
                            Label(L("settings.legal.terms"), systemImage: "doc.text")
                        }
                    }

                    if let supportURL = SupportResources.supportEmailURL {
                        Link(destination: supportURL) {
                            Label(L("settings.legal.support"), systemImage: "envelope")
                        }
                    }
                }
            }
            .navigationTitle(L("settings.title"))
        }
    }
}

private enum SupportResources {
    static let privacyPolicyURL = URL(string: "https://raw.githubusercontent.com/LordKenzo/FitnessDiary/main/AppStoreMetadata/privacy-policy.html")
    static let termsOfUseURL = URL(string: "https://raw.githubusercontent.com/LordKenzo/FitnessDiary/main/AppStoreMetadata/terms-of-use.html")
    static let supportEmailURL = URL(string: "mailto:support@fittypal.com")
}

#Preview {
    SettingsView(bluetoothManager: BluetoothHeartRateManager())
        .modelContainer(for: [UserProfile.self, Muscle.self, Equipment.self, Exercise.self, Client.self, StrengthExpressionParameters.self], inMemory: true)
}
