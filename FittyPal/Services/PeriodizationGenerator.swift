//
//  PeriodizationGenerator.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation

/// Servizio per generare struttura vuota di periodizzazione
/// RF2: Genera automaticamente mesocicli, microcicli e giorni
class PeriodizationGenerator {

    // MARK: - Generazione Mesocicli

    /// Genera mesocicli per un piano (struttura vuota)
    /// - Parameters:
    ///   - plan: Piano di periodizzazione
    ///   - mesocycleDurationWeeks: Durata tipica di un mesociclo in settimane (default 4)
    /// - Returns: Array di mesocicli generati
    func generateMesocycles(
        for plan: PeriodizationPlan,
        mesocycleDurationWeeks: Int = 4
    ) -> [Mesocycle] {
        switch plan.periodizationModel {
        case .linear:
            return generateLinearMesocycles(plan: plan, durationWeeks: mesocycleDurationWeeks)
        case .block:
            return generateBlockMesocycles(plan: plan, durationWeeks: mesocycleDurationWeeks)
        case .undulating:
            return generateUndulatingMesocycles(plan: plan, durationWeeks: mesocycleDurationWeeks)
        }
    }

    // MARK: - Modello Lineare

    /// Periodizzazione LINEARE: Accumulo → Intensificazione → Trasformazione
    private func generateLinearMesocycles(
        plan: PeriodizationPlan,
        durationWeeks: Int
    ) -> [Mesocycle] {
        let totalWeeks = plan.durationInWeeks
        let mesocycleCount = max(1, Int(ceil(Double(totalWeeks) / Double(durationWeeks))))

        var mesocycles: [Mesocycle] = []
        var currentDate = plan.startDate

        // Progressione lineare: Accumulo → Intensificazione → Trasformazione (ciclica)
        let phaseProgression: [PhaseType] = [.accumulation, .intensification, .transformation]

        for i in 0..<mesocycleCount {
            let phaseIndex = i % phaseProgression.count
            let phaseType = phaseProgression[phaseIndex]

            // Calcola date del mesociclo
            let weeksInThisMeso = min(durationWeeks, totalWeeks - (i * durationWeeks))
            guard let endDate = Calendar.current.date(byAdding: .weekOfYear, value: weeksInThisMeso, to: currentDate) else {
                continue
            }

            let mesocycle = Mesocycle(
                order: i + 1,
                name: "Mesociclo \(i + 1) - \(phaseType.rawValue)",
                startDate: currentDate,
                endDate: endDate,
                phaseType: phaseType,
                focusStrengthProfile: plan.primaryStrengthProfile,
                loadWeeks: max(1, weeksInThisMeso - 1), // RF3: almeno 1 settimana scarico
                deloadWeeks: 1,
                plan: plan
            )

            mesocycles.append(mesocycle)
            currentDate = endDate
        }

        return mesocycles
    }

    // MARK: - Modello a Blocchi

    /// Periodizzazione A BLOCCHI: ogni mesociclo focus su un profilo di forza
    private func generateBlockMesocycles(
        plan: PeriodizationPlan,
        durationWeeks: Int
    ) -> [Mesocycle] {
        let totalWeeks = plan.durationInWeeks
        let mesocycleCount = max(1, Int(ceil(Double(totalWeeks) / Double(durationWeeks))))

        var mesocycles: [Mesocycle] = []
        var currentDate = plan.startDate

        // Alterna tra profilo primario e secondario
        let profiles: [StrengthExpressionType] = [
            plan.primaryStrengthProfile,
            plan.secondaryStrengthProfile ?? plan.primaryStrengthProfile
        ]

        for i in 0..<mesocycleCount {
            let profileIndex = i % profiles.count
            let focusProfile = profiles[profileIndex]

            // Fase del blocco (accumulo per blocchi di volume, intensificazione per forza)
            let phaseType: PhaseType = focusProfile == .hypertrophy ? .accumulation : .intensification

            let weeksInThisMeso = min(durationWeeks, totalWeeks - (i * durationWeeks))
            guard let endDate = Calendar.current.date(byAdding: .weekOfYear, value: weeksInThisMeso, to: currentDate) else {
                continue
            }

            let mesocycle = Mesocycle(
                order: i + 1,
                name: "Blocco \(i + 1) - \(focusProfile.rawValue)",
                startDate: currentDate,
                endDate: endDate,
                phaseType: phaseType,
                focusStrengthProfile: focusProfile,
                loadWeeks: max(1, weeksInThisMeso - 1),
                deloadWeeks: 1,
                plan: plan
            )

            mesocycles.append(mesocycle)
            currentDate = endDate
        }

        return mesocycles
    }

    // MARK: - Modello Ondulato

