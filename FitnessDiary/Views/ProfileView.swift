import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @State private var showingSetup = false
    
    private var profile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            if let profile = profile {
                ProfileDetailView(profile: profile)
            } else {
                ContentUnavailableView {
                    Label("Nessun Profilo", systemImage: "person.circle")
                } description: {
                    Text("Crea il tuo profilo per iniziare")
                } actions: {
                    Button("Crea Profilo") {
                        showingSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showingSetup) {
            ProfileSetupView()
        }
        .onAppear {
            if profile == nil {
                showingSetup = true
            }
        }
    }
}

struct ProfileDetailView: View {
    @Bindable var profile: UserProfile
    @State private var showingEdit = false
    
    var body: some View {
        List {
            // Foto e Info Base
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if let image = profile.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.gray)
                        }
                        
                        Text(profile.name)
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section("Dati Fisici") {
                LabeledContent("Sesso", value: profile.gender.rawValue)
                LabeledContent("Età", value: "\(profile.age) anni")
                LabeledContent("Peso", value: String(format: "%.1f kg", profile.weight))
                LabeledContent("Altezza", value: String(format: "%.0f cm", profile.height))
                LabeledContent("BMI", value: String(format: "%.1f", calculateBMI()))
            }
            
            Section("Frequenza Cardiaca") {
                LabeledContent("FC Massima", value: "\(profile.maxHeartRate) bpm")
            }
            
            Section("Zone Cardio") {
                ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                    HStack {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 12, height: 12)
                        Text(zone.name)
                        Spacer()
                        Text(zoneRange(for: zone))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Profilo")
        .toolbar {
            Button("Modifica") {
                showingEdit = true
            }
        }
        .sheet(isPresented: $showingEdit) {
            ProfileEditView(profile: profile)
        }
    }
    
    /// Computes the body mass index (BMI) for the current profile.
    /// - Returns: The BMI value computed as weight in kilograms divided by height in meters squared.
    private func calculateBMI() -> Double {
        let heightInMeters = profile.height / 100
        guard heightInMeters > 0 else { return 0 }
        return profile.weight / (heightInMeters * heightInMeters)
    }
    
    /// Formats the BPM range string for a given heart rate zone using the current profile's zone thresholds.
    /// - Parameters:
    ///   - zone: The heart rate zone to format.
    /// - Returns: A human-readable BPM range for the zone (e.g., "< 100 bpm", "100-120 bpm", "> 160 bpm").
    private func zoneRange(for zone: HeartRateZone) -> String {
        switch zone {
        case .zone1:
            return "0 - \(profile.zone1Max) bpm"
        case .zone2:
            return "\(profile.zone1Max + 1) - \(profile.zone2Max) bpm"
        case .zone3:
            return "\(profile.zone2Max + 1) - \(profile.zone3Max) bpm"
        case .zone4:
            return "\(profile.zone3Max + 1) - \(profile.zone4Max) bpm"
        case .zone5:
            return "\(profile.zone4Max + 1) - \(profile.zone5Max) bpm"
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    
    var body: some View {
        NavigationStack {
            Form {
                // Implementazione simile a ProfileSetupView
                // ma che modifica il profilo esistente
                Text("Modifica profilo - DA IMPLEMENTARE")
            }
            .navigationTitle("Modifica Profilo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}