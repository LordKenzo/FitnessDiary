import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1 - Allenamento
            TrainingHomeView()
                .tabItem {
                    Label("Allenamento", systemImage: "stopwatch")
                }
            
            // Tab 2 - Schede
            WorkoutCardListView()
                .tabItem {
                    Label("Schede", systemImage: "list.bullet.clipboard")
                }
            
            // Tab 3 - Settings
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
