import HealthKit
import Foundation

@MainActor
final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
    ]
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        isAuthorized = true
    }
    
    func fetchUserData() async throws -> (weight: Double?, height: Double?, age: Int?, gender: Gender?) {
        // Peso
        let weight = try await fetchMostRecentSample(for: .bodyMass)
        let weightInKg = weight?.doubleValue(for: .gramUnit(with: .kilo))
        
        // Altezza
        let height = try await fetchMostRecentSample(for: .height)
        let heightInCm = height?.doubleValue(for: .meterUnit(with: .centi))
        
        // Età - FIX: gestiamo il doppio optional correttamente
        let dateOfBirth = try? healthStore.dateOfBirthComponents()
        let age: Int? = {
            guard let birthDate = dateOfBirth?.date else { return nil }
            let components = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
            return components.year
        }()
        
        // Sesso
        let biologicalSex = try? healthStore.biologicalSex()
        let gender: Gender? = {
            switch biologicalSex?.biologicalSex {
            case .male: return .male
            case .female: return .female
            default: return .other
            }
        }()
        
        return (weightInKg, heightInCm, age, gender)
    }
    
    private func fetchMostRecentSample(for identifier: HKQuantityTypeIdentifier) async throws -> HKQuantity? {
        let type = HKQuantityType.quantityType(forIdentifier: identifier)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // FIX: rimuoviamo la query non utilizzata
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let quantity = (samples?.first as? HKQuantitySample)?.quantity
                continuation.resume(returning: quantity)
            }
            
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: Error {
    case notAvailable
    case authorizationFailed
}
