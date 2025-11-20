//
//  ClassicMethodDetailView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI

struct ClassicMethodDetailView: View {
    let method: MethodType
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with icon
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(method.color.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: method.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(method.color)
                        )

                    Text(method.rawValue)
                        .font(.title.bold())

                    Text(method.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

                // Detailed description section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Come Funziona", icon: "info.circle.fill", color: method.color)

                    Text(detailedDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(AppTheme.cardBackground(for: colorScheme))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                // Characteristics section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Caratteristiche", icon: "checklist", color: method.color)

                    VStack(spacing: 8) {
                        CharacteristicRow(
                            icon: "dumbbell.fill",
                            title: "Esercizi richiesti",
                            value: exerciseRequirement
                        )

                        if let validation = validationDescription {
                            CharacteristicRow(
                                icon: "arrow.up.arrow.down",
                                title: "Progressione carico",
                                value: validation
                            )
                        }

                        CharacteristicRow(
                            icon: "timer",
                            title: "Recupero tra serie",
                            value: method.allowsRestBetweenSets ? "Consentito" : "Non previsto"
                        )
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                // Execution preview section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Esempio di Esecuzione", icon: "eye.fill", color: method.color)

                    executionPreview
                        .padding(16)
                        .background(AppTheme.cardBackground(for: colorScheme))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Properties

    private var detailedDescription: String {
        switch method {
        case .superset:
            return "Il Superset prevede l'esecuzione consecutiva di due esercizi senza recupero tra loro. Il recupero completo avviene solo dopo aver completato entrambi gli esercizi. Particolarmente efficace per aumentare l'intensità dell'allenamento e risparmiare tempo."

        case .triset:
            return "Il Triset è simile al Superset ma con tre esercizi consecutivi senza recupero. Dopo aver completato tutti e tre gli esercizi, segue il recupero completo. Ideale per allenamenti ad alta densità che coinvolgono più gruppi muscolari."

        case .giantSet:
            return "Il Giant Set prevede quattro o più esercizi eseguiti consecutivamente senza pause intermedie. Il recupero avviene solo dopo aver completato l'intera sequenza. Metodo avanzato per massimizzare il volume di lavoro e la fatica metabolica."

        case .dropset:
            return "Il Dropset è una singola serie estesa in cui, raggiunto il cedimento muscolare con un peso, si riduce immediatamente il carico (tipicamente del 20-25%) e si continua fino a un nuovo cedimento. Non c'è recupero tra le riduzioni di peso. Eccellente per l'ipertrofia muscolare."

        case .pyramidAscending:
            return "La Piramidale Crescente prevede l'aumento progressivo del carico serie dopo serie, con conseguente diminuzione delle ripetizioni. Ogni serie è seguita da recupero completo. Metodo ideale per sviluppare forza progressiva."

        case .pyramidDescending:
            return "La Piramidale Decrescente inizia con carichi alti e basse ripetizioni, per poi ridurre progressivamente il peso aumentando le ripetizioni. Recupero completo tra le serie. Ottima per combinare lavoro di forza e volume."

        case .contrastTraining:
            return "Il Contrast Training alterna esercizi di forza massimale (alto carico, basse reps) con esercizi di potenza esplosiva (carico moderato, massima velocità). L'alternanza sfrutta la post-activation potentiation per migliorare la potenza muscolare."

        case .complexTraining:
            return "Il Complex Training combina esercizi di forza con alto carico ed esercizi esplosivi o pliometrici a basso carico eseguiti alla massima velocità. L'obiettivo è trasferire i guadagni di forza in potenza esplosiva grazie all'effetto PAP."

        case .rest_pause:
            return "Il Rest-Pause prevede l'esecuzione di una serie fino al cedimento, seguita da pause brevi (10-20 secondi) per recuperare parzialmente e continuare con ulteriori mini-serie. Tutte le mini-serie devono essere eseguite con lo stesso carico. Metodo intenso per massimizzare le ripetizioni totali."

        case .cluster:
            return "Il Cluster Set fraziona una serie in cluster di ripetizioni separate da micro-pause (15-30 secondi). Il carico rimane costante per tutti i cluster. Le micro-pause permettono recupero parziale del sistema nervoso, consentendo di mantenere alta qualità esecutiva anche con carichi elevati."

        default:
            return method.description
        }
    }

    private var exerciseRequirement: String {
        if let max = method.maxExercises, max == method.minExercises {
            return "Esattamente \(method.minExercises)"
        } else if method.maxExercises != nil {
            return "\(method.minExercises)-\(method.maxExercises!) esercizi"
        } else if method.minExercises > 1 {
            return "Minimo \(method.minExercises) esercizi"
        } else {
            return "1 esercizio"
        }
    }

    private var validationDescription: String? {
        switch method.loadProgressionValidation {
        case .ascending:
            return "Crescente (peso aumenta)"
        case .descending:
            return "Decrescente (peso diminuisce)"
        case .constant:
            return "Costante (stesso peso)"
        case .none:
            return nil
        }
    }

    private var executionPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Esempio pratico")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(method.color)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(exampleSteps.enumerated()), id: \.offset) { index, step in
                    ExecutionStepRow(stepNumber: index + 1, step: step, color: method.color)
                }
            }

            if let note = executionNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var exampleSteps: [String] {
        switch method {
        case .superset:
            return [
                "Panca piana: 10 reps @ 80kg",
                "Rematore bilanciere: 10 reps @ 70kg",
                "Recupero: 90 secondi",
                "Ripeti per 3-4 serie totali"
            ]

        case .triset:
            return [
                "Squat: 8 reps @ 100kg",
                "Leg extension: 12 reps @ 40kg",
                "Leg curl: 12 reps @ 35kg",
                "Recupero: 120 secondi",
                "Ripeti per 3 serie totali"
            ]

        case .giantSet:
            return [
                "Trazioni: 10 reps",
                "Rematore manubri: 12 reps @ 30kg",
                "Pulley: 15 reps @ 50kg",
                "Face pull: 15 reps @ 20kg",
                "Recupero: 150 secondi",
                "Ripeti per 2-3 serie totali"
            ]

        case .dropset:
            return [
                "Leg press: 12 reps @ 200kg (cedimento)",
                "Riduci a 160kg: 8 reps (cedimento)",
                "Riduci a 120kg: 10 reps (cedimento)",
                "Fine della serie - recupero completo"
            ]

        case .pyramidAscending:
            return [
                "Serie 1: 12 reps @ 60kg - recupero 90s",
                "Serie 2: 10 reps @ 70kg - recupero 90s",
                "Serie 3: 8 reps @ 80kg - recupero 120s",
                "Serie 4: 6 reps @ 90kg - fine"
            ]

        case .pyramidDescending:
            return [
                "Serie 1: 6 reps @ 90kg - recupero 120s",
                "Serie 2: 8 reps @ 80kg - recupero 90s",
                "Serie 3: 10 reps @ 70kg - recupero 90s",
                "Serie 4: 12 reps @ 60kg - fine"
            ]

        case .contrastTraining:
            return [
                "Squat pesante: 5 reps @ 120kg",
                "Squat jump: 5 reps @ 40kg (esplosivo)",
                "Recupero: 180 secondi",
                "Ripeti per 4-5 serie totali"
            ]

        case .complexTraining:
            return [
                "Front squat: 6 reps @ 80kg",
                "Box jump: 6 salti esplosivi",
                "Recupero: 180 secondi",
                "Ripeti per 4 serie totali"
            ]

        case .rest_pause:
            return [
                "Serie iniziale: 8 reps @ 80kg (cedimento)",
                "Pausa: 15 secondi",
                "Mini-serie: 3 reps @ 80kg (stesso peso)",
                "Pausa: 15 secondi",
                "Mini-serie: 2 reps @ 80kg (stesso peso)",
                "Recupero completo: 180 secondi"
            ]

        case .cluster:
            return [
                "Cluster 1: 3 reps @ 90kg",
                "Micro-pausa: 20 secondi",
                "Cluster 2: 3 reps @ 90kg (stesso peso)",
                "Micro-pausa: 20 secondi",
                "Cluster 3: 3 reps @ 90kg (stesso peso)",
                "Recupero completo: 180 secondi"
            ]

        default:
            return []
        }
    }

    private var executionNote: String? {
        switch method {
        case .dropset:
            return "Preparare in anticipo i pesi ridotti per minimizzare i tempi di transizione."

        case .rest_pause:
            return "Il carico deve rimanere identico per tutta la sequenza (serie iniziale + mini-serie)."

        case .cluster:
            return "Le micro-pause permettono recupero neurale parziale mantenendo alta la qualità esecutiva."

        case .contrastTraining, .complexTraining:
            return "Il recupero ampio (3+ minuti) è essenziale per ottimizzare l'effetto PAP (Post-Activation Potentiation)."

        default:
            return nil
        }
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
        }
    }
}

private struct CharacteristicRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}

private struct ExecutionStepRow: View {
    let stepNumber: Int
    let step: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)

                Text("\(stepNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(color)
            }

            Text(step)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("Dropset") {
    NavigationStack {
        ClassicMethodDetailView(method: .dropset)
    }
}

#Preview("Cluster") {
    NavigationStack {
        ClassicMethodDetailView(method: .cluster)
    }
}

#Preview("Superset") {
    NavigationStack {
        ClassicMethodDetailView(method: .superset)
    }
}
