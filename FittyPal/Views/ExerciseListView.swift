import SwiftUI
import SwiftData
import PhotosUI

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Muscle.name) private var muscles: [Muscle]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingAddExercise = false
    @State private var quickLookExercise: Exercise?
    @State private var editingExercise: Exercise?
    @State private var searchText = ""
    @State private var filterPrimaryMetabolism: PrimaryMetabolism?
    @State private var filterBiomechanicalStructure: BiomechanicalStructure?
    @State private var filterTrainingRole: TrainingRole?
    @State private var filterCategory: ExerciseCategory?
    @State private var filterPrimaryMuscle: Muscle?
    @State private var filterReferencePlane: ReferencePlane?
    @State private var filterMotorSchemas: Set<MotorSchema> = []
    @State private var filterTags: Set<ExerciseTag> = []
    @State private var filterFavoritesOnly = false
    @State private var showingFiltersSheet = false
    
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            (exercise.focusOn?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesMetabolism = filterPrimaryMetabolism == nil || exercise.primaryMetabolism == filterPrimaryMetabolism
            let matchesBiomechanical = filterBiomechanicalStructure == nil || exercise.biomechanicalStructure == filterBiomechanicalStructure
            let matchesRole = filterTrainingRole == nil || exercise.trainingRole == filterTrainingRole
            let matchesCategory = filterCategory == nil || exercise.category == filterCategory
            let matchesPrimaryMuscle = filterPrimaryMuscle == nil || exercise.primaryMuscles.contains(where: { $0.id == filterPrimaryMuscle!.id })
            let matchesReferencePlane = filterReferencePlane == nil || exercise.referencePlane == filterReferencePlane
            let matchesMotorSchemas = filterMotorSchemas.isEmpty || !Set(exercise.motorSchemas).isDisjoint(with: filterMotorSchemas)
            let matchesTags = filterTags.isEmpty || !Set(exercise.tags).isDisjoint(with: filterTags)
            let matchesFavorite = !filterFavoritesOnly || exercise.isFavorite

            return matchesSearch && matchesMetabolism && matchesBiomechanical && matchesRole && matchesCategory && matchesPrimaryMuscle && matchesReferencePlane && matchesMotorSchemas && matchesTags && matchesFavorite
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18, pinnedViews: []) {
                if exercises.isEmpty {
                    GlassEmptyStateCard(
                        systemImage: "figure.strengthtraining.traditional",
                        title: L("exercises.no.exercises"),
                        description: L("exercises.no.exercises.description")
                    ) {
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
                                quickLookExercise = exercise
                            }
                            .overlay(alignment: .topTrailing) {
                                menuButton(for: exercise)
                                    .padding(18)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .searchable(text: $searchText, prompt: L("exercises.search"))
        .safeAreaInset(edge: .top) {
            if isAnyFilterActive() {
                ExerciseFiltersSummaryBar(
                    filterPrimaryMuscle: $filterPrimaryMuscle,
                    filterPrimaryMetabolism: $filterPrimaryMetabolism,
                    filterBiomechanicalStructure: $filterBiomechanicalStructure,
                    filterTrainingRole: $filterTrainingRole,
                    filterCategory: $filterCategory,
                    filterReferencePlane: $filterReferencePlane,
                    filterMotorSchemas: $filterMotorSchemas,
                    filterTags: $filterTags,
                    filterFavoritesOnly: $filterFavoritesOnly,
                    onClearAll: removeAllFilters
                )
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(AppTheme.stroke(for: colorScheme), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle(L("exercises.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showingFiltersSheet = true
                    } label: {
                        Image(systemName: isAnyFilterActive() ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(muscles: muscles, equipment: equipment)
        }
        .sheet(item: $quickLookExercise) { exercise in
            ExerciseQuickLookView(exercise: exercise)
        }
        .sheet(item: $editingExercise) { exercise in
            EditExerciseView(exercise: exercise, muscles: muscles, equipment: equipment)
        }
        .sheet(isPresented: $showingFiltersSheet) {
            ExerciseFiltersView(
                filterPrimaryMetabolism: $filterPrimaryMetabolism,
                filterBiomechanicalStructure: $filterBiomechanicalStructure,
                filterTrainingRole: $filterTrainingRole,
                filterCategory: $filterCategory,
                filterPrimaryMuscle: $filterPrimaryMuscle,
                filterReferencePlane: $filterReferencePlane,
                filterMotorSchemas: $filterMotorSchemas,
                filterTags: $filterTags,
                filterFavoritesOnly: $filterFavoritesOnly,
                muscles: muscles,
                onClearAll: removeAllFilters
            )
        }
        .appScreenBackground()
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        for variant in exercise.variants {
            variant.variants.removeAll { $0.id == exercise.id }
        }
        modelContext.delete(exercise)
    }

    @ViewBuilder
    private func menuButton(for exercise: Exercise) -> some View {
        Menu {
            Button(L("common.edit")) {
                editingExercise = exercise
            }

            Button(role: .destructive) {
                deleteExercise(exercise)
            } label: {
                Label(L("common.delete"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private func removeAllFilters() {
        filterPrimaryMetabolism = nil
        filterBiomechanicalStructure = nil
        filterTrainingRole = nil
        filterCategory = nil
        filterPrimaryMuscle = nil
        filterReferencePlane = nil
        filterMotorSchemas.removeAll()
        filterTags.removeAll()
        filterFavoritesOnly = false
    }

    private func isAnyFilterActive() -> Bool {
        return filterPrimaryMetabolism != nil ||
        filterBiomechanicalStructure != nil ||
        filterTrainingRole != nil ||
        filterCategory != nil ||
        filterPrimaryMuscle != nil ||
        filterReferencePlane != nil ||
        !filterMotorSchemas.isEmpty ||
        !filterTags.isEmpty ||
        filterFavoritesOnly
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    let exercise: Exercise
    @State private var showingFullscreenPhoto = false
    @Environment(\.colorScheme) private var colorScheme

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
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.stroke(for: colorScheme), lineWidth: 1)
                )
        )
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
