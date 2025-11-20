//
//  APIConfiguration.swift
//  FittyPal
//
//  API Configuration Management
//

import Foundation

/// Configuration for external API services
/// ⚠️ IMPORTANT: Never commit actual API keys to version control
struct APIConfiguration {

    // MARK: - Weather API

    /// WeatherAPI.com API Key
    /// Get your free key at: https://www.weatherapi.com/signup.aspx
    /// ⚠️ DO NOT commit your actual key to git!
    static let weatherAPIKey: String = {
        // First, try to load from Config.plist (gitignored)
        if let key = loadFromConfigPlist(key: "WeatherAPIKey"), !key.isEmpty {
            return key
        }

        // Fallback to placeholder (will show error in app)
        return "YOUR_WEATHER_API_KEY_HERE"
    }()

    static let weatherAPIBaseURL = "https://api.weatherapi.com/v1"

    // MARK: - Helper Methods

    private static func loadFromConfigPlist(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return config[key] as? String
    }

    /// Check if API keys are properly configured
    static var isWeatherAPIConfigured: Bool {
        return weatherAPIKey != "YOUR_WEATHER_API_KEY_HERE" && !weatherAPIKey.isEmpty
    }
}
