import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable, Sendable {
    case vibrant
    case ocean
    case sunset
    case forest
    case sunrise
    case lavender
    case fittypal
    case yellowstone
    case christmas

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .vibrant: return "preferences.theme.vibrant"
        case .ocean: return "preferences.theme.ocean"
        case .sunset: return "preferences.theme.sunset"
        case .forest: return "preferences.theme.forest"
        case .sunrise: return "preferences.theme.sunrise"
        case .lavender: return "preferences.theme.lavender"
        case .fittypal: return "preferences.theme.fittypal"
        case .yellowstone: return "preferences.theme.yellowstone"
        case .christmas: return "preferences.theme.christmas"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .sunset, .vibrant, .ocean, .forest: return .dark
        case .sunrise, .lavender, .fittypal, .yellowstone, .christmas: return .light
        }
    }

    var icon: String {
        switch self {
        case .vibrant: return "sparkles"
        case .ocean: return "water.waves"
        case .sunset: return "sunset.fill"
        case .forest: return "tree.fill"
        case .sunrise: return "sunrise.fill"
        case .lavender: return "cloud.fill"
        case .fittypal: return "heart.fill"
        case .yellowstone: return "pawprint.fill"
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
            // Available December 1-31
            if let month = components.month {
                return (month == 12)
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
                    Color(red: 10/255, green: 27/255, blue: 69/255),    // Blu notte (#0A1B45)
                    Color(red: 90/255, green: 45/255, blue: 130/255),   // Viola (#5A2D82)
                    Color(red: 196/255, green: 58/255, blue: 76/255),   // Rosso (#C43A4C)
                    Color(red: 255/255, green: 122/255, blue: 50/255),  // Arancio (#FF7A32)
                    Color(red: 255/255, green: 212/255, blue: 106/255)  // Giallo oro (#FFD46A)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .forest:
            return LinearGradient(
                colors: [
                    Color(red: 15/255, green: 30/255, blue: 20/255),    // Verde abete scuro (#0F1E14)
                    Color(red: 30/255, green: 60/255, blue: 38/255),    // Verde sottobosco (#1E3C26)
                    Color(red: 55/255, green: 95/255, blue: 65/255),    // Verde felce (#375F41)
                    Color(red: 92/255, green: 59/255, blue: 40/255),    // Marrone corteccia (#5C3B28)
                    Color(red: 135/255, green: 90/255, blue: 60/255)    // Marrone terra (#875A3C)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunrise:
            return LinearGradient(
                colors: [
                    Color(red: 26/255, green: 42/255, blue: 79/255),     // #1A2A4F - Blu notte
                    Color(red: 75/255, green: 59/255, blue: 117/255),   // #4B3B75 - Viola crepuscolo
                    Color(red: 213/255, green: 140/255, blue: 169/255), // #D58CA9 - Rosa alba
                    Color(red: 255/255, green: 191/255, blue: 143/255), // #FFBF8F - Arancio tenue
                    Color(red: 255/255, green: 236/255, blue: 200/255)  // #FFECC8 - Giallo orizzonte
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
        case .yellowstone:
            return LinearGradient(
                colors: [
                    Color(red: 255/255, green: 246/255, blue: 220/255),   // #FFF6DC - Giallo pastello
                    Color(red: 255/255, green: 230/255, blue: 180/255),   // #FFE6B4 - Oro tenue
                    Color(red: 255/255, green: 212/255, blue: 160/255),   // #FFD4A0 - Pesca chiaro
                    Color(red: 255/255, green: 185/255, blue: 120/255),   // #FFB978 - Arancio caldo
                    Color(red: 255/255, green: 150/255, blue: 80/255)     // #FF9650 - Arancio pieno
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .christmas:
            return LinearGradient(
                colors: [
                    Color(red: 190/255, green: 30/255, blue: 45/255),   // Rosso carminio
                    Color(red: 60/255, green: 185/255, blue: 137/255),  // Verde menta Natale
                    Color(red: 215/255, green: 38/255, blue: 56/255)    // Rosso ciliegia
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

    // MARK: - Blob colors for backgrounds
    /// Get blob color for a theme
    static func blobColor(for theme: AppColorTheme, primary: Bool = false) -> Color {
        switch theme {
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
        case .sunrise:
            return Color(red: primary ? 200/255 : 180/255, green: primary ? 160/255 : 180/255, blue: primary ? 255/255 : 240/255)
                .opacity(primary ? 0.30 : 0.20)
        case .lavender:
            return Color(red: primary ? 200/255 : 180/255, green: primary ? 160/255 : 180/255, blue: primary ? 255/255 : 240/255)
                .opacity(primary ? 0.30 : 0.20)
        case .fittypal:
            return Color(red: primary ? 80/255 : 100/255, green: primary ? 220/255 : 200/255, blue: primary ? 180/255 : 160/255)
                .opacity(primary ? 0.35 : 0.25)
        case .yellowstone:
            return Color(red: primary ? 80/255 : 100/255, green: primary ? 220/255 : 200/255, blue: primary ? 180/255 : 160/255)
                .opacity(primary ? 0.35 : 0.25)
        case .christmas:
            return Color(red: primary ? 220/255 : 180/255, green: primary ? 50/255 : 180/255, blue: primary ? 50/255 : 50/255)
                .opacity(primary ? 0.30 : 0.22)
        }
    }

    /// Get blob accent color for a theme
    static func blobAccent(for theme: AppColorTheme) -> Color {
        switch theme {
        case .vibrant:
            return Color(red: 255/255, green: 92/255, blue: 125/255).opacity(0.24)
        case .ocean:
            return Color(red: 120/255, green: 220/255, blue: 255/255).opacity(0.20)
        case .sunset:
            return Color(red: 255/255, green: 100/255, blue: 150/255).opacity(0.28)
        case .forest:
            return Color(red: 150/255, green: 220/255, blue: 100/255).opacity(0.22)
        case .sunrise:
            return Color(red: 100/255, green: 240/255, blue: 200/255).opacity(0.28)
        case .lavender:
            return Color(red: 220/255, green: 180/255, blue: 255/255).opacity(0.25)
        case .fittypal:
            return Color(red: 100/255, green: 240/255, blue: 200/255).opacity(0.28)
        case .yellowstone:
            return Color(red: 100/255, green: 240/255, blue: 200/255).opacity(0.28)
        case .christmas:
            return Color(red: 80/255, green: 180/255, blue: 80/255).opacity(0.25)
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
        return AppTheme.blobColor(for: themeManager.currentTheme, primary: primary)
    }

    private func blobAccent() -> Color {
        return AppTheme.blobAccent(for: themeManager.currentTheme)
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
