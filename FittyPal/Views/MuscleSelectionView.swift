import SwiftUI
import SwiftData

// MARK: - Muscle Selection View (Full Screen)
struct MuscleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let muscles: [Muscle]
    @Binding var selectedMuscles: Set<Muscle>
    let title: String
    
    private var musclesByCategory: [MuscleCategory: [Muscle]] {
        Dictionary(grouping: muscles, by: { $0.category })
    }
    
    var body: some View {
        AppBackgroundView {
            NavigationStack {
                VStack {
                    if muscles.isEmpty {
                        ContentUnavailableView {
                            Label("Nessun muscolo disponibile", systemImage: "figure.arms.open")
                        } description: {
                            Text("Inizializza prima la libreria muscoli")
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(MuscleCategory.allCases, id: \.self) { category in
                                if let musclesInCategory = musclesByCategory[category], !musclesInCategory.isEmpty {
                                    Section {
                                        ForEach(musclesInCategory) { muscle in
                                            Button {
                                                toggleMuscle(muscle)
                                            } label: {
                                                HStack {
                                                    Text(muscle.name)
                                                        .foregroundStyle(.primary)
                                                    Spacer()
                                                    if selectedMuscles.contains(muscle) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundStyle(.blue)
                                                    } else {
                                                        Image(systemName: "circle")
                                                            .foregroundStyle(.gray.opacity(0.3))
                                                    }
                                                }
                                            }
                                        }
                                    } header: {
                                        Label(category.rawValue, systemImage: category.icon)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fatto") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func toggleMuscle(_ muscle: Muscle) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.remove(muscle)
        } else {
            selectedMuscles.insert(muscle)
        }
    }
}