    /// Periodizzazione ONDULATA: variazione di volume/intensità
    private func generateUndulatingMesocycles(
        plan: PeriodizationPlan,
        durationWeeks: Int
    ) -> [Mesocycle] {
        let totalWeeks = plan.durationInWeeks
        let mesocycleCount = max(1, Int(ceil(Double(totalWeeks) / Double(durationWeeks))))

        var mesocycles: [Mesocycle] = []
        var currentDate = plan.startDate

        // Ondulazione: alterna fasi di accumulo e intensificazione
        let phaseProgression: [PhaseType] = [.accumulation, .intensification]

        for i in 0..<mesocycleCount {
            let phaseIndex = i % phaseProgression.count
            let phaseType = phaseProgression[phaseIndex]

            let weeksInThisMeso = min(durationWeeks, totalWeeks - (i * durationWeeks))
            guard let endDate = Calendar.current.date(byAdding: .weekOfYear, value: weeksInThisMeso, to: currentDate) else {
                continue
            }

            let mesocycle = Mesocycle(
                order: i + 1,
                name: "Mesociclo \(i + 1) - \(phaseType.rawValue)",
                startDate: currentDate,
                endDate: endDate,
                phaseType: phaseType,
                focusStrengthProfile: plan.primaryStrengthProfile,
                loadWeeks: max(1, weeksInThisMeso - 1),
                deloadWeeks: 1,
                plan: plan
            )

            mesocycles.append(mesocycle)
            currentDate = endDate
        }

        return mesocycles
    }

    // MARK: - Generazione Microcicli

    /// Genera microcicli (settimane) per un mesociclo
    /// RF3: Include settimane di scarico con loadLevel = LOW
    func generateMicrocycles(for mesocycle: Mesocycle, startWeekNumber: Int = 1) -> [Microcycle] {
        var microcycles: [Microcycle] = []
        var currentDate = mesocycle.startDate
        var weekNumber = startWeekNumber

        let totalWeeks = mesocycle.durationInWeeks

        for i in 0..<totalWeeks {
            // Determina se è settimana di scarico (ultime deloadWeeks settimane)
            let isDeloadWeek = i >= mesocycle.loadWeeks

            let loadLevel: LoadLevel = isDeloadWeek ? .low : (i % 2 == 0 ? .high : .medium)

            guard let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) else {
                continue
            }

            let microcycle = Microcycle(
                order: i + 1,
                weekNumber: weekNumber,
                startDate: currentDate,
                endDate: endDate,
                loadLevel: loadLevel,
                mesocycle: mesocycle
            )

            microcycles.append(microcycle)
            currentDate = endDate
            weekNumber += 1
        }

        return microcycles
    }

    // MARK: - Generazione Giorni

    /// Genera giorni di allenamento per un microciclo
    /// - Parameters:
    ///   - microcycle: Settimana di allenamento
    ///   - weeklyFrequency: Numero allenamenti/settimana
    ///   - trainingDays: Giorni della settimana in cui allenarsi (1-7, default: lun/mer/ven = [2,4,6])
    /// - Returns: Array di TrainingDay
    func generateTrainingDays(
        for microcycle: Microcycle,
        weeklyFrequency: Int,
        trainingDays: [Int]? = nil
    ) -> [TrainingDay] {
        var days: [TrainingDay] = []

        // Usa pattern predefinito se non specificato
        let selectedDays = trainingDays ?? defaultTrainingDaysPattern(frequency: weeklyFrequency)

        for dayOfWeek in 1...7 {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOfWeek - 1, to: microcycle.startDate) else {
                continue
            }

            let isTrainingDay = selectedDays.contains(dayOfWeek)

            let trainingDay = TrainingDay(
                date: date,
                dayOfWeek: dayOfWeek,
                isRestDay: !isTrainingDay,
                microcycle: microcycle
            )

            days.append(trainingDay)
        }

        return days
    }

    /// Pattern predefiniti di giorni di allenamento in base alla frequenza
    private func defaultTrainingDaysPattern(frequency: Int) -> [Int] {
        switch frequency {
        case 1:
            return [2] // Lunedì
        case 2:
            return [2, 5] // Lunedì, Giovedì
        case 3:
            return [2, 4, 6] // Lunedì, Mercoledì, Venerdì
        case 4:
            return [2, 3, 5, 6] // Lun, Mar, Gio, Ven
        case 5:
            return [2, 3, 4, 5, 6] // Lun-Ven
        case 6:
            return [2, 3, 4, 5, 6, 7] // Lun-Sab
        case 7:
            return [1, 2, 3, 4, 5, 6, 7] // Tutti i giorni
        default:
            return [2, 4, 6] // Default 3x/settimana
        }
    }

    // MARK: - Generazione Piano Completo

    /// Genera piano completo con mesocicli, microcicli e giorni
    func generateCompletePlan(_ plan: PeriodizationPlan) -> PeriodizationPlan {
        // 1. Genera mesocicli
        let mesocycles = generateMesocycles(for: plan)
        plan.mesocycles = mesocycles

        var weekCounter = 1

        // 2. Per ogni mesociclo, genera microcicli
        for mesocycle in mesocycles {
            let microcycles = generateMicrocycles(for: mesocycle, startWeekNumber: weekCounter)
            mesocycle.microcycles = microcycles
            weekCounter += microcycles.count

            // 3. Per ogni microciclo, genera giorni
            for microcycle in microcycles {
                // Usa i giorni configurati nel piano se disponibili, altrimenti usa il pattern di default
                let trainingDays = plan.hasTrainingDaysConfigured ? plan.trainingDaysRaw : nil
                let days = generateTrainingDays(for: microcycle, weeklyFrequency: plan.weeklyFrequency, trainingDays: trainingDays)
                microcycle.trainingDays = days
            }
        }

        return plan
    }
}
