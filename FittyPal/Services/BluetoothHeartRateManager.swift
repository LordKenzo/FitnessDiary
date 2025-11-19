import Foundation
@preconcurrency import CoreBluetooth
import Observation

@Observable
final class BluetoothHeartRateManager: NSObject {
    // MARK: - Published Properties
    var isScanning = false
    var isConnected = false
    var discoveredDevices: [HeartRateDevice] = []
    var currentHeartRate: Int = 0
    var connectionStatus: ConnectionStatus = .disconnected
    var errorMessage: String?
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    // Timeout gestione connessione
    private var connectionTimer: Timer?
    private let connectionTimeout: TimeInterval = 10.0
    
    private let heartRateServiceUUID = CBUUID(string: "180D")  // Heart Rate Service
    private let heartRateCharacteristicUUID = CBUUID(string: "2A37") // Heart Rate Measurement
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth non è disponibile. Stato: \(centralManager.state.description)"
            return
        }
        
        discoveredDevices.removeAll()
        isScanning = true
        errorMessage = nil
        
        // 🔎 Scansiona SOLO dispositivi che espongono Heart Rate Service
        centralManager.scanForPeripherals(
            withServices: [heartRateServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }
    
    func connect(to device: HeartRateDevice) {
        stopScanning()
        
        guard let peripheral = discoveredDevices.first(where: { $0.id == device.id })?.peripheral else {
            errorMessage = NSLocalizedString("bluetooth.device_not_found",
                                             value: "Dispositivo non trovato",
                                             comment: "Device not found error")
            return
        }
        
        connectionStatus = .connecting
        
        connectionTimer?.invalidate()
        connectionTimer = Timer.scheduledTimer(
            timeInterval: connectionTimeout,
            target: self,
            selector: #selector(handleConnectionTimeoutTimer(_:)),
            userInfo: peripheral.identifier,   // passiamo solo l'UUID
            repeats: false
        )
        
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
}

// MARK: - CBCentralManagerDelegate
extension BluetoothHeartRateManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            errorMessage = nil
        case .poweredOff:
            errorMessage = "Bluetooth è spento"
            isConnected = false
            connectionStatus = .disconnected
        case .unauthorized:
            errorMessage = "Permessi Bluetooth non concessi"
        case .unsupported:
            errorMessage = "Bluetooth non supportato"
        default:
            errorMessage = "Bluetooth non disponibile"
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        // A questo punto CoreBluetooth ci ha già filtrato SOLO dispositivi con Heart Rate Service
        // (grazie a withServices: [heartRateServiceUUID]).
        
        // Evita duplicati
        if !discoveredDevices.contains(where: { $0.id == peripheral.identifier }) {
            let name = peripheral.name ?? "Heart Rate Monitor"
            
            let device = HeartRateDevice(
                id: peripheral.identifier,
                name: name,
                rssi: RSSI.intValue,
                peripheral: peripheral
            )
            discoveredDevices.append(device)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        connectionTimer?.invalidate()
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        connectionStatus = .connected
        isConnected = true
        errorMessage = nil
        
        peripheral.discoverServices([heartRateServiceUUID])
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionTimer?.invalidate()
        
        connectionStatus = .disconnected
        isConnected = false
        errorMessage = NSLocalizedString(
            "bluetooth.connection_failed",
            value: "Connessione fallita: \(error?.localizedDescription ?? "Errore sconosciuto")",
            comment: "Bluetooth connection failed"
        )
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionTimer?.invalidate()
        
        connectedPeripheral = nil
        connectionStatus = .disconnected
        isConnected = false
        currentHeartRate = 0
        
        if let error = error {
            errorMessage = NSLocalizedString(
                "bluetooth.disconnected_with_error",
                value: "Disconnesso: \(error.localizedDescription)",
                comment: "Bluetooth disconnected with error"
            )
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothHeartRateManager: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        if let error = error {
            errorMessage = "Errore servizi: \(error.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services where service.uuid == heartRateServiceUUID {
            peripheral.discoverCharacteristics([heartRateCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error = error {
            errorMessage = "Errore caratteristiche: \(error.localizedDescription)"
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics where characteristic.uuid == heartRateCharacteristicUUID {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error = error {
            errorMessage = "Errore lettura: \(error.localizedDescription)"
            return
        }
        
        guard characteristic.uuid == heartRateCharacteristicUUID,
              let data = characteristic.value else { return }
        
        let heartRate = parseHeartRate(from: data)
        currentHeartRate = heartRate
    }
    
    // Parse Heart Rate secondo lo standard Bluetooth
    private func parseHeartRate(from data: Data) -> Int {
        var bytes = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &bytes, count: data.count)
        
        guard !bytes.isEmpty else { return 0 }
        
        let firstByte = bytes[0]
        let isUInt16 = (firstByte & 0x01) == 1
        
        if isUInt16 && bytes.count >= 3 {
            return Int(UInt16(bytes[1]) | (UInt16(bytes[2]) << 8))
        } else if bytes.count >= 2 {
            return Int(bytes[1])
        }
        
        return 0
    }
    
    private func handleConnectionTimeout(_ peripheral: CBPeripheral) {
        // Se nel frattempo si è connesso/disconnesso, non fare nulla
        guard connectionStatus == .connecting else { return }
        
        centralManager.cancelPeripheralConnection(peripheral)
        connectionStatus = .disconnected
        isConnected = false
        
        errorMessage = NSLocalizedString(
            "bluetooth.connection_timeout",
            value: "Timeout di connessione",
            comment: "Bluetooth connection timeout error"
        )
    }
    
    @objc private func handleConnectionTimeoutTimer(_ timer: Timer) {
        // Siamo sul main runloop → ok per UI / stato
        guard connectionStatus == .connecting else { return }
        
        guard
            let deviceID = timer.userInfo as? UUID,
            let peripheral = discoveredDevices.first(where: { $0.id == deviceID })?.peripheral
        else {
            return
        }
        
        centralManager.cancelPeripheralConnection(peripheral)
        connectionStatus = .disconnected
        isConnected = false
        
        errorMessage = NSLocalizedString(
            "bluetooth.connection_timeout",
            value: "Timeout di connessione",
            comment: "Bluetooth connection timeout error"
        )
    }

}

// MARK: - Supporting Types
struct HeartRateDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
    fileprivate let peripheral: CBPeripheral
    
    var signalStrength: String {
        switch rssi {
        case -50...0: return "Eccellente"
        case -70 ..< -50: return "Buono"
        case -90 ..< -70: return "Discreto"
        default: return "Debole"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HeartRateDevice, rhs: HeartRateDevice) -> Bool {
        lhs.id == rhs.id
    }
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    
    var description: String {
        switch self {
        case .disconnected:
            return NSLocalizedString(
                "connection.disconnected",
                value: "Disconnesso",
                comment: "Connection state: disconnected"
            )
        case .connecting:
            return NSLocalizedString(
                "connection.connecting",
                value: "Connessione in corso...",
                comment: "Connection state: connecting"
            )
        case .connected:
            return NSLocalizedString(
                "connection.connected",
                value: "Connesso",
                comment: "Connection state: connected"
            )
        }
    }
}


extension CBManagerState {
    var description: String {
        switch self {
        case .unknown:     return "unknown"
        case .resetting:   return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized:return "unauthorized"
        case .poweredOff:  return "poweredOff"
        case .poweredOn:   return "poweredOn"
        @unknown default:  return "unknown state"
        }
    }
}
