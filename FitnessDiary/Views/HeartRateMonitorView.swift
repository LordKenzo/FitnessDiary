//
//  HeartRateMonitorView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import SwiftUI
import SwiftData

struct HeartRateMonitorView: View {
    @State private var bluetoothManager = BluetoothHeartRateManager()
    @Query private var profiles: [UserProfile]
    
    init() {}

    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con stato connessione
                connectionHeader
                
                Divider()
                
                // Contenuto principale
                if bluetoothManager.isConnected {
                    heartRateDisplay
                } else {
                    deviceScanner
                }
            }
            .navigationTitle("Heart Rate Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if bluetoothManager.isConnected {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Disconnetti") {
                            bluetoothManager.disconnect()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Connection Header
    private var connectionHeader: some View {
        VStack(spacing: 12) {
            // Status Badge
            HStack {
                Circle()
                    .fill(bluetoothManager.isConnected ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                
                Text(bluetoothManager.connectionStatus.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Error Message
            if let error = bluetoothManager.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Heart Rate Display
    private var heartRateDisplay: some View {
        ScrollView {
            VStack(spacing: 24) {
                // BPM principale
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(bluetoothManager.currentHeartRate)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(currentZoneColor)
                            .contentTransition(.numericText())
                        
                        Text("bpm")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Zona corrente
                    if let zone = currentZone {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 12, height: 12)
                            Text(zone.name)
                                .font(.headline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(zone.color.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 40)
                
                // Grafico zone cardio
                if let profile = userProfile {
                    heartRateZonesChart(profile: profile)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Device Scanner
    private var deviceScanner: some View {
        VStack(spacing: 20) {
            if bluetoothManager.discoveredDevices.isEmpty {
                // Nessun dispositivo ancora
                if bluetoothManager.isScanning {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Ricerca dispositivi...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Nessun risultato + pulsante per avviare
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        
                        Text("Nessun dispositivo trovato")
                            .font(.headline)
                        
                        Text("Assicurati che il tuo heart rate monitor sia acceso e nelle vicinanze")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            bluetoothManager.startScanning()
                        }) {
                            Label("Avvia Scansione", systemImage: "magnifyingglass")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Dispositivi trovati: MOSTRA LA LISTA SEMPRE
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Dispositivi trovati")
                            .font(.headline)
                        Spacer()
                        
                        if bluetoothManager.isScanning {
                            Button("Ferma") {
                                bluetoothManager.stopScanning()
                            }
                            .font(.subheadline)
                        } else {
                            Button("Scansiona") {
                                bluetoothManager.startScanning()
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    
                    List {
                        ForEach(bluetoothManager.discoveredDevices) { device in
                            Button {
                                bluetoothManager.connect(to: device)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(device.name)
                                            .font(.headline)
                                        
                                        HStack(spacing: 4) {
                                            signalIcon(for: device.rssi)
                                            Text(device.signalStrength)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

    
    // MARK: - Heart Rate Zones Chart
    private func heartRateZonesChart(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zone di Frequenza Cardiaca")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                    let range = zoneRange(for: zone, profile: profile)
                    let isInZone = isHeartRateInZone(zone, profile: profile)
                    
                    HStack {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(zone.name)
                                .font(.subheadline)
                                .fontWeight(isInZone ? .semibold : .regular)
                            Text(zone.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(range)
                            .font(.subheadline)
                            .fontWeight(isInZone ? .semibold : .regular)
                            .foregroundStyle(isInZone ? zone.color : .secondary)
                    }
                    .padding(12)
                    .background(isInZone ? zone.color.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    private var currentZone: HeartRateZone? {
        guard let profile = userProfile else { return nil }
        
        let hr = bluetoothManager.currentHeartRate
        
        if hr <= profile.zone1Max {
            return .zone1
        } else if hr <= profile.zone2Max {
            return .zone2
        } else if hr <= profile.zone3Max {
            return .zone3
        } else if hr <= profile.zone4Max {
            return .zone4
        } else {
            return .zone5
        }
    }
    
    private var currentZoneColor: Color {
        currentZone?.color ?? .gray
    }
    
    private func isHeartRateInZone(_ zone: HeartRateZone, profile: UserProfile) -> Bool {
        let hr = bluetoothManager.currentHeartRate
        guard hr > 0 else { return false }
        
        switch zone {
        case .zone1:
            return hr <= profile.zone1Max
        case .zone2:
            return hr > profile.zone1Max && hr <= profile.zone2Max
        case .zone3:
            return hr > profile.zone2Max && hr <= profile.zone3Max
        case .zone4:
            return hr > profile.zone3Max && hr <= profile.zone4Max
        case .zone5:
            return hr > profile.zone4Max
        }
    }
    
    private func zoneRange(for zone: HeartRateZone, profile: UserProfile) -> String {
        switch zone {
        case .zone1:
            return "< \(profile.zone1Max)"
        case .zone2:
            return "\(profile.zone1Max + 1)-\(profile.zone2Max)"
        case .zone3:
            return "\(profile.zone2Max + 1)-\(profile.zone3Max)"
        case .zone4:
            return "\(profile.zone3Max + 1)-\(profile.zone4Max)"
        case .zone5:
            return "> \(profile.zone4Max)"
        }
    }
    
    private func signalIcon(for rssi: Int) -> some View {
        let strength: Int
        switch rssi {
        case -50...0: strength = 3
        case -70 ..< -50: strength = 2
        case -90 ..< -70: strength = 1
        default: strength = 0
        }
        
        return Image(systemName: "wifi", variableValue: Double(strength) / 3.0)
            .foregroundStyle(strength > 1 ? .green : strength > 0 ? .orange : .red)
    }
}

#Preview {
    HeartRateMonitorView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
