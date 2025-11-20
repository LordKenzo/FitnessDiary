import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable, Sendable {
    case vibrant
    case ocean
    case sunset
    case forest
    case lavender

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vibrant: return "Vibrant"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .forest: return "Forest"
        case .lavender: return "Lavender"
        }
    }

    var localizationKey: String {
        switch self {
        case .vibrant: return "preferences.theme.vibrant"
        case .ocean: return "preferences.theme.ocean"
        case .sunset: return "preferences.theme.sunset"
        case .forest: return "preferences.theme.forest"
        case .lavender: return "preferences.theme.lavender"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .vibrant, .ocean, .forest: return .dark
        case .sunset, .lavender: return .light
        }
    }

    var icon: String {
        switch self {
        case .vibrant: return "sparkles"
        case .ocean: return "water.waves"
        case .sunset: return "sunset.fill"
        case .forest: return "leaf.fill"
        case .lavender: return "cloud.fill"
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
            self.currentTheme = theme
        } else {
            self.currentTheme = .vibrant
        }
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
        }
    }

    // MARK: - Legacy ColorScheme-based functions (for compatibility)
    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        backgroundGradient(for: ThemeManager.shared.currentTheme)
    }

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
