//
//  Weekday.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import Foundation

/// Giorni della settimana per la pianificazione degli allenamenti
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    /// Nome completo del giorno in italiano
    var fullName: String {
        switch self {
        case .sunday: return "Domenica"
        case .monday: return "Lunedì"
        case .tuesday: return "Martedì"
        case .wednesday: return "Mercoledì"
        case .thursday: return "Giovedì"
        case .friday: return "Venerdì"
        case .saturday: return "Sabato"
        }
    }

    /// Nome breve (3 lettere)
    var shortName: String {
        switch self {
        case .sunday: return "Dom"
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mer"
        case .thursday: return "Gio"
        case .friday: return "Ven"
        case .saturday: return "Sab"
        }
    }

    /// Simbolo singola lettera
    var symbol: String {
        switch self {
        case .sunday: return "D"
        case .monday: return "L"
        case .tuesday: return "M"
        case .wednesday: return "M"
        case .thursday: return "G"
        case .friday: return "V"
        case .saturday: return "S"
        }
    }

    /// Compatibilità con Calendar.Component weekday (1 = Domenica)
    var calendarWeekday: Int {
        rawValue
    }

    /// Crea un Weekday da un Date
    static func from(date: Date) -> Weekday {
        let weekday = Calendar.current.component(.weekday, from: date)
        return Weekday(rawValue: weekday) ?? .monday
    }

    /// Trova la prossima occorrenza di questo giorno a partire da una data
    func next(after date: Date) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)

        var daysToAdd = self.rawValue - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }

    /// Ordine preferito per la settimana (inizia da lunedì)
    var weekOrder: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }

    /// Array ordinato con settimana che inizia da lunedì
    static var orderedFromMonday: [Weekday] {
        allCases.sorted { $0.weekOrder < $1.weekOrder }
    }
}
