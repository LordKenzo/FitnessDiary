import Foundation
import SwiftUI

enum BlockType: String, Codable, CaseIterable {
    case simple = "Esercizio Singolo"
    case method = "Con Metodo"
}

/// Tipo di validazione da applicare alla progressione dei carichi
enum LoadProgressionValidation {
    case none // Nessuna validazione
    case ascending // I pesi devono aumentare serie dopo serie
    case descending // I pesi devono diminuire serie dopo serie
    case constant // Tutte le serie devono avere lo stesso peso
}

enum MethodType: String, Codable, CaseIterable, Identifiable {
    case superset = "Superset"
    case triset = "Triset"
    case giantSet = "Giant Set"
    case dropset = "Dropset"
    case pyramidAscending = "Piramidale Crescente"
    case pyramidDescending = "Piramidale Decrescente"
    case contrastTraining = "Contrast Training"
    case complexTraining = "Complex Training"
    case rest_pause = "Rest-Pause"
    case cluster = "Cluster Set"
    case emom = "EMOM"
    case amrap = "AMRAP"
    case circuit = "Circuito"

    var id: String { rawValue }

    // Icona SF Symbol per ogni metodologia
    var icon: String {
        switch self {
        case .superset:
            return "arrow.left.arrow.right"
        case .triset:
            return "arrow.triangle.swap"
        case .giantSet:
            return "square.grid.3x3"
        case .dropset:
            return "arrow.down.to.line"
        case .pyramidAscending:
            return "arrow.up.forward"
        case .pyramidDescending:
            return "arrow.down.forward"
        case .contrastTraining:
            return "bolt.horizontal"
        case .complexTraining:
            return "link"
        case .rest_pause:
            return "pause.circle"
        case .cluster:
            return "circle.grid.3x3"
        case .emom:
            return "timer"
        case .amrap:
            return "infinity"
        case .circuit:
            return "arrow.triangle.turn.up.right.circle"
        }
    }

    // Colore associato alla metodologia
    var color: Color {
        switch self {
        case .superset:
            return .blue
        case .triset:
            return .cyan
        case .giantSet:
            return .indigo
        case .dropset:
            return .orange
        case .pyramidAscending:
            return .green
        case .pyramidDescending:
            return .mint
        case .contrastTraining:
            return .purple
        case .complexTraining:
            return .pink
        case .rest_pause:
            return .red
        case .cluster:
            return .yellow
        case .emom:
            return .teal
        case .amrap:
            return .brown
        case .circuit:
            return .gray
        }
    }

    // Numero minimo di esercizi richiesti
    var minExercises: Int {
        switch self {
        case .superset:
            return 2
        case .triset:
            return 3
        case .giantSet:
            return 4
        case .dropset, .pyramidAscending, .pyramidDescending, .rest_pause, .cluster:
            return 1
        case .contrastTraining, .complexTraining:
            return 2
        case .emom, .amrap, .circuit:
            return 1
        }
    }

    // Descrizione breve della metodologia
    var description: String {
        switch self {
        case .superset:
            return "Due esercizi eseguiti consecutivamente senza recupero"
        case .triset:
            return "Tre esercizi eseguiti consecutivamente senza recupero"
        case .giantSet:
            return "Quattro o più esercizi eseguiti consecutivamente"
        case .dropset:
            return "Serie scalate con riduzione progressiva del carico"
        case .pyramidAscending:
            return "Serie con aumento progressivo del carico"
        case .pyramidDescending:
            return "Serie con riduzione progressiva del carico"
        case .contrastTraining:
            return "Alternanza tra esercizi di forza massimale e potenza"
        case .complexTraining:
            return "Combinazione di esercizi complementari"
        case .rest_pause:
            return "Serie con pause brevi per massimizzare le ripetizioni"
        case .cluster:
            return "Serie frazionate con micro-pause tra le ripetizioni"
        case .emom:
            return "Every Minute On the Minute - ripetizioni ogni minuto"
        case .amrap:
            return "As Many Reps As Possible - massime ripetizioni nel tempo"
        case .circuit:
            return "Circuito di esercizi da ripetere"
        }
    }

    // Tipo di validazione da applicare alla progressione dei carichi
    var loadProgressionValidation: LoadProgressionValidation {
        switch self {
        case .dropset, .pyramidDescending:
            return .descending
        case .pyramidAscending:
            return .ascending
        case .rest_pause, .cluster:
            return .constant
        default:
            return .none
        }
    }
}
