import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Label("Profilo", systemImage: "person.circle")
                }
            
            Text("Esercizi")
                .tabItem {
                    Label("Esercizi", systemImage: "figure.strengthtraining.traditional")
                }
            
            Text("Schede")
                .tabItem {
                    Label("Schede", systemImage: "list.bullet.clipboard")
                }
            
            Text("Allenamento")
                .tabItem {
                    Label("Allenamento", systemImage: "stopwatch")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
