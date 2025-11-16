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
        List {
            if muscles.isEmpty {
                ContentUnavailableView {
                    Label("Nessun muscolo disponibile", systemImage: "figure.arms.open")
                } description: {
                    Text("Inizializza prima la libreria muscoli")
                }
            } else {
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

    private func toggleMuscle(_ muscle: Muscle) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.remove(muscle)
        } else {
            selectedMuscles.insert(muscle)
        }
    }
}

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let muscles: [Muscle]
    let equipment: [Equipment]

    @State private var name = ""
    @State private var description = ""
    @State private var biomechanicalStructure: BiomechanicalStructure = .multiJoint
    @State private var trainingRole: TrainingRole = .base
    @State private var primaryMetabolism: PrimaryMetabolism = .mixed
    @State private var category: ExerciseCategory = .training
    @State private var youtubeURL = ""
    @State private var selectedPrimaryMuscles: Set<Muscle> = []
    @State private var selectedSecondaryMuscles: Set<Muscle> = []
    @State private var selectedEquipment: Equipment?

    @State private var photoItem1: PhotosPickerItem?
    @State private var photoItem2: PhotosPickerItem?
    @State private var photoItem3: PhotosPickerItem?

    @State private var photoData1: Data?
    @State private var photoData2: Data?
    @State private var photoData3: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni Base") {
                    TextField("Nome esercizio", text: $name)

                    TextField("Descrizione (opzionale)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Tassonomia") {
                    Picker("Struttura Biomeccanica", selection: $biomechanicalStructure) {
                        ForEach(BiomechanicalStructure.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("Ruolo nell'Allenamento", selection: $trainingRole) {
                        ForEach(TrainingRole.allCases, id: \.self) { role in
                            Label(role.rawValue, systemImage: role.icon)
                                .tag(role)
                        }
                    }

                    Picker("Metabolismo Primario", selection: $primaryMetabolism) {
                        ForEach(PrimaryMetabolism.allCases, id: \.self) { metabolism in
                            Label(metabolism.rawValue, systemImage: metabolism.icon)
                                .tag(metabolism)
                        }
                    }

                    Picker("Categoria", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section("Attrezzo") {
                    Picker("Seleziona attrezzo (opzionale)", selection: $selectedEquipment) {
                        Text("Nessuno").tag(nil as Equipment?)
                        ForEach(equipment) { item in
                            Label(item.name, systemImage: item.category.icon)
                                .tag(item as Equipment?)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        MuscleSelectionView(
                            muscles: muscles,
                            selectedMuscles: $selectedPrimaryMuscles,
                            title: "Muscoli Primari"
                        )
                    } label: {
                        HStack {
                            Label("Muscoli Primari", systemImage: "star.fill")
                            Spacer()
                            if selectedPrimaryMuscles.isEmpty {
                                Text("Nessuno")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(selectedPrimaryMuscles.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !selectedPrimaryMuscles.isEmpty {
                        Text(selectedPrimaryMuscles.map { $0.name }.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    NavigationLink {
                        MuscleSelectionView(
                            muscles: muscles,
                            selectedMuscles: $selectedSecondaryMuscles,
                            title: "Muscoli Secondari"
                        )
                    } label: {
                        HStack {
                            Label("Muscoli Secondari", systemImage: "star.leadinghalf.filled")
                            Spacer()
                            if selectedSecondaryMuscles.isEmpty {
                                Text("Nessuno")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(selectedSecondaryMuscles.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !selectedSecondaryMuscles.isEmpty {
                        Text(selectedSecondaryMuscles.map { $0.name }.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Foto (Max 3)") {
                    PhotoPickerRow(title: "Foto 1", item: $photoItem1, photoData: $photoData1)
                    PhotoPickerRow(title: "Foto 2", item: $photoItem2, photoData: $photoData2)
                    PhotoPickerRow(title: "Foto 3", item: $photoItem3, photoData: $photoData3)
                }

                Section("Video") {
                    TextField("URL YouTube (opzionale)", text: $youtubeURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Nuovo Esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveExercise()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveExercise() {
        let exercise = Exercise(
            name: name,
            description: description.isEmpty ? nil : description,
            photo1Data: photoData1,
            photo2Data: photoData2,
            photo3Data: photoData3,
            biomechanicalStructure: biomechanicalStructure,
            trainingRole: trainingRole,
            primaryMetabolism: primaryMetabolism,
            category: category,
            youtubeURL: youtubeURL.isEmpty ? nil : youtubeURL,
            primaryMuscles: Array(selectedPrimaryMuscles),
            secondaryMuscles: Array(selectedSecondaryMuscles),
            equipment: selectedEquipment
        )
        modelContext.insert(exercise)
        dismiss()
    }
}

struct EditExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var exercise: Exercise
    let muscles: [Muscle]
    let equipment: [Equipment]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var selectedPrimaryMuscles: Set<Muscle> = []
    @State private var selectedSecondaryMuscles: Set<Muscle> = []
    @State private var photoItem1: PhotosPickerItem?
    @State private var photoItem2: PhotosPickerItem?
    @State private var photoItem3: PhotosPickerItem?
    @State private var showingAddVariant = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni Base") {
                    TextField("Nome esercizio", text: $exercise.name)

                    TextField("Descrizione (opzionale)", text: Binding(
                        get: { exercise.exerciseDescription ?? "" },
                        set: { exercise.exerciseDescription = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Tassonomia") {
                    Picker("Struttura Biomeccanica", selection: $exercise.biomechanicalStructure) {
                        ForEach(BiomechanicalStructure.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("Ruolo nell'Allenamento", selection: $exercise.trainingRole) {
                        ForEach(TrainingRole.allCases, id: \.self) { role in
                            Label(role.rawValue, systemImage: role.icon)
                                .tag(role)
                        }
                    }

                    Picker("Metabolismo Primario", selection: $exercise.primaryMetabolism) {
                        ForEach(PrimaryMetabolism.allCases, id: \.self) { metabolism in
                            Label(metabolism.rawValue, systemImage: metabolism.icon)
                                .tag(metabolism)
                        }
                    }

                    Picker("Categoria", selection: $exercise.category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section("Attrezzo") {
                    Picker("Seleziona attrezzo (opzionale)", selection: $exercise.equipment) {
                        Text("Nessuno").tag(nil as Equipment?)
                        ForEach(equipment) { item in
                            Label(item.name, systemImage: item.category.icon)
                                .tag(item as Equipment?)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        MuscleSelectionView(
                            muscles: muscles,
                            selectedMuscles: $selectedPrimaryMuscles,
                            title: "Muscoli Primari"
                        )
                    } label: {
                        HStack {
                            Label("Muscoli Primari", systemImage: "star.fill")
                            Spacer()
                            if selectedPrimaryMuscles.isEmpty {
                                Text("Nessuno")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(selectedPrimaryMuscles.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !selectedPrimaryMuscles.isEmpty {
                        Text(selectedPrimaryMuscles.map { $0.name }.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: selectedPrimaryMuscles) { _, newValue in
                    exercise.primaryMuscles = Array(newValue)
                }

                Section {
                    NavigationLink {
                        MuscleSelectionView(
                            muscles: muscles,
                            selectedMuscles: $selectedSecondaryMuscles,
                            title: "Muscoli Secondari"
                        )
                    } label: {
                        HStack {
                            Label("Muscoli Secondari", systemImage: "star.leadinghalf.filled")
                            Spacer()
                            if selectedSecondaryMuscles.isEmpty {
                                Text("Nessuno")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(selectedSecondaryMuscles.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !selectedSecondaryMuscles.isEmpty {
                        Text(selectedSecondaryMuscles.map { $0.name }.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: selectedSecondaryMuscles) { _, newValue in
                    exercise.secondaryMuscles = Array(newValue)
                }

                Section("Foto (Max 3)") {
                    PhotoEditorRow(
                        title: "Foto 1",
                        item: $photoItem1,
                        currentData: $exercise.photo1Data,
                        allPhotos: [exercise.photo1Data, exercise.photo2Data, exercise.photo3Data],
                        photoIndex: 0
                    )
                    PhotoEditorRow(
                        title: "Foto 2",
                        item: $photoItem2,
                        currentData: $exercise.photo2Data,
                        allPhotos: [exercise.photo1Data, exercise.photo2Data, exercise.photo3Data],
                        photoIndex: 1
                    )
                    PhotoEditorRow(
                        title: "Foto 3",
                        item: $photoItem3,
                        currentData: $exercise.photo3Data,
                        allPhotos: [exercise.photo1Data, exercise.photo2Data, exercise.photo3Data],
                        photoIndex: 2
                    )
                }

                Section {
                    if exercise.variants.isEmpty {
                        Text("Nessuna variante")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(exercise.variants) { variant in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(variant.name)
                                        .font(.body)
                                    if let equipment = variant.equipment {
                                        Text(equipment.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    removeVariant(variant)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Button {
                        showingAddVariant = true
                    } label: {
                        Label("Aggiungi Variante", systemImage: "plus.circle")
                    }
                    .disabled(exercise.variants.count >= 10)
                } header: {
                    HStack {
                        Text("Varianti (\(exercise.variants.count)/10)")
                        Spacer()
                        if !exercise.variants.isEmpty {
                            Text("Bidirezionale")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Video") {
                    TextField("URL YouTube (opzionale)", text: Binding(
                        get: { exercise.youtubeURL ?? "" },
                        set: { exercise.youtubeURL = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.URL)
                    .autocapitalization(.none)

                    if let urlString = exercise.youtubeURL,
                       let url = URL(string: urlString) {
                        Link(destination: url) {
                            Label("Apri Video", systemImage: "play.rectangle.fill")
                        }
                    }
                }

                Section {
                    Button("Elimina Esercizio", role: .destructive) {
                        deleteExercise()
                    }
                }
            }
            .navigationTitle("Modifica Esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedPrimaryMuscles = Set(exercise.primaryMuscles)
                selectedSecondaryMuscles = Set(exercise.secondaryMuscles)
            }
            .sheet(isPresented: $showingAddVariant) {
                AddVariantView(exercise: exercise, allExercises: allExercises)
            }
        }
    }

    private func removeVariant(_ variant: Exercise) {
        exercise.removeVariant(variant)
    }

    private func deleteExercise() {
        // Rimuovi questo esercizio da tutte le varianti degli altri esercizi
        for variant in exercise.variants {
            variant.variants.removeAll { $0.id == exercise.id }
        }

        modelContext.delete(exercise)
        dismiss()
    }
}

// MARK: - Add Variant View
struct AddVariantView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var exercise: Exercise
    let allExercises: [Exercise]

    private var availableExercises: [Exercise] {
        allExercises.filter { candidate in
            // Escludi l'esercizio stesso
            candidate.id != exercise.id &&
            // Escludi esercizi già nelle varianti
            !exercise.variants.contains(where: { $0.id == candidate.id })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableExercises.isEmpty {
                    ContentUnavailableView {
                        Label("Nessun esercizio disponibile", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Tutti gli esercizi sono già varianti o hai raggiunto il limite")
                    }
                } else {
                    ForEach(availableExercises) { candidate in
                        Button {
                            addVariant(candidate)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(candidate.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 8) {
                                        Label(candidate.trainingRole.rawValue, systemImage: candidate.trainingRole.icon)
                                            .font(.caption)
                                            .foregroundStyle(candidate.trainingRole.color)

                                        Label(candidate.category.rawValue, systemImage: candidate.category.icon)
                                            .font(.caption)
                                            .foregroundStyle(candidate.category.color)
                                    }

                                    if let equipment = candidate.equipment {
                                        HStack(spacing: 4) {
                                            Image(systemName: equipment.category.icon)
                                                .font(.caption2)
                                            Text(equipment.name)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Aggiungi Variante")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addVariant(_ variant: Exercise) {
        exercise.addVariant(variant)
        dismiss()
    }
}

// MARK: - Fullscreen Photo Viewer
struct FullscreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    let imageData: Data
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                // Reset if zoomed out too much
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                }
                                // Limit max zoom
                                if scale > 4.0 {
                                    withAnimation {
                                        scale = 4.0
                                        lastScale = 4.0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to reset zoom
                        withAnimation {
                            scale = 1.0
                            lastScale = 1.0
                        }
                    }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Multi-Photo Fullscreen Viewer
struct MultiPhotoFullscreenView: View {
    @Environment(\.dismiss) private var dismiss
    let photos: [Data]
    let initialIndex: Int
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    init(photos: [Data], initialIndex: Int = 0) {
        self.photos = photos
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    if let uiImage = UIImage(data: photos[index]) {
                        GeometryReader { geometry in
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .scaleEffect(scale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = lastScale * value
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            if scale < 1.0 {
                                                withAnimation {
                                                    scale = 1.0
                                                    lastScale = 1.0
                                                }
                                            }
                                            if scale > 4.0 {
                                                withAnimation {
                                                    scale = 4.0
                                                    lastScale = 4.0
                                                }
                                            }
                                        }
                                )
                                .onTapGesture(count: 2) {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onChange(of: currentIndex) { _, _ in
                // Reset zoom when changing photo
                scale = 1.0
                lastScale = 1.0
            }

            VStack {
                HStack {
                    if photos.count > 1 {
                        Text("\(currentIndex + 1) / \(photos.count)")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.5))
                            )
                            .padding()
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// Helper view per PhotoPicker nella AddExerciseView
struct PhotoPickerRow: View {
    let title: String
    @Binding var item: PhotosPickerItem?
    @Binding var photoData: Data?
    @State private var showingFullscreen = false

    var body: some View {
        HStack {
            if let data = photoData, let uiImage = UIImage(data: data) {
                Button {
                    showingFullscreen = true
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    HStack(spacing: 12) {
                        Button {
                            showingFullscreen = true
                        } label: {
                            Label("Visualizza", systemImage: "eye")
                                .font(.caption)
                        }

                        Button("Rimuovi", role: .destructive) {
                            photoData = nil
                            item = nil
                        }
                        .font(.caption)
                    }
                }
            } else {
                PhotosPicker(selection: $item, matching: .images) {
                    Label(title, systemImage: "photo")
                }
            }
        }
        .onChange(of: item) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullscreen) {
            if let data = photoData {
                FullscreenPhotoView(imageData: data)
            }
        }
    }
}

// Helper view per PhotoPicker nella EditExerciseView
struct PhotoEditorRow: View {
    let title: String
    @Binding var item: PhotosPickerItem?
    @Binding var currentData: Data?
    let allPhotos: [Data?]
    let photoIndex: Int
    @State private var showingFullscreen = false

    private var availablePhotos: [Data] {
        allPhotos.compactMap { $0 }
    }

    private var availablePhotoIndex: Int {
        let index = allPhotos.prefix(photoIndex + 1).compactMap { $0 }.count - 1
        return max(0, index)
    }

    var body: some View {
        HStack {
            if let data = currentData, let uiImage = UIImage(data: data) {
                Button {
                    showingFullscreen = true
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    HStack(spacing: 12) {
                        Button {
                            showingFullscreen = true
                        } label: {
                            Label("Visualizza", systemImage: "eye")
                                .font(.caption)
                        }

                        Button("Rimuovi", role: .destructive) {
                            currentData = nil
                            item = nil
                        }
                        .font(.caption)
                    }
                }
            } else {
                PhotosPicker(selection: $item, matching: .images) {
                    Label(title, systemImage: "photo")
                }
            }
        }
        .onChange(of: item) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    currentData = data
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullscreen) {
            if !availablePhotos.isEmpty {
                MultiPhotoFullscreenView(photos: availablePhotos, initialIndex: availablePhotoIndex)
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
