//
//  CustomTrainingMethod.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData

/// Represents a custom training method defined by the user
@Model
final class CustomTrainingMethod: Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastModifiedAt: Date

    @Relationship(deleteRule: .cascade)
    var repConfigurations: [CustomRepConfiguration]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        lastModifiedAt: Date = Date(),
        repConfigurations: [CustomRepConfiguration] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
        self.repConfigurations = repConfigurations
    }

    /// Total number of reps in this custom method
    var totalReps: Int {
        repConfigurations.count
    }

    /// Returns a brief description of the method for display
    var methodDescription: String {
        guard !repConfigurations.isEmpty else { return "Nessuna configurazione" }

        let loadsDescription = repConfigurations.map { config in
            if config.loadPercentage > 0 {
                return "+\(Int(config.loadPercentage))%"
            } else if config.loadPercentage < 0 {
                return "\(Int(config.loadPercentage))%"
            } else {
                return "0%"
            }
        }.joined(separator: ", ")

        return "\(totalReps) reps: \(loadsDescription)"
    }
}

/// Configuration for a single repetition within a custom training method
@Model
final class CustomRepConfiguration: Identifiable {
    var id: UUID
    var repOrder: Int // Position of this rep (1-based)
    var loadPercentage: Double // Percentage relative to first rep (-50 to +100)
    var restAfterRep: TimeInterval // Rest after this rep in seconds (0-240)

    @Relationship(inverse: \CustomTrainingMethod.repConfigurations)
    var method: CustomTrainingMethod?

    init(
        id: UUID = UUID(),
        repOrder: Int,
        loadPercentage: Double = 0.0,
        restAfterRep: TimeInterval = 0.0
    ) {
        self.id = id
        self.repOrder = repOrder
        self.loadPercentage = loadPercentage
        self.restAfterRep = restAfterRep
    }

    /// Returns the actual load percentage to apply (100% + loadPercentage)
    var actualLoadPercentage: Double {
        100.0 + loadPercentage
    }

    /// Returns formatted load percentage for display
    var formattedLoadPercentage: String {
        if loadPercentage > 0 {
            return "+\(Int(loadPercentage))%"
        } else if loadPercentage < 0 {
            return "\(Int(loadPercentage))%"
        } else {
            return "0%"
        }
    }

    /// Returns formatted rest time for display
    var formattedRestTime: String {
        let seconds = Int(restAfterRep)
        if seconds == 0 {
            return "Nessuna pausa"
        } else if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
}
