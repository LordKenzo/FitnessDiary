import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var bluetoothManager = BluetoothHeartRateManager()
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        TabView {
            // Tab 1 - Dashboard
            DashboardView()
                .tabItem {
                    Label(L("tab.dashboard"), systemImage: "house.fill")
                }

            // Tab 2 - Allenamento
            WorkoutExecutionView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label(L("tab.workout"), systemImage: "stopwatch")
                }

            // Tab 3 - Schede
            WorkoutCardListView()
                .tabItem {
                    Label(L("tab.cards"), systemImage: "list.bullet.clipboard")
                }

            // Tab 4 - Settings
            SettingsView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label(L("tab.settings"), systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
