import SwiftUI

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
    }
}
