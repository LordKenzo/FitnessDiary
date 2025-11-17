//
//  GeneralSettingsView.swift
//  FitnessDiary
//
//  Created by Claude on 17/11/2025.
//

import SwiftUI
import SwiftData

struct GeneralSettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    private var userProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        Form {
            if let profile = userProfile {
                Section {
                    Stepper("Countdown: \(profile.workoutCountdownSeconds)s",
                           value: Binding(
                               get: { profile.workoutCountdownSeconds },
                               set: { profile.workoutCountdownSeconds = $0 }
                           ),
                           in: 0...30,
                           step: 5)
                } header: {
                    Text("Allenamento")
                } footer: {
                    Text("Tempo di countdown prima dell'inizio dell'allenamento. Può essere saltato per iniziare subito.")
                        .font(.caption)
                }
            } else {
                ContentUnavailableView(
                    "Nessun Profilo",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Crea un profilo per configurare le impostazioni")
                )
            }
        }
        .navigationTitle("Impostazioni Generali")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GeneralSettingsView()
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
