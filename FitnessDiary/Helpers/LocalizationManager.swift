//
//  LocalizationManager.swift
//  FitnessDiary
//
//  Created by Claude
//

import Foundation
import SwiftUI

/// Supported languages in the app
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italiano"
        case .spanish: return "Español"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .italian: return "🇮🇹"
        case .spanish: return "🇪🇸"
        }
    }
}

/// Manager for handling app localization
@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        // Load saved language or use system default
        if let savedLanguageCode = UserDefaults.standard.string(forKey: "appLanguage"),
           let savedLanguage = AppLanguage(rawValue: savedLanguageCode) {
            self.currentLanguage = savedLanguage
        } else {
            // Detect system language
            let systemLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = AppLanguage(rawValue: systemLanguageCode) ?? .italian
        }
    }

    /// Change the app language
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    /// Get localized string for the current language
    func localizedString(_ key: String, comment: String = "") -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to Italian if bundle not found
            return NSLocalizedString(key, comment: comment)
        }

        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

/// Property wrapper for accessing localized strings with reactive updates
@propertyWrapper
@MainActor
struct Localized: DynamicProperty {
    @ObservedObject private var manager = LocalizationManager.shared

    private let key: String
    private let comment: String

    init(_ key: String, comment: String = "") {
        self.key = key
        self.comment = comment
    }

    var wrappedValue: String {
        manager.localizedString(key, comment: comment)
    }
}

/// Helper function for localized strings
@MainActor
func L(_ key: String, comment: String = "") -> String {
    LocalizationManager.shared.localizedString(key, comment: comment)
}

/// Extension to make Text views language-reactive
extension Text {
    @MainActor
    init(localized key: String, comment: String = "") {
        self.init(LocalizationManager.shared.localizedString(key, comment: comment))
    }
}
