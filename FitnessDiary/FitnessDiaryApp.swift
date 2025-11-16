import SwiftUI
import SwiftData

@main
struct FitnessDiaryApp: App {
    @State private var showOnboarding = true

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else {
                ContentView() // La tua vista principale
            }
        }
        .modelContainer(for: [UserProfile.self, Muscle.self, Equipment.self, Exercise.self, Client.self, WorkoutCard.self, WorkoutFolder.self, WorkoutBlock.self, WorkoutExerciseItem.self, WorkoutSet.self, StrengthExpressionParameters.self])
    }
}
