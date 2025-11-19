import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Muscle.name) private var muscles: [Muscle]

    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedTab: ExercisePickerTab = .categories
    @State private var showingFiltersSheet = false

    @State private var filterPrimaryMetabolism: PrimaryMetabolism?
    @State private var filterBiomechanicalStructure: BiomechanicalStructure?
    @State private var filterTrainingRole: TrainingRole?
    @State private var filterCategory: ExerciseCategory?
    @State private var filterPrimaryMuscle: Muscle?
    @State private var filterReferencePlane: ReferencePlane?
    @State private var filterMotorSchemas: Set<MotorSchema> = []
    @State private var filterTags: Set<ExerciseTag> = []
    @State private var filterFavoritesOnly = false

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
        .sorted { $0.name < $1.name }
    }

    private var favoriteExercises: [Exercise] {
        filteredExercises.filter { $0.isFavorite }
    }

    private var exercisesByCategory: [(ExerciseCategory, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises, by: { $0.category })
        return ExerciseCategory.allCases.compactMap { category in
            guard let exercises = grouped[category], !exercises.isEmpty else { return nil }
            return (category, exercises.sorted { $0.name < $1.name })
        }
    }

    private var displayedCount: Int {
        switch selectedTab {
        case .favorites: return favoriteExercises.count
        case .categories: return filteredExercises.count
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if selectedTab == .favorites {
                    ForEach(favoriteExercises) { exercise in
                        ExercisePickerRow(exercise: exercise) {
                            select(exercise)
                        }
                    }
                } else {
                    ForEach(exercisesByCategory, id: \.0.rawValue) { category, exercises in
                        Section {
                            ForEach(exercises) { exercise in
                                ExercisePickerRow(exercise: exercise) {
                                    select(exercise)
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if displayedCount == 0 {
                    ContentUnavailableView {
                        Label("Nessun esercizio trovato", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Aggiorna la ricerca o i filtri")
                    }
                    .padding()
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 12) {
                    Picker("Modalità", selection: $selectedTab) {
                        ForEach(ExercisePickerTab.allCases) { tab in
                            Label(tab.title, systemImage: tab.icon)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

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
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(.regularMaterial)
            }
            .searchable(text: $searchText, prompt: "Cerca esercizio")
            .navigationTitle("Seleziona Esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFiltersSheet = true
                    } label: {
                        Image(systemName: isAnyFilterActive() ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
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
        }
    }

    private func select(_ exercise: Exercise) {
        onSelect(exercise)
        dismiss()
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

private enum ExercisePickerTab: String, CaseIterable, Identifiable {
    case favorites
    case categories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .favorites: return "Preferiti"
        case .categories: return "Tutte"
        }
    }

    var icon: String {
        switch self {
        case .favorites: return "star.fill"
        case .categories: return "square.grid.2x2"
        }
    }
}

private struct ExercisePickerRow: View {
    let exercise: Exercise
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if exercise.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if let focusOn = exercise.focusOn, !focusOn.isEmpty {
                    Text(focusOn)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Image(systemName: exercise.trainingRole.icon)
                        .font(.caption2)
                        .foregroundStyle(exercise.trainingRole.color)
                    Image(systemName: exercise.category.icon)
                        .font(.caption2)
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

                if !exercise.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(exercise.tags.sorted(by: { $0.rawValue < $1.rawValue })) { tag in
                                MetadataChip(title: tag.rawValue, systemImage: tag.icon, tint: tag.color)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExercisePickerView(exercises: [], onSelect: { _ in })
}
