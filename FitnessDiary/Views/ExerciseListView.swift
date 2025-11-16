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
    @State private var filterMetabolicType: MetabolicType?
    @State private var filterExerciseType: ExerciseType?

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesMetabolic = filterMetabolicType == nil || exercise.metabolicType == filterMetabolicType
            let matchesExercise = filterExerciseType == nil || exercise.exerciseType == filterExerciseType
            return matchesSearch && matchesMetabolic && matchesExercise
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
                    Section("Tipo Metabolico") {
                        Button(action: { filterMetabolicType = nil }) {
                            Label("Tutti", systemImage: filterMetabolicType == nil ? "checkmark" : "")
                        }
                        ForEach(MetabolicType.allCases, id: \.self) { type in
                            Button(action: { filterMetabolicType = type }) {
                                Label(type.rawValue, systemImage: filterMetabolicType == type ? "checkmark" : type.icon)
                            }
                        }
                    }

                    Section("Tipo Esercizio") {
                        Button(action: { filterExerciseType = nil }) {
                            Label("Tutti", systemImage: filterExerciseType == nil ? "checkmark" : "")
                        }
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Button(action: { filterExerciseType = type }) {
                                Label(type.rawValue, systemImage: filterExerciseType == type ? "checkmark" : type.icon)
                            }
                        }
                    }

                    if filterMetabolicType != nil || filterExerciseType != nil {
                        Divider()
                        Button("Rimuovi Filtri", role: .destructive) {
                            filterMetabolicType = nil
                            filterExerciseType = nil
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
            modelContext.delete(filteredExercises[index])
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            // Anteprima foto o placeholder
            if let photoData = exercise.photo1Data,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
                    Label(exercise.metabolicType.rawValue, systemImage: exercise.metabolicType.icon)
                        .font(.caption)
                        .foregroundStyle(exercise.metabolicType.color)

                    Label(exercise.exerciseType.rawValue, systemImage: exercise.exerciseType.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            if exercise.youtubeURL != nil {
                Image(systemName: "video.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Muscle Group Selector Component
struct MuscleGroupSelector: View {
    let muscles: [Muscle]
    @Binding var selectedMuscles: Set<Muscle>
    let title: String
    let icon: String

    private var musclesByCategory: [MuscleCategory: [Muscle]] {
        Dictionary(grouping: muscles, by: { $0.category })
    }

    var body: some View {
        Section {
            if muscles.isEmpty {
                Text("Nessun muscolo disponibile")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(MuscleCategory.allCases, id: \.self) { category in
                    if let musclesInCategory = musclesByCategory[category], !musclesInCategory.isEmpty {
                        DisclosureGroup {
                            ForEach(musclesInCategory) { muscle in
                                Button {
                                    toggleMuscle(muscle)
                                } label: {
                                    HStack {
                                        Text(muscle.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedMuscles.contains(muscle) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        } header: {
            Label(title, systemImage: icon)
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
    @State private var metabolicType: MetabolicType = .mixed
    @State private var exerciseType: ExerciseType = .multiJoint
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

                Section("Tipologia") {
                    Picker("Tipo Metabolico", selection: $metabolicType) {
                        ForEach(MetabolicType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("Tipo Esercizio", selection: $exerciseType) {
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
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

                MuscleGroupSelector(
                    muscles: muscles,
                    selectedMuscles: $selectedPrimaryMuscles,
                    title: "Muscoli Primari",
                    icon: "star.fill"
                )

                MuscleGroupSelector(
                    muscles: muscles,
                    selectedMuscles: $selectedSecondaryMuscles,
                    title: "Muscoli Secondari",
                    icon: "star.leadinghalf.filled"
                )

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
            metabolicType: metabolicType,
            exerciseType: exerciseType,
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

    @State private var selectedPrimaryMuscles: Set<Muscle> = []
    @State private var selectedSecondaryMuscles: Set<Muscle> = []
    @State private var photoItem1: PhotosPickerItem?
    @State private var photoItem2: PhotosPickerItem?
    @State private var photoItem3: PhotosPickerItem?

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

                Section("Tipologia") {
                    Picker("Tipo Metabolico", selection: $exercise.metabolicType) {
                        ForEach(MetabolicType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("Tipo Esercizio", selection: $exercise.exerciseType) {
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
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

                MuscleGroupSelector(
                    muscles: muscles,
                    selectedMuscles: $selectedPrimaryMuscles,
                    title: "Muscoli Primari",
                    icon: "star.fill"
                )
                .onChange(of: selectedPrimaryMuscles) { _, newValue in
                    exercise.primaryMuscles = Array(newValue)
                }

                MuscleGroupSelector(
                    muscles: muscles,
                    selectedMuscles: $selectedSecondaryMuscles,
                    title: "Muscoli Secondari",
                    icon: "star.leadinghalf.filled"
                )
                .onChange(of: selectedSecondaryMuscles) { _, newValue in
                    exercise.secondaryMuscles = Array(newValue)
                }

                Section("Foto (Max 3)") {
                    PhotoEditorRow(
                        title: "Foto 1",
                        item: $photoItem1,
                        currentData: $exercise.photo1Data
                    )
                    PhotoEditorRow(
                        title: "Foto 2",
                        item: $photoItem2,
                        currentData: $exercise.photo2Data
                    )
                    PhotoEditorRow(
                        title: "Foto 3",
                        item: $photoItem3,
                        currentData: $exercise.photo3Data
                    )
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
        }
    }

    private func deleteExercise() {
        modelContext.delete(exercise)
        dismiss()
    }
}

// Helper view per PhotoPicker nella AddExerciseView
struct PhotoPickerRow: View {
    let title: String
    @Binding var item: PhotosPickerItem?
    @Binding var photoData: Data?

    var body: some View {
        HStack {
            if let data = photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading) {
                    Text(title)
                    Button("Rimuovi", role: .destructive) {
                        photoData = nil
                        item = nil
                    }
                    .font(.caption)
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
    }
}

// Helper view per PhotoPicker nella EditExerciseView
struct PhotoEditorRow: View {
    let title: String
    @Binding var item: PhotosPickerItem?
    @Binding var currentData: Data?

    var body: some View {
        HStack {
            if let data = currentData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading) {
                    Text(title)
                    Button("Rimuovi", role: .destructive) {
                        currentData = nil
                        item = nil
                    }
                    .font(.caption)
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
    }
}

#Preview {
    NavigationStack {
        ExerciseListView()
    }
    .modelContainer(for: [Exercise.self, Muscle.self, Equipment.self], inMemory: true)
}
