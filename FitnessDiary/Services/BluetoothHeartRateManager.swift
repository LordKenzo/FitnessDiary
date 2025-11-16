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
            errorMessage = "Dispositivo non trovato"
            return
        }
        
        connectionStatus = .connecting
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
        connectedPeripheral = peripheral
        peripheral.delegate = self
        connectionStatus = .connected
        isConnected = true
        errorMessage = nil
        
        // Scopri i servizi (in particolare Heart Rate)
        peripheral.discoverServices([heartRateServiceUUID])
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionStatus = .disconnected
        isConnected = false
        errorMessage = "Connessione fallita: \(error?.localizedDescription ?? "Errore sconosciuto")"
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectedPeripheral = nil
        connectionStatus = .disconnected
        isConnected = false
        currentHeartRate = 0
        
        if let error = error {
            errorMessage = "Disconnesso: \(error.localizedDescription)"
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
        case .disconnected: return "Disconnesso"
        case .connecting:   return "Connessione in corso..."
        case .connected:    return "Connesso"
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
