import SwiftUI
import SwiftData
import PhotosUI

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Muscle.name) private var muscles: [Muscle]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]

    @State private var showingAddExercise = false
    @State private var selectedExercise: Exercise?
    @State private var searchText = ""
    @State private var filterPrimaryMetabolism: PrimaryMetabolism?
    @State private var filterBiomechanicalStructure: BiomechanicalStructure?
    @State private var filterTrainingRole: TrainingRole?
    @State private var filterCategory: ExerciseCategory?

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesMetabolism = filterPrimaryMetabolism == nil || exercise.primaryMetabolism == filterPrimaryMetabolism
            let matchesBiomechanical = filterBiomechanicalStructure == nil || exercise.biomechanicalStructure == filterBiomechanicalStructure
            let matchesRole = filterTrainingRole == nil || exercise.trainingRole == filterTrainingRole
            let matchesCategory = filterCategory == nil || exercise.category == filterCategory
            return matchesSearch && matchesMetabolism && matchesBiomechanical && matchesRole && matchesCategory
        }
    }

    var body: some View {
        List {
            if exercises.isEmpty {
                ContentUnavailableView {
                    Label("Nessun esercizio", systemImage: "figure.strengthtraining.traditional")
                } description: {
                    Text("Aggiungi il tuo primo esercizio")
                } actions: {
                    Button("Aggiungi Esercizio") {
                        showingAddExercise = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(filteredExercises) { exercise in
                    ExerciseRow(exercise: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedExercise = exercise
                        }
                }
                .onDelete(perform: deleteExercises)
            }
        }
        .searchable(text: $searchText, prompt: "Cerca esercizio")
        .navigationTitle("Esercizi")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Section("Metabolismo Primario") {
                        Button(action: { filterPrimaryMetabolism = nil }) {
                            Label("Tutti", systemImage: filterPrimaryMetabolism == nil ? "checkmark" : "")
                        }
                        ForEach(PrimaryMetabolism.allCases, id: \.self) { type in
                            Button(action: { filterPrimaryMetabolism = type }) {
                                Label(type.rawValue, systemImage: filterPrimaryMetabolism == type ? "checkmark" : type.icon)
                            }
                        }
                    }

                    Section("Struttura Biomeccanica") {
                        Button(action: { filterBiomechanicalStructure = nil }) {
                            Label("Tutti", systemImage: filterBiomechanicalStructure == nil ? "checkmark" : "")
                        }
                        ForEach(BiomechanicalStructure.allCases, id: \.self) { type in
                            Button(action: { filterBiomechanicalStructure = type }) {
                                Label(type.rawValue, systemImage: filterBiomechanicalStructure == type ? "checkmark" : type.icon)
                            }
                        }
                    }

                    Section("Ruolo nell'Allenamento") {
                        Button(action: { filterTrainingRole = nil }) {
                            Label("Tutti", systemImage: filterTrainingRole == nil ? "checkmark" : "")
                        }
                        ForEach(TrainingRole.allCases, id: \.self) { role in
                            Button(action: { filterTrainingRole = role }) {
                                Label(role.rawValue, systemImage: filterTrainingRole == role ? "checkmark" : role.icon)
                            }
                        }
                    }

                    Section("Categoria") {
                        Button(action: { filterCategory = nil }) {
                            Label("Tutti", systemImage: filterCategory == nil ? "checkmark" : "")
                        }
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Button(action: { filterCategory = category }) {
                                Label(category.rawValue, systemImage: filterCategory == category ? "checkmark" : category.icon)
                            }
                        }
                    }

                    if filterPrimaryMetabolism != nil || filterBiomechanicalStructure != nil || filterTrainingRole != nil || filterCategory != nil {
                        Divider()
                        Button("Rimuovi Filtri", role: .destructive) {
                            filterPrimaryMetabolism = nil
                            filterBiomechanicalStructure = nil
                            filterTrainingRole = nil
                            filterCategory = nil
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(muscles: muscles, equipment: equipment)
        }
        .sheet(item: $selectedExercise) { exercise in
            EditExerciseView(exercise: exercise, muscles: muscles, equipment: equipment)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exerciseToDelete = filteredExercises[index]

            // Rimuovi questo esercizio da tutte le varianti degli altri esercizi
            for variant in exerciseToDelete.variants {
                variant.variants.removeAll { $0.id == exerciseToDelete.id }
            }

            modelContext.delete(exerciseToDelete)
        }
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    let exercise: Exercise
    @State private var showingFullscreenPhoto = false

    var body: some View {
        HStack(spacing: 12) {
            // Anteprima foto o placeholder
            if let photoData = exercise.photo1Data,
               let uiImage = UIImage(data: photoData) {
                Button {
                    showingFullscreenPhoto = true
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "eye.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 16, height: 16)
                                )
                                .offset(x: 2, y: 2)
                        }
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(exercise.trainingRole.rawValue, systemImage: exercise.trainingRole.icon)
                        .font(.caption)
                        .foregroundStyle(exercise.trainingRole.color)

                    Label(exercise.category.rawValue, systemImage: exercise.category.icon)
                        .font(.caption)
                        .foregroundStyle(exercise.category.color)
                }

                HStack(spacing: 8) {
                    Label(exercise.biomechanicalStructure.rawValue, systemImage: exercise.biomechanicalStructure.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Label(exercise.primaryMetabolism.rawValue, systemImage: exercise.primaryMetabolism.icon)
                        .font(.caption2)
                        .foregroundStyle(exercise.primaryMetabolism.color)
                }

                // Muscoli primari
                if !exercise.primaryMuscles.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(exercise.primaryMuscles.map { $0.name }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                // Muscoli secondari
                if !exercise.secondaryMuscles.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "star.leadinghalf.filled")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text(exercise.secondaryMuscles.map { $0.name }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Attrezzo
                if let equipment = exercise.equipment {
                    HStack(spacing: 4) {
                        Image(systemName: equipment.category.icon)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(equipment.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if exercise.youtubeURL != nil {
                    Image(systemName: "video.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if !exercise.variants.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(.purple)
                            .font(.caption2)
                        Text("\(exercise.variants.count)")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .fullScreenCover(isPresented: $showingFullscreenPhoto) {
            if let photoData = exercise.photo1Data {
                FullscreenPhotoView(imageData: photoData)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseListView()
    }
    .modelContainer(for: [Exercise.self, Muscle.self, Equipment.self], inMemory: true)
}
