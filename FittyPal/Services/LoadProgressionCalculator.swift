//
//  LoadProgressionCalculator.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation

/// Servizio per calcolare la progressione automatica dei carichi
/// RF4: Auto-progressione del carico tra settimane e gestione fase di scarico
class LoadProgressionCalculator {

    // MARK: - Calcolo Carico con Progressione

    /// Calcola il carico progressivo per una settimana specifica
    /// - Parameters:
    ///   - baseLoad: Carico base (percentuale 1RM o kg)
    ///   - microcycle: Settimana corrente
    ///   - mesocycle: Mesociclo di appartenenza
    /// - Returns: Carico modulato in base alla progressione e al contesto
    func calculateProgressiveLoad(
        baseLoad: Double,
        for microcycle: Microcycle,
        in mesocycle: Mesocycle
    ) -> Double {
        // Se è settimana di scarico, applica riduzione
        if microcycle.isDeloadWeek {
            return baseLoad * microcycle.intensityFactor
        }

        // Calcola progressione basata sull'ordine della settimana nel mesociclo
        let weekInMeso = microcycle.order
        let progressionIncrement = microcycle.loadProgressionPercentage * Double(weekInMeso - 1)

        // Applica progressione e fattore di intensità
        let progressedLoad = baseLoad * (1.0 + progressionIncrement)
        let modulatedLoad = progressedLoad * microcycle.intensityFactor

        return modulatedLoad
    }

    /// Calcola il carico progressivo in percentuale di 1RM
    /// - Parameters:
    ///   - basePercentage: Percentuale 1RM base (es. 75.0)
    ///   - microcycle: Settimana corrente
    ///   - mesocycle: Mesociclo di appartenenza
    ///   - oneRM: 1RM dell'esercizio (opzionale, per calcolare kg)
    /// - Returns: Tupla (percentuale modulata, kg se 1RM fornito)
    func calculateProgressiveLoadPercentage(
        basePercentage: Double,
        for microcycle: Microcycle,
        in mesocycle: Mesocycle,
        oneRM: Double? = nil
    ) -> (percentage: Double, kg: Double?) {
        let modulatedPercentage = calculateProgressiveLoad(
            baseLoad: basePercentage,
            for: microcycle,
            in: mesocycle
        )

        // Limita al 100% (non si può superare il massimale)
        let cappedPercentage = min(modulatedPercentage, 100.0)

        let kg: Double? = if let oneRM = oneRM {
            (cappedPercentage / 100.0) * oneRM
        } else {
            nil
        }

        return (cappedPercentage, kg)
    }

    // MARK: - Modulazione Volume

    /// Calcola il numero di serie modulato in base al contesto
    /// - Parameters:
    ///   - baseSets: Numero serie base
    ///   - microcycle: Settimana corrente
    /// - Returns: Numero serie modulato (arrotondato)
    func calculateModulatedSets(baseSets: Int, for microcycle: Microcycle) -> Int {
        let modulatedSets = Double(baseSets) * microcycle.volumeFactor
        return max(1, Int(round(modulatedSets)))
    }

    /// Calcola il numero di ripetizioni modulato
    /// - Parameters:
    ///   - baseReps: Ripetizioni base
    ///   - microcycle: Settimana corrente
    /// - Returns: Ripetizioni modulate (arrotondate)
    func calculateModulatedReps(baseReps: Int, for microcycle: Microcycle) -> Int {
        let modulatedReps = Double(baseReps) * microcycle.volumeFactor
        return max(1, Int(round(modulatedReps)))
    }

    // MARK: - Pattern di Progressione

    /// Genera pattern di progressione per un mesociclo completo
    /// - Parameter mesocycle: Mesociclo per cui generare il pattern
    /// - Returns: Array di fattori di progressione per ogni settimana
    func generateProgressionPattern(for mesocycle: Mesocycle) -> [ProgressionWeek] {
        var pattern: [ProgressionWeek] = []

        for (index, microcycle) in mesocycle.sortedMicrocycles.enumerated() {
            let weekPattern = ProgressionWeek(
                weekNumber: index + 1,
                loadLevel: microcycle.loadLevel,
                intensityFactor: microcycle.intensityFactor,
                volumeFactor: microcycle.volumeFactor,
                loadProgressionPercentage: microcycle.loadProgressionPercentage,
                isDeload: microcycle.isDeloadWeek
            )

            pattern.append(weekPattern)
        }

        return pattern
    }

    // MARK: - Predizione Massimali

    /// Predice il nuovo 1RM in base alla progressione del mesociclo
    /// - Parameters:
    ///   - current1RM: 1RM corrente
    ///   - mesocycle: Mesociclo completato/in corso
    /// - Returns: 1RM stimato alla fine del mesociclo
    func predictNew1RM(current1RM: Double, after mesocycle: Mesocycle) -> Double {
        // Stima incremento basato sul tipo di fase
        let estimatedIncrease: Double = switch mesocycle.phaseType {
        case .accumulation:
            0.02 // +2% (volume alto, forza moderata)
        case .intensification:
            0.05 // +5% (intensità alta, guadagni di forza)
        case .transformation:
            0.03 // +3% (specifico, consolidamento)
        case .deload:
            0.0 // nessun incremento durante scarico
        }

        return current1RM * (1.0 + estimatedIncrease)
    }

    // MARK: - Validazione Progressione

    /// Verifica se la progressione proposta è sicura e realistica
    /// - Parameters:
    ///   - baseLoad: Carico base
    ///   - progressedLoad: Carico progressivo calcolato
    ///   - maxIncrementPercentage: Incremento massimo consentito per step (default 10%)
    /// - Returns: True se progressione è valida
    func isProgressionSafe(
        baseLoad: Double,
        progressedLoad: Double,
        maxIncrementPercentage: Double = 0.10
    ) -> Bool {
        let increment = (progressedLoad - baseLoad) / baseLoad

        return increment <= maxIncrementPercentage
    }
}

// MARK: - Supporting Types

/// Pattern di progressione per una settimana
struct ProgressionWeek {
    let weekNumber: Int
    let loadLevel: LoadLevel
    let intensityFactor: Double
    let volumeFactor: Double
    let loadProgressionPercentage: Double
    let isDeload: Bool

    /// Descrizione testuale del pattern
    var description: String {
        if isDeload {
            return "Settimana \(weekNumber): SCARICO (intensità \(Int(intensityFactor * 100))%, volume \(Int(volumeFactor * 100))%)"
        } else {
            return "Settimana \(weekNumber): \(loadLevel.rawValue) (intensità \(Int(intensityFactor * 100))%, volume \(Int(volumeFactor * 100))%, +\(Int(loadProgressionPercentage * 100))%)"
        }
    }
}
