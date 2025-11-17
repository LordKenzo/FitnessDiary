import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1 - Allenamento
            WorkoutSelectionView()
                .tabItem {
                    Label("Allenamento", systemImage: "stopwatch")
                }

            // Tab 2 - Storico
            WorkoutHistoryView()
                .tabItem {
                    Label("Storico", systemImage: "clock.arrow.circlepath")
                }

            // Tab 3 - Schede
            WorkoutCardListView()
                .tabItem {
                    Label("Schede", systemImage: "list.bullet.clipboard")
                }

            // Tab 4 - Settings
            SettingsView()
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
