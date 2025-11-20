//
//  PeriodizationModel.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation
import SwiftUI

/// Modello di periodizzazione dell'allenamento
enum PeriodizationModel: String, Codable, CaseIterable {
    case linear = "Lineare"
    case block = "A Blocchi"
    case undulating = "Ondulata"

    var description: String {
        switch self {
        case .linear:
            return "Progressione lineare: accumulo → intensificazione → trasformazione"
        case .block:
            return "Blocchi specializzati: ogni mesociclo focus su un profilo di forza"
        case .undulating:
            return "Variazione ondulata: alternanza di volume e intensità"
        }
    }

    var icon: String {
        switch self {
        case .linear:
            return "chart.line.uptrend.xyaxis"
        case .block:
            return "square.stack.3d.up"
        case .undulating:
            return "waveform"
        }
    }
}

/// Tipo di fase del mesociclo
enum PhaseType: String, Codable, CaseIterable {
    case accumulation = "Accumulo"
    case intensification = "Intensificazione"
    case transformation = "Trasformazione"
    case deload = "Scarico"

    var description: String {
        switch self {
        case .accumulation:
            return "Volume alto, intensità media - costruzione base"
        case .intensification:
            return "Volume medio, intensità alta - sviluppo forza"
        case .transformation:
            return "Volume specifico per obiettivo - picco prestazione"
        case .deload:
            return "Recupero attivo - riduzione carico per supercompensazione"
        }
    }

    var icon: String {
        switch self {
        case .accumulation:
            return "arrow.up.doc"
        case .intensification:
            return "bolt.fill"
        case .transformation:
            return "star.fill"
        case .deload:
            return "arrow.down.circle"
        }
    }

    var color: String {
        switch self {
        case .accumulation:
            return "blue"
        case .intensification:
            return "orange"
        case .transformation:
            return "purple"
        case .deload:
            return "green"
        }
    }
}

/// Livello di carico della settimana
enum LoadLevel: String, Codable, CaseIterable {
    case high = "Alto"
    case medium = "Medio"
    case low = "Scarico"

    var description: String {
        switch self {
        case .high:
            return "Carico alto - settimana di massimo stress"
        case .medium:
            return "Carico medio - settimana standard"
        case .low:
            return "Scarico - settimana di recupero"
        }
    }

    var icon: String {
        switch self {
        case .high:
            return "arrow.up.circle.fill"
        case .medium:
            return "arrow.left.arrow.right.circle"
        case .low:
            return "arrow.down.circle.fill"
        }
    }

    /// Fattore di intensità predefinito (modulabile)
    var defaultIntensityFactor: Double {
        switch self {
        case .high:
            return 1.15
        case .medium:
            return 1.0
        case .low:
            return 0.7
        }
    }

    /// Fattore di volume predefinito (modulabile)
    var defaultVolumeFactor: Double {
        switch self {
        case .high:
            return 1.2
        case .medium:
            return 1.0
        case .low:
            return 0.6
        }
    }
}

/// Tipo di split routine
enum SplitType: String, Codable, CaseIterable {
    case fullBody = "Full Body"
    case upperLower = "Upper/Lower"
    case pushPullLegs = "Push/Pull/Legs"
    case bodyPartSplit = "Body Part Split"
    case custom = "Custom"

    var description: String {
        switch self {
        case .fullBody:
            return "Allenamento total body - tutto il corpo ogni sessione"
        case .upperLower:
            return "Split upper/lower - parte superiore e inferiore separate"
        case .pushPullLegs:
            return "Push/Pull/Legs - spinta, trazione, gambe"
        case .bodyPartSplit:
            return "Split per gruppi muscolari - es. chest, back, legs..."
        case .custom:
            return "Split personalizzato"
        }
    }

    var icon: String {
        switch self {
        case .fullBody:
            return "figure.stand"
        case .upperLower:
            return "figure.arms.open"
        case .pushPullLegs:
            return "figure.walk"
        case .bodyPartSplit:
            return "figure.strengthtraining.traditional"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

// MARK: - SwiftUI Color Extensions

extension PhaseType {
    /// Colore SwiftUI per la fase
    var swiftUIColor: Color {
        switch self {
        case .accumulation:
            return .blue
        case .intensification:
            return .orange
        case .transformation:
            return .purple
        case .deload:
            return .green
        }
    }
}

extension LoadLevel {
    /// Colore SwiftUI per il livello di carico
    var swiftUIColor: Color {
        switch self {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
}
