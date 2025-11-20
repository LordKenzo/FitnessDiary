import SwiftUI
import SwiftData
import UIKit

@main
struct FittyPalApp: App {
    @State private var showOnboarding = true
    @State private var themeManager = ThemeManager.shared

    init() {
        let tableAppearance = UITableView.appearance()
        tableAppearance.backgroundColor = .clear
        tableAppearance.tableFooterView = UIView()
        tableAppearance.tableHeaderView = UIView()

        UITableViewCell.appearance().backgroundColor = .clear
        UITableViewHeaderFooterView.appearance().tintColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .environment(themeManager)
            } else {
                ContentView() // La tua vista principale
                    .environment(themeManager)
            }
        }
        .modelContainer(for: [UserProfile.self, Muscle.self, Equipment.self, Exercise.self, Client.self, WorkoutCard.self, WorkoutFolder.self, WorkoutBlock.self, WorkoutExerciseItem.self, WorkoutSet.self, StrengthExpressionParameters.self, WorkoutSessionLog.self, CustomTrainingMethod.self, CustomRepConfiguration.self])
    }
}
