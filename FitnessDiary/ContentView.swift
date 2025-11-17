import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var bluetoothManager = BluetoothHeartRateManager()

    var body: some View {
        TabView {
            // Tab 1 - Dashboard
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            // Tab 2 - Allenamento
            WorkoutExecutionView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Allenamento", systemImage: "stopwatch")
                }

            // Tab 3 - Schede
            WorkoutCardListView()
                .tabItem {
                    Label("Schede", systemImage: "list.bullet.clipboard")
                }

            // Tab 4 - Settings
            SettingsView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Impostazioni", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
