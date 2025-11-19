import SwiftUI

/// Centralized palette that keeps the new visual identity consistent across views.
/// The theme mirrors the marketing site by providing paired light/dark gradients
/// and semitransparent surfaces that can be reused throughout the app.
enum AppTheme {
    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 15/255, green: 18/255, blue: 33/255),
                    Color(red: 27/255, green: 32/255, blue: 65/255),
                    Color(red: 50/255, green: 33/255, blue: 68/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 247/255, green: 249/255, blue: 255/255),
                    Color(red: 255/255, green: 249/255, blue: 242/255)
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

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppTheme.backgroundGradient(for: colorScheme)
            .ignoresSafeArea()
            .overlay(blobLayer)
    }

    private var blobLayer: some View {
        ZStack {
            Circle()
                .fill(Color.pink.opacity(colorScheme == .dark ? 0.25 : 0.35))
                .frame(width: 320)
                .blur(radius: 120)
                .offset(x: -140, y: -250)

            Circle()
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.20 : 0.25))
                .frame(width: 380)
                .blur(radius: 140)
                .offset(x: 160, y: -180)

            Circle()
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.18 : 0.25))
                .frame(width: 420)
                .blur(radius: 160)
                .offset(x: 60, y: 220)
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
}

private struct AppScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AppBackgroundView()
            content
        }
    }
}
