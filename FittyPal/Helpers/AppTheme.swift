import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable {
    case light
    case vibrant

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .light:
            return "preferences.theme.light"
        case .vibrant:
            return "preferences.theme.vibrant"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .vibrant:
            return .dark
        }
    }
}

/// Centralized palette that keeps the new visual identity consistent across views.
/// The theme mirrors the marketing site by providing paired light/dark gradients
/// and semitransparent surfaces that can be reused throughout the app.
enum AppTheme {
    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 19/255, green: 6/255, blue: 27/255),
                    Color(red: 49/255, green: 12/255, blue: 56/255),
                    Color(red: 94/255, green: 22/255, blue: 72/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 235/255, green: 251/255, blue: 249/255),
                    Color(red: 205/255, green: 243/255, blue: 235/255),
                    Color(red: 165/255, green: 227/255, blue: 215/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
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
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
                .overlay(blobLayer)
            
            content
        }
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
        if colorScheme == .dark {
            return Color(red: primary ? 255/255 : 226/255, green: primary ? 102/255 : 70/255, blue: primary ? 196/255 : 125/255)
                .opacity(primary ? 0.32 : 0.22)
        } else {
            return Color(red: primary ? 255/255 : 255/255, green: primary ? 189/255 : 214/255, blue: primary ? 148/255 : 186/255)
                .opacity(primary ? 0.35 : 0.25)
        }
    }
    
    private func blobAccent() -> Color {
        if colorScheme == .dark {
            return Color(red: 255/255, green: 92/255, blue: 125/255).opacity(0.24)
        } else {
            return Color(red: 255/255, green: 170/255, blue: 120/255).opacity(0.28)
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
