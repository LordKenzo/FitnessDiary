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

// MARK: - Rep Grouping for Execution

/// Represents a group of consecutive reps with the same load and rest configuration
struct RepGroup: Identifiable {
    let id = UUID()
    let reps: [CustomRepConfiguration]
    let load: Double // Calculated load for this group
    let loadPercentage: Double // Percentage variation
    let restAfterGroup: TimeInterval // Rest after completing this group

    var firstRepNumber: Int {
        reps.first?.repOrder ?? 0
    }

    var lastRepNumber: Int {
        reps.last?.repOrder ?? 0
    }

    var repCount: Int {
        reps.count
    }

    var repRange: String {
        if repCount == 1 {
            return "Rep \(firstRepNumber)"
        }
        return "Rep \(firstRepNumber)-\(lastRepNumber)"
    }

    var formattedLoad: String {
        String(format: "%.1f", load)
    }

    var formattedLoadPercentage: String {
        if loadPercentage > 0 {
            return "+\(Int(loadPercentage))%"
        } else if loadPercentage < 0 {
            return "\(Int(loadPercentage))%"
        } else {
            return "0%"
        }
    }
}

// MARK: - Custom Method Extensions

extension CustomTrainingMethod {
    /// Create rep groups based on load and rest patterns for efficient execution
    func createRepGroups(baseLoad: Double) -> [RepGroup] {
        guard !repConfigurations.isEmpty else { return [] }

        let sortedConfigs = repConfigurations.sorted { $0.repOrder < $1.repOrder }
        var groups: [RepGroup] = []
        var currentGroupConfigs: [CustomRepConfiguration] = []
        var previousLoad: Double?
        var previousRest: TimeInterval?

        for config in sortedConfigs {
            let currentLoad = baseLoad * (config.actualLoadPercentage / 100.0)
            let currentRest = config.restAfterRep

            let shouldStartNewGroup = previousLoad != nil && (
                abs(currentLoad - (previousLoad ?? 0)) > 0.01 || // Allow small floating point differences
                currentRest != previousRest
            )

            if shouldStartNewGroup {
                // Close previous group
                if let firstConfig = currentGroupConfigs.first {
                    let groupLoad = baseLoad * (firstConfig.actualLoadPercentage / 100.0)
                    let groupRest = firstConfig.restAfterRep

                    groups.append(RepGroup(
                        reps: currentGroupConfigs,
                        load: groupLoad,
                        loadPercentage: firstConfig.loadPercentage,
                        restAfterGroup: groupRest
                    ))
                }
                currentGroupConfigs = []
            }

            currentGroupConfigs.append(config)
            previousLoad = currentLoad
            previousRest = currentRest
        }

        // Add last group
        if let firstConfig = currentGroupConfigs.first {
            let groupLoad = baseLoad * (firstConfig.actualLoadPercentage / 100.0)
            let groupRest = firstConfig.restAfterRep

            groups.append(RepGroup(
                reps: currentGroupConfigs,
                load: groupLoad,
                loadPercentage: firstConfig.loadPercentage,
                restAfterGroup: groupRest
            ))
        }

        return groups
    }

    /// Check if all reps have the same load (0% variation)
    var hasSameLoadAllReps: Bool {
        return repConfigurations.allSatisfy { $0.loadPercentage == 0 }
    }

    /// Check if any rep has rest time
    var hasRestBetweenReps: Bool {
        return repConfigurations.contains(where: { $0.restAfterRep > 0 })
    }

    /// Calculate load for a specific rep number
    func loadForRep(_ repNumber: Int, baseLoad: Double) -> Double {
        guard let config = repConfigurations.first(where: { $0.repOrder == repNumber }) else {
            return baseLoad
        }
        let multiplier = config.actualLoadPercentage / 100.0
        return baseLoad * multiplier
    }

    /// Get all loads for all reps given a base load
    func allLoads(baseLoad: Double) -> [Double] {
        return repConfigurations
            .sorted(by: { $0.repOrder < $1.repOrder })
            .map { config in
                let multiplier = config.actualLoadPercentage / 100.0
                return baseLoad * multiplier
            }
    }
}
