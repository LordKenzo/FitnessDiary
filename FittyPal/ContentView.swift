import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var bluetoothManager = BluetoothHeartRateManager()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(ThemeManager.self) private var themeManager

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
        .onAppear {
            configureTabBarAppearance(for: themeManager.currentTheme)
        }
        .onChange(of: themeManager.currentTheme) { _, newTheme in
            configureTabBarAppearance(for: newTheme)
        }
    }

    private func configureTabBarAppearance(for theme: AppColorTheme) {
        let appearance = UITabBarAppearance()

        // Use transparent background with blur for all themes
        appearance.configureWithTransparentBackground()

        switch theme {
        case .vibrant, .ocean, .forest:
            // Dark themes: subtle dark tint with blur
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        case .sunset, .lavender, .fittypal, .christmas:
            // Light themes: subtle white tint with blur + dark icons
            appearance.backgroundColor = UIColor.white.withAlphaComponent(0.4)

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

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
