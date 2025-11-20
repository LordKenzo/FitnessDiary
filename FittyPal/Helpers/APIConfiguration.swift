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
            #if DEBUG
            print("✅ API Key loaded from Config.plist: \(key.prefix(10))...")
            #endif
            return key
        }

        #if DEBUG
        print("⚠️ Config.plist not found in bundle, using placeholder")
        #endif

        // Fallback to placeholder (will show error in app)
        return "YOUR_WEATHER_API_KEY_HERE"
    }()

    static let weatherAPIBaseURL = "https://api.weatherapi.com/v1"

    // MARK: - Helper Methods

    private static func loadFromConfigPlist(key: String) -> String? {
        #if DEBUG
        print("🔍 Looking for Config.plist in bundle...")
        print("   Bundle path: \(Bundle.main.bundlePath)")
        #endif

        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            #if DEBUG
            print("❌ Config.plist not found in bundle")
            print("   Available resources: \(Bundle.main.paths(forResourcesOfType: "plist", inDirectory: nil))")
            #endif
            return nil
        }

        #if DEBUG
        print("✅ Found Config.plist at: \(path)")
        #endif

        guard let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            #if DEBUG
            print("❌ Failed to parse Config.plist")
            #endif
            return nil
        }

        guard let value = config[key] as? String else {
            #if DEBUG
            print("❌ Key '\(key)' not found in Config.plist")
            print("   Available keys: \(config.keys)")
            #endif
            return nil
        }

        return value
    }

    /// Check if API keys are properly configured
    static var isWeatherAPIConfigured: Bool {
        return weatherAPIKey != "YOUR_WEATHER_API_KEY_HERE" && !weatherAPIKey.isEmpty
    }
}
