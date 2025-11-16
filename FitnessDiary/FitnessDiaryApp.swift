import SwiftUI
import SwiftData

@main
struct FitnessDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserProfile.self, Muscle.self])
    }
}
