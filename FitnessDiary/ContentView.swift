import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var bluetoothManager = BluetoothHeartRateManager()

    var body: some View {
        TabView {
            // Tab 1 - Allenamento
            WorkoutExecutionView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Allenamento", systemImage: "stopwatch")
                }

            // Tab 2 - Schede
            WorkoutCardListView()
                .tabItem {
                    Label("Schede", systemImage: "list.bullet.clipboard")
                }

            // Tab 3 - Settings
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
