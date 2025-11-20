//
//  PeriodizationService.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftData

/// Servizio principale per logica business di periodizzazione
/// RF4: Determinazione del contesto corrente di allenamento
/// RF5: Integrazione con le schede di allenamento
class PeriodizationService {

    private let modelContext: ModelContext
    private let progressionCalculator: LoadProgressionCalculator

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.progressionCalculator = LoadProgressionCalculator()
    }

    // MARK: - RF4: Contesto Corrente

    /// Ottieni il contesto di allenamento corrente per un utente/cliente
    /// RF4: Dato userId e data, restituisce contesto corrente
    /// - Parameters:
    ///   - userId: ID UserProfile (opzionale)
    ///   - clientId: ID Client (opzionale)
    ///   - date: Data di riferimento (default oggi)
    /// - Returns: Contesto di allenamento corrente o nil
    func getCurrentTrainingContext(
        userId: UUID? = nil,
        clientId: UUID? = nil,
        date: Date = Date()
    ) -> TrainingContext? {
        // 1. Trova piano attivo
        guard let activePlan = findActivePlan(userId: userId, clientId: clientId, date: date) else {
            return nil
        }

        // 2. Trova mesociclo corrente
        guard let currentMeso = findCurrentMesocycle(in: activePlan, date: date) else {
            return nil
        }

        // 3. Trova microciclo (settimana) corrente
        guard let currentMicro = findCurrentMicrocycle(in: currentMeso, date: date) else {
            return nil
        }

        // 4. Trova giorno corrente (opzionale)
        let currentDay = findCurrentTrainingDay(in: currentMicro, date: date)

        // 5. Costruisci contesto
        return TrainingContext(
            plan: activePlan,
            mesocycle: currentMeso,
            microcycle: currentMicro,
            trainingDay: currentDay,
            focusStrengthProfile: currentMeso.focusStrengthProfile,
            loadLevel: currentMicro.loadLevel,
            intensityFactor: currentMicro.intensityFactor,
            volumeFactor: currentMicro.volumeFactor
        )
    }

    /// Trova il piano attivo per utente/cliente
    private func findActivePlan(
        userId: UUID?,
        clientId: UUID?,
        date: Date
    ) -> PeriodizationPlan? {
        let descriptor = FetchDescriptor<PeriodizationPlan>(
            predicate: #Predicate { plan in
                plan.isActive &&
                plan.startDate <= date &&
                plan.endDate >= date
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let plans = try? modelContext.fetch(descriptor) else {
            return nil
        }

        // Filtra per userId o clientId se specificati
        return plans.first { plan in
            if let userId = userId {
                return plan.userProfile?.id == userId
            } else if let clientId = clientId {
                return plan.client?.id == clientId
            }
            return true
        }
    }

    /// Trova mesociclo corrente nel piano
    private func findCurrentMesocycle(in plan: PeriodizationPlan, date: Date) -> Mesocycle? {
        return plan.mesocycles.first { meso in
            date >= meso.startDate && date <= meso.endDate
        }
    }

    /// Trova microciclo corrente nel mesociclo
    private func findCurrentMicrocycle(in mesocycle: Mesocycle, date: Date) -> Microcycle? {
        return mesocycle.microcycles.first { micro in
            date >= micro.startDate && date <= micro.endDate
        }
    }

    /// Trova giorno corrente nel microciclo
    private func findCurrentTrainingDay(in microcycle: Microcycle, date: Date) -> TrainingDay? {
        return microcycle.trainingDays.first { day in
            Calendar.current.isDate(day.date, inSameDayAs: date)
        }
    }

    // MARK: - RF5: Integrazione con Schede

    /// Applica il contesto di periodizzazione a una scheda
    /// RF5: Modula intensità e volume in base al contesto corrente
    /// - Parameters:
    ///   - workoutCard: Scheda base da modulare
    ///   - context: Contesto di periodizzazione
    /// - Returns: Scheda modulata (copia)
    func applyPeriodizationContext(
        to workoutCard: WorkoutCard,
        with context: TrainingContext
    ) -> WorkoutCard {
        // Per ora restituisce la scheda originale
        // L'applicazione vera richiede clonazione e modifica dei WorkoutSet
        // TODO: Implementare clonazione e modulazione effettiva
        return workoutCard
    }

    /// Calcola il carico modulato per un set in base al contesto
    /// - Parameters:
    ///   - basePercentage: Percentuale 1RM base
    ///   - context: Contesto di periodizzazione
    ///   - oneRM: 1RM dell'esercizio (opzionale)
    /// - Returns: Tupla (percentuale modulata, kg se 1RM fornito)
    func calculateModulatedLoad(
        basePercentage: Double,
        context: TrainingContext,
        oneRM: Double? = nil
    ) -> (percentage: Double, kg: Double?) {
        return progressionCalculator.calculateProgressiveLoadPercentage(
            basePercentage: basePercentage,
            for: context.microcycle,
            in: context.mesocycle,
            oneRM: oneRM
        )
    }

    // MARK: - Gestione Template

    /// Crea un piano da template
    /// - Parameters:
    ///   - template: Template di periodizzazione
    ///   - startDate: Data di inizio
    ///   - userProfile: Profilo utente (opzionale)
    ///   - client: Cliente (opzionale)
    /// - Returns: Piano generato
    func createPlanFromTemplate(
        _ template: PeriodizationTemplate,
        startDate: Date,
        userProfile: UserProfile? = nil,
        client: Client? = nil
    ) -> PeriodizationPlan {
        let endDate = Calendar.current.date(
            byAdding: .weekOfYear,
            value: template.recommendedDurationWeeks,
            to: startDate
        ) ?? startDate

        let plan = PeriodizationPlan(
            name: template.name,
            startDate: startDate,
            endDate: endDate,
            periodizationModel: template.periodizationModel,
            primaryStrengthProfile: template.primaryStrengthProfile,
            secondaryStrengthProfile: template.secondaryStrengthProfile,
            weeklyFrequency: template.weeklyFrequency,
            notes: template.periodizationDescription,
            templateId: template.id,
            userProfile: userProfile,
            client: client
        )

        // Incrementa contatore uso template
        template.incrementUsage()

        return plan
    }

    /// Salva un piano come template
    /// - Parameter plan: Piano da salvare come template
    /// - Returns: Template creato
    func savePlanAsTemplate(_ plan: PeriodizationPlan, name: String, description: String? = nil) -> PeriodizationTemplate {
        let template = PeriodizationTemplate(
            name: name,
            description: description,
            periodizationModel: plan.periodizationModel,
            primaryStrengthProfile: plan.primaryStrengthProfile,
            secondaryStrengthProfile: plan.secondaryStrengthProfile,
            weeklyFrequency: plan.weeklyFrequency,
            recommendedDurationWeeks: plan.durationInWeeks
        )

        modelContext.insert(template)

        return template
    }
}

// MARK: - TrainingContext

/// Contesto di allenamento corrente (RF4)
struct TrainingContext {
    let plan: PeriodizationPlan
    let mesocycle: Mesocycle
    let microcycle: Microcycle
    let trainingDay: TrainingDay?

    // Parametri chiave per RF5
    let focusStrengthProfile: StrengthExpressionType
    let loadLevel: LoadLevel
    let intensityFactor: Double
    let volumeFactor: Double

    /// Descrizione testuale del contesto
    var description: String {
        """
        Piano: \(plan.name)
        Mesociclo: \(mesocycle.name) (\(mesocycle.phaseType.rawValue))
        Settimana: \(microcycle.weekNumber) - \(loadLevel.rawValue)
        Focus: \(focusStrengthProfile.rawValue)
        Intensità: \(Int(intensityFactor * 100))% | Volume: \(Int(volumeFactor * 100))%
        """
    }

    /// Verifica se è settimana di scarico
    var isDeloadWeek: Bool {
        microcycle.isDeloadWeek
    }
}
