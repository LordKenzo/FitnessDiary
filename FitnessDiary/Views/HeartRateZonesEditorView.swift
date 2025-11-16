//
//  HeartRateZonesEditorView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import SwiftUI
import SwiftData

struct HeartRateZonesEditorView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    @State private var useCustomMaxHR = false
    @State private var customMaxHR: Int
    @State private var useCustomZones = false
    
    // Zone temporanee per editing
    @State private var tempZone1Max: Int
    @State private var tempZone2Max: Int
    @State private var tempZone3Max: Int
    @State private var tempZone4Max: Int
    @State private var tempZone5Max: Int
    
    init(profile: UserProfile) {
        self.profile = profile
        _customMaxHR = State(initialValue: profile.maxHeartRate)
        _tempZone1Max = State(initialValue: profile.zone1Max)
        _tempZone2Max = State(initialValue: profile.zone2Max)
        _tempZone3Max = State(initialValue: profile.zone3Max)
        _tempZone4Max = State(initialValue: profile.zone4Max)
        _tempZone5Max = State(initialValue: profile.zone5Max)
    }
    
    var calculatedMaxHR: Int {
        220 - profile.age
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Sezione FC Massima
                Section {
                    Toggle("Usa FC massima personalizzata", isOn: $useCustomMaxHR)
                    
                    if useCustomMaxHR {
                        HStack {
                            Text("FC Massima")
                            Spacer()
                            TextField("FC Max", value: $customMaxHR, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("bpm")
                        }
                    } else {
                        LabeledContent("FC Massima calcolata", value: "\(calculatedMaxHR) bpm")
                    }
                } header: {
                    Text("Frequenza Cardiaca Massima")
                } footer: {
                    Text("Formula standard: 220 - età = \(calculatedMaxHR) bpm")
                }
                
                // Sezione Zone Cardio
                Section {
                    Toggle("Personalizza zone manualmente", isOn: $useCustomZones)
                } header: {
                    Text("Zone Cardio")
                }
                
                if useCustomZones {
                    customZonesSection
                } else {
                    automaticZonesSection
                }
                
                // Preview Zone
                Section("Anteprima Zone") {
                    ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                        HStack {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.name)
                                    .font(.subheadline)
                                Text(zone.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(previewZoneRange(for: zone))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Zone Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveZones()
                        dismiss()
                    }
                }
            }
            .onChange(of: useCustomMaxHR) { _, newValue in
                if !newValue {
                    customMaxHR = calculatedMaxHR
                    recalculateZones()
                }
            }
            .onChange(of: customMaxHR) { _, _ in
                if !useCustomZones {
                    recalculateZones()
                }
            }
        }
    }
    
    private var automaticZonesSection: some View {
        Section {
            ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                HStack {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 12, height: 12)
                    Text(zone.name)
                    Spacer()
                    Text(autoZoneRange(for: zone))
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Le zone vengono calcolate automaticamente in base alla FC massima")
        }
    }
    
    private var customZonesSection: some View {
        Section {
            // Zona 1
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(HeartRateZone.zone1.color)
                        .frame(width: 12, height: 12)
                    Text("Zona 1 - Recupero")
                }
                HStack {
                    Text("Massimo")
                    Spacer()
                    TextField("Max", value: $tempZone1Max, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: 0 - \(tempZone1Max) bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Zona 2
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(HeartRateZone.zone2.color)
                        .frame(width: 12, height: 12)
                    Text("Zona 2 - Endurance")
                }
                HStack {
                    Text("Massimo")
                    Spacer()
                    TextField("Max", value: $tempZone2Max, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(tempZone1Max + 1) - \(tempZone2Max) bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Zona 3
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(HeartRateZone.zone3.color)
                        .frame(width: 12, height: 12)
                    Text("Zona 3 - Tempo")
                }
                HStack {
                    Text("Massimo")
                    Spacer()
                    TextField("Max", value: $tempZone3Max, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(tempZone2Max + 1) - \(tempZone3Max) bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Zona 4
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(HeartRateZone.zone4.color)
                        .frame(width: 12, height: 12)
                    Text("Zona 4 - Soglia")
                }
                HStack {
                    Text("Massimo")
                    Spacer()
                    TextField("Max", value: $tempZone4Max, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(tempZone3Max + 1) - \(tempZone4Max) bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Zona 5
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(HeartRateZone.zone5.color)
                        .frame(width: 12, height: 12)
                    Text("Zona 5 - VO2 Max")
                }
                HStack {
                    Text("Massimo")
                    Spacer()
                    TextField("Max", value: $tempZone5Max, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(tempZone4Max + 1) - \(tempZone5Max) bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("⚠️ Assicurati che ogni zona sia progressiva (Zone 1 < Zona 2 < ... < Zona 5)")
        }
    }
    
    private func autoZoneRange(for zone: HeartRateZone) -> String {
        let maxHR = useCustomMaxHR ? customMaxHR : calculatedMaxHR
        let z1 = Int(Double(maxHR) * 0.60)
        let z2 = Int(Double(maxHR) * 0.70)
        let z3 = Int(Double(maxHR) * 0.80)
        let z4 = Int(Double(maxHR) * 0.90)
        let z5 = maxHR
        
        switch zone {
        case .zone1:
            return "0 - \(z1) bpm"
        case .zone2:
            return "\(z1 + 1) - \(z2) bpm"
        case .zone3:
            return "\(z2 + 1) - \(z3) bpm"
        case .zone4:
            return "\(z3 + 1) - \(z4) bpm"
        case .zone5:
            return "\(z4 + 1) - \(z5) bpm"
        }
    }
    
    private func previewZoneRange(for zone: HeartRateZone) -> String {
        if useCustomZones {
            switch zone {
            case .zone1:
                return "0 - \(tempZone1Max) bpm"
            case .zone2:
                return "\(tempZone1Max + 1) - \(tempZone2Max) bpm"
            case .zone3:
                return "\(tempZone2Max + 1) - \(tempZone3Max) bpm"
            case .zone4:
                return "\(tempZone3Max + 1) - \(tempZone4Max) bpm"
            case .zone5:
                return "\(tempZone4Max + 1) - \(tempZone5Max) bpm"
            }
        } else {
            return autoZoneRange(for: zone)
        }
    }
    
    private func recalculateZones() {
        let maxHR = useCustomMaxHR ? customMaxHR : calculatedMaxHR
        tempZone1Max = Int(Double(maxHR) * 0.60)
        tempZone2Max = Int(Double(maxHR) * 0.70)
        tempZone3Max = Int(Double(maxHR) * 0.80)
        tempZone4Max = Int(Double(maxHR) * 0.90)
        tempZone5Max = maxHR
    }
    
    private func saveZones() {
        let maxHR = useCustomMaxHR ? customMaxHR : calculatedMaxHR
        profile.maxHeartRate = maxHR
        
        if useCustomZones {
            profile.zone1Max = tempZone1Max
            profile.zone2Max = tempZone2Max
            profile.zone3Max = tempZone3Max
            profile.zone4Max = tempZone4Max
            profile.zone5Max = tempZone5Max
        } else {
            profile.updateHeartRateZones(maxHR: maxHR)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let profile = UserProfile(name: "Mario Rossi", age: 30)
        container.mainContext.insert(profile)
        
        return HeartRateZonesEditorView(profile: profile)
            .environment(\.modelContext, container.mainContext)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
