import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var bluetoothManager = BluetoothHeartRateManager()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @AppStorage("appColorTheme") private var appColorThemeRaw = AppColorTheme.vibrant.rawValue

    var body: some View {
        ZStack {
            AppBackgroundView()

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
        }
        .preferredColorScheme(appColorTheme.colorScheme)
    }

    private var appColorTheme: AppColorTheme {
        AppColorTheme(rawValue: appColorThemeRaw) ?? .vibrant
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
