//
//  HeartRateZone.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import Foundation
import SwiftUI

enum HeartRateZone: Int, CaseIterable {
    case zone1 = 1 // Recupero
    case zone2 = 2 // Endurance
    case zone3 = 3 // Tempo
    case zone4 = 4 // Soglia
    case zone5 = 5 // VO2 Max
    
    var name: String {
        switch self {
        case .zone1: return "Zona 1 - Recupero"
        case .zone2: return "Zona 2 - Endurance"
        case .zone3: return "Zona 3 - Tempo"
        case .zone4: return "Zona 4 - Soglia"
        case .zone5: return "Zona 5 - VO2 Max"
        }
    }
    
    var description: String {
        switch self {
        case .zone1: return "50-60% FCMax - Riscaldamento e recupero"
        case .zone2: return "60-70% FCMax - Resistenza aerobica"
        case .zone3: return "70-80% FCMax - Capacità aerobica"
        case .zone4: return "80-90% FCMax - Soglia anaerobica"
        case .zone5: return "90-100% FCMax - Massima intensità"
        }
    }
    
    var color: Color {
        switch self {
        case .zone1: return .blue
        case .zone2: return .green
        case .zone3: return .yellow
        case .zone4: return .orange
        case .zone5: return .red
        }
    }
    
    static func getZone(for heartRate: Int, profile: UserProfile) -> HeartRateZone {
        if heartRate <= profile.zone1Max {
            return .zone1
        } else if heartRate <= profile.zone2Max {
            return .zone2
        } else if heartRate <= profile.zone3Max {
            return .zone3
        } else if heartRate <= profile.zone4Max {
            return .zone4
        } else {
            return .zone5
        }
    }
}