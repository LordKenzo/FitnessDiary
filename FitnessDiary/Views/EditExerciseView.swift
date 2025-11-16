import SwiftUI
import SwiftData
import PhotosUI

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

// MARK: - Photo Editor Row
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
                    }
                }
            } else {
                PhotosPicker(selection: $item, matching: .images) {
                    Label(title, systemImage: "photo")
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                currentData = nil
                item = nil
            } label: {
                Label("Elimina", systemImage: "trash")
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
