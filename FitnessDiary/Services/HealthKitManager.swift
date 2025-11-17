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
    
    /// Requests permission to read the manager's configured HealthKit data types.
    /// Sets `isAuthorized` to `true` if authorization is granted, `false` otherwise (retry-friendly).
    /// - Throws: `HealthKitError.notAvailable` if HealthKit data is not available on the device.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)

        // Verify actual authorization status for at least one key type (bodyMass)
        // Note: HealthKit doesn't throw on denial, we must check status explicitly
        let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let status = healthStore.authorizationStatus(for: bodyMassType)

        // sharingAuthorized means we can read the data
        if status == .sharingAuthorized {
            isAuthorized = true
        } else {
            isAuthorized = false
            // Note: .notDetermined means user hasn't decided yet or we can't determine
            // We don't throw in this case to allow retry
        }
    }
    
    /// Retrieves the user's most recent weight and height samples from HealthKit, computes age from date of birth, and maps biological sex to `Gender`.
    /// - Returns: A tuple with:
    ///   - weight: The most recent body mass in kilograms, or `nil` if unavailable.
    ///   - height: The most recent height in centimeters, or `nil` if unavailable.
    ///   - age: The user's age in years computed from date of birth, or `nil` if unavailable.
    ///   - gender: The user's mapped `Gender` (`.male`, `.female`, or `.other`), or `nil` if unavailable.
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
    
    /// Fetches the most recent quantity sample for the given HealthKit quantity identifier.
    /// - Parameter identifier: The `HKQuantityTypeIdentifier` to query (for example `.bodyMass` or `.height`).
    /// - Returns: The most recent `HKQuantity` for the requested type, or `nil` if no sample exists.
    /// - Throws: The error produced by the HealthKit query if the query fails.
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