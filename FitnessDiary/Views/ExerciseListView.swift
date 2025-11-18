import SwiftUI
import SwiftData
import PhotosUI

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Muscle.name) private var muscles: [Muscle]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingAddExercise = false
    @State private var selectedExercise: Exercise?
    @State private var searchText = ""
    @State private var filterPrimaryMetabolism: PrimaryMetabolism?
    @State private var filterBiomechanicalStructure: BiomechanicalStructure?
    @State private var filterTrainingRole: TrainingRole?
    @State private var filterCategory: ExerciseCategory?
    @State private var filterPrimaryMuscle: Muscle?
    
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesMetabolism = filterPrimaryMetabolism == nil || exercise.primaryMetabolism == filterPrimaryMetabolism
            let matchesBiomechanical = filterBiomechanicalStructure == nil || exercise.biomechanicalStructure == filterBiomechanicalStructure
            let matchesRole = filterTrainingRole == nil || exercise.trainingRole == filterTrainingRole
            let matchesCategory = filterCategory == nil || exercise.category == filterCategory
            let matchesPrimaryMuscle = filterPrimaryMuscle == nil || exercise.primaryMuscles.contains(where: { $0.id == filterPrimaryMuscle!.id })
            return matchesSearch && matchesMetabolism && matchesBiomechanical && matchesRole && matchesCategory && matchesPrimaryMuscle
        }
    }
    
    var body: some View {
        List {
            if exercises.isEmpty {
                ContentUnavailableView {
                    Label(L("exercises.no.exercises"), systemImage: "figure.strengthtraining.traditional")
                } description: {
                    Text(L("exercises.no.exercises.description"))
                } actions: {
                    Button(L("exercises.add")) {
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
        .searchable(text: $searchText, prompt: L("exercises.search"))
        .navigationTitle(L("exercises.title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                muscleFilterMenu()
                otherFiltersMenu()
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus")
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
            for variant in exerciseToDelete.variants {
                variant.variants.removeAll { $0.id == exerciseToDelete.id }
            }
            modelContext.delete(exerciseToDelete)
        }
    }
    
    @ViewBuilder
    private func muscleFilterMenu() -> some View {
        Menu {
            Button(action: { filterPrimaryMuscle = nil }) {
                Label("Tutti i muscoli", systemImage: filterPrimaryMuscle == nil ? "checkmark" : "")
            }
            ForEach(muscles) { muscle in
                Button(action: { filterPrimaryMuscle = muscle }) {
                    Label(muscle.name, systemImage: filterPrimaryMuscle?.id == muscle.id ? "checkmark" : "figure.strengthtraining.traditional")
                }
            }
        } label: {
            Image(systemName: "figure.strengthtraining.traditional")
        }
    }

    
    @ViewBuilder
    private func otherFiltersMenu() -> some View {
        Menu {
            Section("Metabolismo Primario") {
                metabolismFilterSection()
            }
            Section("Struttura Biomeccanica") {
                biomechanicalStructureFilterSection()
            }
            Section("Ruolo nell'Allenamento") {
                trainingRoleFilterSection()
            }
            Section("Categoria") {
                categoryFilterSection()
            }
            if isAnyFilterActive() {
                Divider()
                removeAllFiltersButton()
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    @ViewBuilder
    private func metabolismFilterSection() -> some View {
        Button(action: { filterPrimaryMetabolism = nil }) {
            Label("Tutti", systemImage: filterPrimaryMetabolism == nil ? "checkmark" : "")
        }
        ForEach(PrimaryMetabolism.allCases, id: \.self) { type in
            Button(action: { filterPrimaryMetabolism = type }) {
                Label(type.rawValue, systemImage: filterPrimaryMetabolism == type ? "checkmark" : type.icon)
            }
        }
    }
    
    @ViewBuilder
    private func biomechanicalStructureFilterSection() -> some View {
        Button(action: { filterBiomechanicalStructure = nil }) {
            Label("Tutti", systemImage: filterBiomechanicalStructure == nil ? "checkmark" : "")
        }
        ForEach(BiomechanicalStructure.allCases, id: \.self) { type in
            Button(action: { filterBiomechanicalStructure = type }) {
                Label(type.rawValue, systemImage: filterBiomechanicalStructure == type ? "checkmark" : type.icon)
            }
        }
    }
    
    @ViewBuilder
    private func trainingRoleFilterSection() -> some View {
        Button(action: { filterTrainingRole = nil }) {
            Label("Tutti", systemImage: filterTrainingRole == nil ? "checkmark" : "")
        }
        ForEach(TrainingRole.allCases, id: \.self) { role in
            Button(action: { filterTrainingRole = role }) {
                Label(role.rawValue, systemImage: filterTrainingRole == role ? "checkmark" : role.icon)
            }
        }
    }
    
    @ViewBuilder
    private func categoryFilterSection() -> some View {
        Button(action: { filterCategory = nil }) {
            Label("Tutti", systemImage: filterCategory == nil ? "checkmark" : "")
        }
        ForEach(ExerciseCategory.allCases, id: \.self) { category in
            Button(action: { filterCategory = category }) {
                Label(category.rawValue, systemImage: filterCategory == category ? "checkmark" : category.icon)
            }
        }
    }
    
    @ViewBuilder
    private func removeAllFiltersButton() -> some View {
        Button("Rimuovi Filtri", role: .destructive) {
            filterPrimaryMetabolism = nil
            filterBiomechanicalStructure = nil
            filterTrainingRole = nil
            filterCategory = nil
            filterPrimaryMuscle = nil
        }
    }
    
    private func isAnyFilterActive() -> Bool {
        return filterPrimaryMetabolism != nil ||
        filterBiomechanicalStructure != nil ||
        filterTrainingRole != nil ||
        filterCategory != nil ||
        filterPrimaryMuscle != nil
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
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                    if exercise.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: exercise.trainingRole.icon)
                        .font(.caption)
                        .foregroundStyle(exercise.trainingRole.color)
                    Image(systemName: exercise.category.icon)
                        .font(.caption)
                        .foregroundStyle(exercise.category.color)
                    Image(systemName: exercise.biomechanicalStructure.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: exercise.primaryMetabolism.icon)
                        .font(.caption2)
                        .foregroundStyle(exercise.primaryMetabolism.color)
                }

                if let referencePlane = exercise.referencePlane {
                    HStack(spacing: 4) {
                        Image(systemName: referencePlane.icon)
                            .font(.caption2)
                            .foregroundStyle(referencePlane.color)
                        Text(referencePlane.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !exercise.motorSchemas.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(exercise.motorSchemas.sorted(by: { $0.rawValue < $1.rawValue })) { schema in
                            Image(systemName: schema.icon)
                                .font(.caption2)
                                .foregroundStyle(schema.color)
                        }
                    }
                }

                if let focusOn = exercise.focusOn, !focusOn.isEmpty {
                    Text("Focus: \(focusOn)")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                if !exercise.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(exercise.tags.sorted(by: { $0.rawValue < $1.rawValue })) { tag in
                                MetadataChip(title: tag.rawValue, systemImage: tag.icon, tint: tag.color)
                            }
                        }
                        .padding(.vertical, 2)
                    }
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
