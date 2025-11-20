import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable, Sendable {
    case vibrant
    case ocean
    case sunset
    case forest
    case lavender
    case fittypal
    case christmas

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vibrant: return "Vibrant"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .forest: return "Forest"
        case .lavender: return "Lavender"
        case .fittypal: return "FittyPal"
        case .christmas: return "Christmas"
        }
    }

    var localizationKey: String {
        switch self {
        case .vibrant: return "preferences.theme.vibrant"
        case .ocean: return "preferences.theme.ocean"
        case .sunset: return "preferences.theme.sunset"
        case .forest: return "preferences.theme.forest"
        case .lavender: return "preferences.theme.lavender"
        case .fittypal: return "preferences.theme.fittypal"
        case .christmas: return "preferences.theme.christmas"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .vibrant, .ocean, .forest: return .dark
        case .sunset, .lavender, .fittypal, .christmas: return .light
        }
    }

    var icon: String {
        switch self {
        case .vibrant: return "sparkles"
        case .ocean: return "water.waves"
        case .sunset: return "sunset.fill"
        case .forest: return "leaf.fill"
        case .lavender: return "cloud.fill"
        case .fittypal: return "heart.fill"
        case .christmas: return "gift.fill"
        }
    }

    /// Seasonal themes are only available during specific date ranges
    var isSeasonal: Bool {
        switch self {
        case .christmas: return true
        default: return false
        }
    }

    /// Check if this seasonal theme is currently available
    func isAvailable() -> Bool {
        guard isSeasonal else { return true }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.month, .day], from: now)

        switch self {
        case .christmas:
            // Debug: Available Nov 20-21
            // Production: Available Dec 1-31
            if let month = components.month, let day = components.day {
                return (month == 11 && day >= 20 && day <= 21) // Debug
                // return (month == 12) // Production
            }
            return false
        default:
            return true
        }
    }
}

/// Theme Manager - Singleton to manage app-wide theme
@MainActor
@Observable
class ThemeManager {
    static let shared = ThemeManager()

    var currentTheme: AppColorTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppColorTheme(rawValue: savedTheme) {
            // Check if saved theme is seasonal and no longer available
            if theme.isSeasonal && !theme.isAvailable() {
                // Switch to FittyPal after seasonal theme expires
                self.currentTheme = .fittypal
            } else {
                self.currentTheme = theme
            }
        } else {
            self.currentTheme = .vibrant
        }
    }

    /// Get available themes (filtering out unavailable seasonal themes)
    static var availableThemes: [AppColorTheme] {
        AppColorTheme.allCases.filter { $0.isAvailable() }
    }
}

