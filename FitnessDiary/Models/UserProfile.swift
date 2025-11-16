import Foundation
import SwiftData
import SwiftUI

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var age: Int
    var gender: Gender
    var weight: Double // in kg
    var height: Double // in cm
    @Attribute(.externalStorage) var profileImageData: Data?
    
    // Zone cardio (5 zone) - % della frequenza cardiaca massima
    var zone1Max: Int // Recupero: 50-60%
    var zone2Max: Int // Endurance: 60-70%
    var zone3Max: Int // Tempo: 70-80%
    var zone4Max: Int // Soglia: 80-90%
    var zone5Max: Int // VO2 Max: 90-100%
    
    var maxHeartRate: Int // Calcolata o personalizzata
    
    init(
        id: UUID = UUID(),
        name: String = "",
        age: Int = 25,
        gender: Gender = .other,
        weight: Double = 70.0,
        height: Double = 170.0,
        profileImageData: Data? = nil,
        maxHeartRate: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.weight = weight
        self.height = height
        self.profileImageData = profileImageData
        
        // Calcola la frequenza cardiaca massima (formula: 220 - età)
        let calculatedMaxHR = maxHeartRate ?? (220 - age)
        self.maxHeartRate = calculatedMaxHR
        
        // Imposta le zone cardio di default usando la variabile locale
        self.zone1Max = Int(Double(calculatedMaxHR) * 0.60)
        self.zone2Max = Int(Double(calculatedMaxHR) * 0.70)
        self.zone3Max = Int(Double(calculatedMaxHR) * 0.80)
        self.zone4Max = Int(Double(calculatedMaxHR) * 0.90)
        self.zone5Max = calculatedMaxHR
    }
    
    var profileImage: UIImage? {
        get {
            guard let data = profileImageData else { return nil }
            return UIImage(data: data)
        }
        set {
            profileImageData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
    
    func updateHeartRateZones(maxHR: Int) {
        self.maxHeartRate = maxHR
        self.zone1Max = Int(Double(maxHR) * 0.60)
        self.zone2Max = Int(Double(maxHR) * 0.70)
        self.zone3Max = Int(Double(maxHR) * 0.80)
        self.zone4Max = Int(Double(maxHR) * 0.90)
        self.zone5Max = maxHR
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "Maschio"
    case female = "Femmina"
    case other = "Altro"
}
