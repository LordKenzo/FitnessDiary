//
//  Client.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Client: Identifiable {
    var id: UUID
    var firstName: String
    var lastName: String

    // Foto profilo con external storage
    @Attribute(.externalStorage) var profileImageData: Data?

    // Dati opzionali
    var age: Int?
    var gender: Gender?
    var weight: Double?  // kg
    var height: Double?  // cm
    var medicalHistory: String?  // Anamnesi
    var gym: String?  // Palestra

    @Relationship(deleteRule: .cascade)
    var oneRepMaxRecords: [OneRepMax] // Record di 1RM per i Big 5

    // Computed property per nome completo
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    // Computed property per l'immagine
    var profileImage: UIImage? {
        get {
            guard let data = profileImageData else { return nil }
            return UIImage(data: data)
        }
        set {
            if let image = newValue {
                profileImageData = image.jpegData(compressionQuality: 0.8)
            } else {
                profileImageData = nil
            }
        }
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        profileImageData: Data? = nil,
        age: Int? = nil,
        gender: Gender? = nil,
        weight: Double? = nil,
        height: Double? = nil,
        medicalHistory: String? = nil,
        gym: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageData = profileImageData
        self.age = age
        self.gender = gender
        self.weight = weight
        self.height = height
        self.medicalHistory = medicalHistory
        self.gym = gym
        self.oneRepMaxRecords = []
    }

    /// Get the 1RM for a specific Big 5 exercise
    func getOneRepMax(for exercise: Big5Exercise) -> Double? {
        return oneRepMaxRecords.first(where: { $0.exercise == exercise })?.weight
    }
}
