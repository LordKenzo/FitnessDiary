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
    @State private var customMaxHRText: String
    @State private var useCustomZones = false

    // Zone temporanee per editing
    @State private var tempZone1Text: String
    @State private var tempZone2Text: String
    @State private var tempZone3Text: String
    @State private var tempZone4Text: String
    @State private var tempZone5Text: String
    
    init(profile: UserProfile) {
        self.profile = profile
        _customMaxHRText = State(initialValue: "\(profile.maxHeartRate)")
        _tempZone1Text = State(initialValue: "\(profile.zone1Max)")
        _tempZone2Text = State(initialValue: "\(profile.zone2Max)")
        _tempZone3Text = State(initialValue: "\(profile.zone3Max)")
        _tempZone4Text = State(initialValue: "\(profile.zone4Max)")
        _tempZone5Text = State(initialValue: "\(profile.zone5Max)")
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
                            TextField("FC Max", text: numericBinding($customMaxHRText))
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
            .glassScrollBackground()
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
                    customMaxHRText = "\(calculatedMaxHR)"
                    if !useCustomZones {
                        recalculateZones()
                    }
                }
            }
            .onChange(of: customMaxHRText) { _, _ in
                if !useCustomZones {
                    recalculateZones()
                }
            }
        }
        .appScreenBackground()
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
                    TextField("Max", text: numericBinding($tempZone1Text))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: 0 - \(zoneValue(for: .zone1)) bpm")
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
                    TextField("Max", text: numericBinding($tempZone2Text))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(zoneValue(for: .zone1) + 1) - \(zoneValue(for: .zone2)) bpm")
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
                    TextField("Max", text: numericBinding($tempZone3Text))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(zoneValue(for: .zone2) + 1) - \(zoneValue(for: .zone3)) bpm")
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
                    TextField("Max", text: numericBinding($tempZone4Text))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(zoneValue(for: .zone3) + 1) - \(zoneValue(for: .zone4)) bpm")
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
                    TextField("Max", text: numericBinding($tempZone5Text))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("bpm")
                }
                Text("Range: \(zoneValue(for: .zone4) + 1) - \(zoneValue(for: .zone5)) bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("⚠️ Assicurati che ogni zona sia progressiva (Zone 1 < Zona 2 < ... < Zona 5)")
        }
    }
    
    private func autoZoneRange(for zone: HeartRateZone) -> String {
        let maxHR = selectedMaxHeartRate
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
                return "0 - \(zoneValue(for: .zone1)) bpm"
            case .zone2:
                return "\(zoneValue(for: .zone1) + 1) - \(zoneValue(for: .zone2)) bpm"
            case .zone3:
                return "\(zoneValue(for: .zone2) + 1) - \(zoneValue(for: .zone3)) bpm"
            case .zone4:
                return "\(zoneValue(for: .zone3) + 1) - \(zoneValue(for: .zone4)) bpm"
            case .zone5:
                return "\(zoneValue(for: .zone4) + 1) - \(zoneValue(for: .zone5)) bpm"
            }
        } else {
            return autoZoneRange(for: zone)
        }
    }

    private func recalculateZones() {
        let maxHR = selectedMaxHeartRate
        tempZone1Text = "\(Int(Double(maxHR) * 0.60))"
        tempZone2Text = "\(Int(Double(maxHR) * 0.70))"
        tempZone3Text = "\(Int(Double(maxHR) * 0.80))"
        tempZone4Text = "\(Int(Double(maxHR) * 0.90))"
        tempZone5Text = "\(maxHR)"
    }

    private func saveZones() {
        let maxHR = selectedMaxHeartRate
        profile.maxHeartRate = maxHR

        if useCustomZones {
            profile.zone1Max = zoneValue(for: .zone1)
            profile.zone2Max = zoneValue(for: .zone2)
            profile.zone3Max = zoneValue(for: .zone3)
            profile.zone4Max = zoneValue(for: .zone4)
            profile.zone5Max = zoneValue(for: .zone5)
        } else {
            profile.updateHeartRateZones(maxHR: maxHR)
        }
    }

    private var customMaxHRValue: Int {
        guard let value = Int(customMaxHRText), value > 0 else {
            return profile.maxHeartRate
        }
        return value
    }

    private var selectedMaxHeartRate: Int {
        useCustomMaxHR ? customMaxHRValue : calculatedMaxHR
    }

    private func zoneValue(for zone: HeartRateZone) -> Int {
        switch zone {
        case .zone1:
            return Int(tempZone1Text) ?? profile.zone1Max
        case .zone2:
            return Int(tempZone2Text) ?? profile.zone2Max
        case .zone3:
            return Int(tempZone3Text) ?? profile.zone3Max
        case .zone4:
            return Int(tempZone4Text) ?? profile.zone4Max
        case .zone5:
            return Int(tempZone5Text) ?? profile.zone5Max
        }
    }

    private func numericBinding(_ binding: Binding<String>) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber }
                binding.wrappedValue = filtered
            }
        )
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
