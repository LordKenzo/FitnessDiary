//
//  WeatherService.swift
//  FittyPal
//
//  Service for fetching weather data from WeatherAPI.com
//

import Foundation
import CoreLocation

// MARK: - Weather Models

struct WeatherResponse: Codable {
    let location: WeatherLocation
    let current: CurrentWeather
}

struct WeatherLocation: Codable {
    let name: String
    let region: String
    let country: String
    let localtime: String
}

struct CurrentWeather: Codable {
    let temp_c: Double
    let temp_f: Double
    let condition: WeatherCondition
    let wind_kph: Double
    let precip_mm: Double
    let humidity: Int
    let feelslike_c: Double
    let uv: Double

    enum CodingKeys: String, CodingKey {
        case temp_c = "temp_c"
        case temp_f = "temp_f"
        case condition
        case wind_kph = "wind_kph"
        case precip_mm = "precip_mm"
        case humidity
        case feelslike_c = "feelslike_c"
        case uv
    }
}

struct WeatherCondition: Codable {
    let text: String
    let icon: String
    let code: Int
}

// MARK: - Workout Suggestion

enum WorkoutSuggestion {
    case outdoor
    case indoor
    case caution

    var emoji: String {
        switch self {
        case .outdoor: return "🏃‍♂️"
        case .indoor: return "💪"
        case .caution: return "⚠️"
        }
    }

    func localizedMessage(language: String = "it") -> String {
        switch self {
        case .outdoor:
            return language == "it" ? "Perfetto per allenarsi all'aperto!" : "Perfect for outdoor training!"
        case .indoor:
            return language == "it" ? "Meglio una sessione in palestra" : "Better to train indoors"
        case .caution:
            return language == "it" ? "Condizioni difficili, sii prudente" : "Difficult conditions, be careful"
        }
    }
}

// MARK: - Weather Service

@MainActor
class WeatherService: ObservableObject {
    static let shared = WeatherService()

    @Published var currentWeather: CurrentWeather?
    @Published var location: WeatherLocation?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = APIConfiguration.weatherAPIBaseURL
    private let apiKey = APIConfiguration.weatherAPIKey

    private init() {}

    /// Fetch weather for coordinates
    func fetchWeather(latitude: Double, longitude: Double) async {
        guard APIConfiguration.isWeatherAPIConfigured else {
            errorMessage = "Weather API not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        let query = "\(latitude),\(longitude)"
        let urlString = "\(baseURL)/current.json?key=\(apiKey)&q=\(query)&aqi=no"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                isLoading = false
                return
            }

            guard httpResponse.statusCode == 200 else {
                errorMessage = "HTTP Error: \(httpResponse.statusCode)"
                isLoading = false
                return
            }

            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)

            self.currentWeather = weatherResponse.current
            self.location = weatherResponse.location
            self.isLoading = false

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Get workout suggestion based on current weather
    func getWorkoutSuggestion() -> WorkoutSuggestion {
        guard let weather = currentWeather else {
            return .indoor
        }

        let temp = weather.temp_c
        let precipitation = weather.precip_mm
        let windSpeed = weather.wind_kph

        // Caution conditions: extreme weather
        if temp < 0 || temp > 35 || precipitation > 5 || windSpeed > 40 {
            return .caution
        }

        // Outdoor conditions: nice weather
        if temp >= 10 && temp <= 28 && precipitation < 1 && windSpeed < 25 {
            return .outdoor
        }

        // Default to indoor
        return .indoor
    }

    /// Get weather emoji based on condition
    func getWeatherEmoji() -> String {
        guard let weather = currentWeather else {
            return "🌡️"
        }

        let code = weather.condition.code

        // Based on WeatherAPI condition codes
        switch code {
        case 1000: return "☀️"  // Sunny
        case 1003: return "⛅️"  // Partly cloudy
        case 1006, 1009: return "☁️"  // Cloudy
        case 1030, 1135, 1147: return "🌫️"  // Fog
        case 1063, 1150, 1153, 1180, 1183, 1186, 1189, 1192, 1195, 1198, 1201, 1240, 1243, 1246: return "🌧️"  // Rain
        case 1066, 1114, 1117, 1210, 1213, 1216, 1219, 1222, 1225, 1237, 1255, 1258, 1261, 1264: return "❄️"  // Snow
        case 1087, 1273, 1276, 1279, 1282: return "⛈️"  // Thunderstorm
        case 1069, 1072, 1168, 1171, 1204, 1207, 1249, 1252: return "🌨️"  // Sleet
        default: return "🌡️"
        }
    }

    /// Format temperature for display
    func getTemperatureString(useCelsius: Bool = true) -> String {
        guard let weather = currentWeather else {
            return "—"
        }

        let temp = useCelsius ? weather.temp_c : weather.temp_f
        let unit = useCelsius ? "°C" : "°F"
        return String(format: "%.0f%@", temp, unit)
    }

    /// Get weather summary text
    func getWeatherSummary() -> String {
        guard let weather = currentWeather,
              let location = location else {
            return "Weather data not available"
        }

        let temp = String(format: "%.0f°C", weather.temp_c)
        return "\(temp) • \(weather.condition.text)"
    }
}
