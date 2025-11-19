//
//  HeartRateMonitorView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//

import SwiftUI
import SwiftData
import Observation

struct HeartRateMonitorView: View {
    @Bindable var bluetoothManager: BluetoothHeartRateManager
    @Query private var profiles: [UserProfile]

    init(bluetoothManager: BluetoothHeartRateManager) {
        self.bluetoothManager = bluetoothManager
    }

    private var userProfile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    connectionCard

                    if bluetoothManager.isConnected {
                        heartRateCard

                        if let profile = userProfile {
                            heartRateZonesCard(profile: profile)
                        }
                    } else {
                        discoveryCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Heart Rate Monitor")
            .navigationBarTitleDisplayMode(.inline)
        }
        .appScreenBackground()
    }

    // MARK: - Cards
    private var connectionCard: some View {
        GlassSectionCard(
            title: "Stato connessione",
            subtitle: bluetoothManager.errorMessage == nil ? nil : "Problemi con il dispositivo",
            iconName: "antenna.radiowaves.left.and.right"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(bluetoothManager.isConnected ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)

                    Text(bluetoothManager.connectionStatus.description)
                        .font(.headline)
                    Spacer()
                    statusActionButton
                }

                if let error = bluetoothManager.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var heartRateCard: some View {
        GlassSectionCard(
            title: "Battito attuale",
            subtitle: bluetoothManager.isConnected ? "Monitoraggio in tempo reale" : nil,
            iconName: "heart.fill"
        ) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(bluetoothManager.currentHeartRate)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(currentZoneColor)
                            .contentTransition(.numericText())
                        Text("bpm")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    if let zone = currentZone {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 12, height: 12)
                            Text(zone.name)
                                .font(.headline)
                            Spacer()
                            Text(zone.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(zone.color.opacity(0.15), in: Capsule())
                    }
                }

            }
        }
    }

    private func heartRateZonesCard(profile: UserProfile) -> some View {
        GlassSectionCard(
            title: "Zone di Frequenza Cardiaca",
            iconName: "chart.bar.doc.horizontal"
        ) {
            VStack(spacing: 12) {
                ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                    let range = zoneRange(for: zone, profile: profile)
                    let isInZone = isHeartRateInZone(zone, profile: profile)

                    HStack(spacing: 12) {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 14, height: 14)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(zone.name)
                                .font(.subheadline.weight(isInZone ? .semibold : .regular))
                            Text(zone.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(range)
                            .font(.subheadline)
                            .foregroundStyle(isInZone ? zone.color : .secondary)
                    }
                    .padding(12)
                    .background(isInZone ? zone.color.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var discoveryCard: some View {
        GlassSectionCard(
            title: "Dispositivi Bluetooth",
            subtitle: bluetoothManager.isScanning ? "Ricerca in corso" : "Attiva lo scan per collegarti",
            iconName: "dot.radiowaves.left.and.right"
        ) {
            if bluetoothManager.discoveredDevices.isEmpty {
                VStack(spacing: 16) {
                    if bluetoothManager.isScanning {
                        ProgressView()
                            .scaleEffect(1.3)
                        Text("Ricerca dispositivi...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "heart.circle")
                            .font(.system(size: 58))
                            .foregroundStyle(.pink)
                        Text("Nessun dispositivo trovato")
                            .font(.headline)
                        Text("Assicurati che il cardiofrequenzimetro sia acceso e nelle vicinanze.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button(action: { bluetoothManager.startScanning() }) {
                            Label("Avvia scansione", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("Dispositivi trovati")
                            .font(.headline)
                        Spacer()
                        if bluetoothManager.isScanning {
                            Button("Ferma") { bluetoothManager.stopScanning() }
                        } else {
                            Button("Scansiona") { bluetoothManager.startScanning() }
                        }
                        .font(.footnote.weight(.semibold))
                    }

                    ForEach(bluetoothManager.discoveredDevices) { device in
                        Button {
                            bluetoothManager.connect(to: device)
                        } label: {
                            GlassListRow(
                                title: device.name,
                                subtitle: device.signalStrength,
                                iconName: "antenna.radiowaves.left.and.right"
                            ) {
                                signalIcon(for: device.rssi)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private var statusActionButton: some View {
        if bluetoothManager.isConnected {
            Button("Disconnetti") {
                bluetoothManager.disconnect()
            }
            .font(.footnote.weight(.semibold))
        } else if bluetoothManager.isScanning {
            Button("Ferma") {
                bluetoothManager.stopScanning()
            }
            .font(.footnote.weight(.semibold))
        } else {
            Button("Scansiona") {
                bluetoothManager.startScanning()
            }
            .font(.footnote.weight(.semibold))
        }
    }

    private var currentZone: HeartRateZone? {
        guard let profile = userProfile else { return nil }

        let hr = bluetoothManager.currentHeartRate
        guard hr > 0 else { return nil }

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
    HeartRateMonitorView(bluetoothManager: BluetoothHeartRateManager())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
