import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var bluetoothManager = BluetoothHeartRateManager()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(ThemeManager.self) private var themeManager
    @State private var isAtBottom: Bool = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label(L("tab.dashboard"), systemImage: "house.fill")
                }

            WorkoutExecutionView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label(L("tab.workout"), systemImage: "stopwatch")
                }

            WorkoutCardListView()
                .tabItem {
                    Label(L("tab.cards"), systemImage: "list.bullet.clipboard")
                }

            SettingsView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label(L("tab.settings"), systemImage: "gearshape")
                }
        }
        .appScreenBackground()
        .environment(\.isAtBottomKey, $isAtBottom)
        .onAppear {
            configureTabBarAppearance(for: themeManager.currentTheme, isAtBottom: isAtBottom)
        }
        .onChange(of: themeManager.currentTheme) { _, newTheme in
            configureTabBarAppearance(for: newTheme, isAtBottom: isAtBottom)
        }
        .onChange(of: isAtBottom) { _, newValue in
            configureTabBarAppearance(for: themeManager.currentTheme, isAtBottom: newValue)
        }
    }

    private func configureTabBarAppearance(for theme: AppColorTheme, isAtBottom: Bool) {
        let appearance = UITabBarAppearance()

        // Use transparent background with blur for all themes
        appearance.configureWithTransparentBackground()

        // Adjust opacity based on scroll position
        let darkOpacity: CGFloat = isAtBottom ? 0.1 : 0.2
        let lightOpacity: CGFloat = isAtBottom ? 0.1 : 0.4

        switch theme {
        case .vibrant, .ocean, .forest:
            // Dark themes: subtle dark tint with blur
            appearance.backgroundColor = UIColor.black.withAlphaComponent(darkOpacity)

        case .sunset, .lavender, .fittypal, .christmas:
            // Light themes: subtle white tint with blur + dark icons
            appearance.backgroundColor = UIColor.white.withAlphaComponent(lightOpacity)

            // Use dark icons for light themes for better contrast
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor.black.withAlphaComponent(0.7)
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black.withAlphaComponent(0.7)]
            itemAppearance.selected.iconColor = UIColor.systemBlue
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]

            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
        }

        // Apply to global appearance for new instances
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // IMPORTANT: Apply to existing TabBar instances immediately
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.allSubviews.compactMap { $0 as? UITabBar }.forEach { tabBar in
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }
}

// MARK: - Environment Key for Bottom Detection
private struct IsAtBottomKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isAtBottomKey: Binding<Bool> {
        get { self[IsAtBottomKey.self] }
        set { self[IsAtBottomKey.self] = newValue }
    }
}

// MARK: - Scroll Position Tracker
struct ScrollPositionTracker: ViewModifier {
    @Environment(\.isAtBottomKey) private var isAtBottom
    let threshold: CGFloat = 50 // Distance from bottom to trigger

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scrollView")).minY
                    )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { minY in
                // When minY is very negative, we're at the bottom
                let isNearBottom = minY < -threshold
                if isAtBottom.wrappedValue != isNearBottom {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAtBottom.wrappedValue = isNearBottom
                    }
                }
            }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func trackScrollPosition() -> some View {
        modifier(ScrollPositionTracker())
    }
}

// Helper extension to find all subviews
extension UIView {
    var allSubviews: [UIView] {
        var subviews = self.subviews
        for subview in self.subviews {
            subviews.append(contentsOf: subview.allSubviews)
        }
        return subviews
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