/// Centralized palette that keeps the new visual identity consistent across views.
enum AppTheme {
    // MARK: - Theme-aware functions
    static func backgroundGradient(for theme: AppColorTheme) -> LinearGradient {
        switch theme {
        case .vibrant:
            return LinearGradient(
                colors: [
                    Color(red: 19/255, green: 6/255, blue: 27/255),
                    Color(red: 49/255, green: 12/255, blue: 56/255),
                    Color(red: 94/255, green: 22/255, blue: 72/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ocean:
            return LinearGradient(
                colors: [
                    Color(red: 10/255, green: 25/255, blue: 47/255),
                    Color(red: 18/255, green: 58/255, blue: 85/255),
                    Color(red: 28/255, green: 75/255, blue: 102/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunset:
            return LinearGradient(
                colors: [
                    Color(red: 255/255, green: 237/255, blue: 220/255),
                    Color(red: 255/255, green: 210/255, blue: 180/255),
                    Color(red: 255/255, green: 180/255, blue: 150/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .forest:
            return LinearGradient(
                colors: [
                    Color(red: 15/255, green: 30/255, blue: 20/255),
                    Color(red: 25/255, green: 55/255, blue: 35/255),
                    Color(red: 35/255, green: 70/255, blue: 45/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .lavender:
            return LinearGradient(
                colors: [
                    Color(red: 240/255, green: 235/255, blue: 255/255),
                    Color(red: 225/255, green: 215/255, blue: 250/255),
                    Color(red: 210/255, green: 195/255, blue: 245/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .fittypal:
            return LinearGradient(
                colors: [
                    Color(red: 242/255, green: 255/255, blue: 252/255),
                    Color(red: 204/255, green: 252/255, blue: 238/255),
                    Color(red: 141/255, green: 233/255, blue: 198/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .christmas:
            return LinearGradient(
                colors: [
                    Color(red: 255/255, green: 245/255, blue: 245/255),  // Light red/white
                    Color(red: 230/255, green: 255/255, blue: 235/255),  // Light green/white
                    Color(red: 255/255, green: 235/255, blue: 235/255)   // Light red
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - ColorScheme-based functions (for components that don't need themes)
    static func heroGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.orange.opacity(0.9), .pink.opacity(0.9), .yellow.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    static func elevatedSurface(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.08)
        default:
            return Color.white.opacity(0.95)
        }
    }

    static func cardBackground(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color(red: 25/255, green: 28/255, blue: 46/255).opacity(0.9)
        default:
            return Color.white.opacity(0.85)
        }
    }

    static func chipBackground(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.08)
        default:
            return Color.black.opacity(0.05)
        }
    }

    /// Lightweight background for text fields - minimal opacity for better typing performance
    static func fieldBackground(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.02)
        default:
            return Color.black.opacity(0.02)
        }
    }

    static func stroke(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.08)
        default:
            return Color.black.opacity(0.06)
        }
    }

    static func shadow(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.black.opacity(0.55)
        default:
            return Color.black.opacity(0.08)
        }
    }

    static func subtleText(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.7)
        default:
            return Color.black.opacity(0.6)
        }
    }
}

struct AppBackgroundView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ThemeManager.self) private var themeManager
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: themeManager.currentTheme)
                .ignoresSafeArea()
                .overlay(blobLayer)

            content
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }

    private var blobLayer: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(blobColor(primary: true))
                    .frame(width: geometry.size.width * 0.6)
                    .blur(radius: geometry.size.width * 0.23)
                    .offset(x: -geometry.size.width * 0.25, y: -geometry.size.height * 0.3)

                Circle()
                    .fill(blobColor())
                    .frame(width: geometry.size.width * 0.7)
                    .blur(radius: geometry.size.width * 0.27)
                    .offset(x: geometry.size.width * 0.28, y: -geometry.size.height * 0.18)

                Circle()
                    .fill(blobAccent())
                    .frame(width: geometry.size.width * 0.76)
                    .blur(radius: geometry.size.width * 0.3)
                    .offset(x: geometry.size.width * 0.07, y: geometry.size.height * 0.28)
            }
        }
    }

    private func blobColor(primary: Bool = false) -> Color {
        switch themeManager.currentTheme {
        case .vibrant:
            return Color(red: primary ? 255/255 : 226/255, green: primary ? 102/255 : 70/255, blue: primary ? 196/255 : 125/255)
                .opacity(primary ? 0.32 : 0.22)
        case .ocean:
            return Color(red: primary ? 80/255 : 100/255, green: primary ? 180/255 : 200/255, blue: primary ? 255/255 : 220/255)
                .opacity(primary ? 0.28 : 0.18)
        case .sunset:
            return Color(red: primary ? 255/255 : 255/255, green: primary ? 140/255 : 180/255, blue: primary ? 100/255 : 130/255)
                .opacity(primary ? 0.35 : 0.25)
        case .forest:
            return Color(red: primary ? 100/255 : 120/255, green: primary ? 200/255 : 180/255, blue: primary ? 100/255 : 120/255)
                .opacity(primary ? 0.25 : 0.18)
        case .lavender:
            return Color(red: primary ? 200/255 : 180/255, green: primary ? 160/255 : 180/255, blue: primary ? 255/255 : 240/255)
                .opacity(primary ? 0.30 : 0.20)
        case .fittypal:
            return Color(red: primary ? 80/255 : 100/255, green: primary ? 220/255 : 200/255, blue: primary ? 180/255 : 160/255)
                .opacity(primary ? 0.35 : 0.25)
        case .christmas:
            return Color(red: primary ? 220/255 : 180/255, green: primary ? 50/255 : 180/255, blue: primary ? 50/255 : 50/255)
                .opacity(primary ? 0.30 : 0.22)
        }
    }

    private func blobAccent() -> Color {
        switch themeManager.currentTheme {
        case .vibrant:
            return Color(red: 255/255, green: 92/255, blue: 125/255).opacity(0.24)
        case .ocean:
            return Color(red: 120/255, green: 220/255, blue: 255/255).opacity(0.20)
        case .sunset:
            return Color(red: 255/255, green: 100/255, blue: 150/255).opacity(0.28)
        case .forest:
            return Color(red: 150/255, green: 220/255, blue: 100/255).opacity(0.22)
        case .lavender:
            return Color(red: 220/255, green: 180/255, blue: 255/255).opacity(0.25)
        case .fittypal:
            return Color(red: 100/255, green: 240/255, blue: 200/255).opacity(0.28)
        case .christmas:
            return Color(red: 80/255, green: 180/255, blue: 80/255).opacity(0.25)
        }
    }
}




struct DashboardCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground(for: colorScheme))
            .background(.thinMaterial.opacity(colorScheme == .dark ? 0.25 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.stroke(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow(for: colorScheme), radius: 25, y: 14)
    }
}

extension View {
    func dashboardCardStyle() -> some View {
        modifier(DashboardCardModifier())
    }

    /// Wraps the receiver in the ambient gradient background used across the app.
    func appScreenBackground() -> some View {
        modifier(AppScreenBackgroundModifier())
    }
    
    /// Makes `List` and `Form` containers transparent so the ambient gradient
    /// remains visible behind scrollable system chrome.
    func glassScrollBackground() -> some View {
        modifier(GlassScrollBackgroundModifier())
    }
}

private struct AppScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        AppBackgroundView {
            content
        }
    }
}

private struct GlassScrollBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}
