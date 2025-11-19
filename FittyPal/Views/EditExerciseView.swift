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
    @State private var selectedMotorSchemas: Set<MotorSchema> = []
    @State private var selectedTags: Set<ExerciseTag> = []
    @State private var photoItem1: PhotosPickerItem?
    @State private var photoItem2: PhotosPickerItem?
    @State private var photoItem3: PhotosPickerItem?
    @State private var showingAddVariant = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Informazioni Base
                    informationSection

                    // Tassonomia
                    taxonomySection

                    // Piano e Focus
                    planeAndFocusSection

                    // Schemi Motori
                    motorSchemasSection

                    // Tag
                    tagsSection

                    // Attrezzo
                    equipmentSection

                    // Muscoli
                    musclesSection

                    // Foto
                    photosSection

                    // Varianti
                    variantsSection

                    // Video
                    videoSection

                    // Delete Button
                    deleteSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Modifica Esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedPrimaryMuscles = Set(exercise.primaryMuscles)
                selectedSecondaryMuscles = Set(exercise.secondaryMuscles)
                selectedMotorSchemas = Set(exercise.motorSchemas)
                selectedTags = Set(exercise.tags)
            }
            .sheet(isPresented: $showingAddVariant) {
                AddVariantView(exercise: exercise, allExercises: allExercises)
            }
        }
        .appScreenBackground()
    }

    // MARK: - Sections
    private var informationSection: some View {
        SectionCard(title: "Informazioni Base") {
            VStack(spacing: 12) {
                TextField("Nome esercizio", text: $exercise.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)
                    .padding(12)

                TextField("Descrizione (opzionale)", text: Binding(
                    get: { exercise.exerciseDescription ?? "" },
                    set: { exercise.exerciseDescription = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                    .font(.subheadline)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .padding(12)
            }
        }
    }

    private var taxonomySection: some View {
        SectionCard(title: "Tassonomia") {
            VStack(spacing: 12) {
                Picker("Struttura Biomeccanica", selection: $exercise.biomechanicalStructure) {
                    ForEach(BiomechanicalStructure.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                Picker("Ruolo nell'Allenamento", selection: $exercise.trainingRole) {
                    ForEach(TrainingRole.allCases, id: \.self) { role in
                        Label(role.rawValue, systemImage: role.icon)
                            .tag(role)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                Picker("Metabolismo Primario", selection: $exercise.primaryMetabolism) {
                    ForEach(PrimaryMetabolism.allCases, id: \.self) { metabolism in
                        Label(metabolism.rawValue, systemImage: metabolism.icon)
                            .tag(metabolism)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                Picker("Categoria", selection: $exercise.category) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon)
                            .tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
            }
        }
    }

    private var planeAndFocusSection: some View {
        SectionCard(title: "Piano di riferimento e Focus") {
            VStack(spacing: 12) {
                Picker("Piano di riferimento", selection: Binding(
                    get: { exercise.referencePlane },
                    set: { exercise.referencePlane = $0 }
                )) {
                    Text("Nessuno").tag(nil as ReferencePlane?)
                    ForEach(ReferencePlane.allCases) { plane in
                        Label(plane.rawValue, systemImage: plane.icon)
                            .tag(plane as ReferencePlane?)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                TextField("Focus On (opzionale)", text: Binding(
                    get: { exercise.focusOn ?? "" },
                    set: { exercise.focusOn = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                ), axis: .vertical)
                    .font(.subheadline)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .padding(12)

                Toggle("Segna come preferito", isOn: $exercise.isFavorite)
                    .padding(12)
            }
        }
    }

    private var motorSchemasSection: some View {
        SectionCard(title: "Schemi Motori (max 3)") {
            VStack(spacing: 12) {
                NavigationLink {
                    MotorSchemaSelectionView(selection: $selectedMotorSchemas)
                } label: {
                    HStack {
                        Label("Schemi Motori", systemImage: "square.grid.3x3")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedMotorSchemas.isEmpty ? "Nessuno" : "\(selectedMotorSchemas.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                }
                .buttonStyle(.plain)

                if !selectedMotorSchemas.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedMotorSchemas.sorted(by: { $0.rawValue < $1.rawValue })) { schema in
                                MetadataChip(title: schema.rawValue, systemImage: schema.icon, tint: schema.color)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: selectedMotorSchemas) { _, newValue in
            exercise.motorSchemas = newValue.sorted(by: { $0.rawValue < $1.rawValue })
        }
    }

    private var tagsSection: some View {
        SectionCard(title: "Tag esercizio") {
            VStack(spacing: 12) {
                NavigationLink {
                    ExerciseTagSelectionView(selection: $selectedTags)
                } label: {
                    HStack {
                        Label("Tag", systemImage: "tag")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedTags.isEmpty ? "Nessuno" : "\(selectedTags.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                }
                .buttonStyle(.plain)

                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedTags.sorted(by: { $0.rawValue < $1.rawValue })) { tag in
                                MetadataChip(title: tag.rawValue, systemImage: tag.icon, tint: tag.color)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: selectedTags) { _, newValue in
            exercise.tags = newValue.sorted(by: { $0.rawValue < $1.rawValue })
        }
    }

    private var equipmentSection: some View {
        SectionCard(title: "Attrezzo") {
            Picker("Seleziona attrezzo (opzionale)", selection: $exercise.equipment) {
                Text("Nessuno").tag(nil as Equipment?)
                ForEach(equipment) { item in
                    Label(item.name, systemImage: item.category.icon)
                        .tag(item as Equipment?)
                }
            }
            .pickerStyle(.menu)
            .padding(12)
        }
    }

    private var musclesSection: some View {
        VStack(spacing: 20) {
            SectionCard(title: "Muscoli Primari") {
                VStack(spacing: 12) {
                    NavigationLink {
                        MuscleSelectionView(
                            muscles: muscles,
                            selectedMuscles: $selectedPrimaryMuscles,
                            title: "Muscoli Primari"
                        )
                    } label: {
                        HStack {
                            Label("Muscoli Primari", systemImage: "star.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedPrimaryMuscles.isEmpty ? "Nessuno" : "\(selectedPrimaryMuscles.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                    }
                    .buttonStyle(.plain)

                    if !selectedPrimaryMuscles.isEmpty {
                        Text(selectedPrimaryMuscles.map { $0.name }.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .onChange(of: selectedPrimaryMuscles) { _, newValue in
                exercise.primaryMuscles = Array(newValue)
            }

            SectionCard(title: "Muscoli Secondari") {
                VStack(spacing: 12) {
                    NavigationLink {
                        MuscleSelectionView(
                            muscles: muscles,
                            selectedMuscles: $selectedSecondaryMuscles,
                            title: "Muscoli Secondari"
                        )
                    } label: {
                        HStack {
                            Label("Muscoli Secondari", systemImage: "star.leadinghalf.filled")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedSecondaryMuscles.isEmpty ? "Nessuno" : "\(selectedSecondaryMuscles.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                    }
                    .buttonStyle(.plain)

                    if !selectedSecondaryMuscles.isEmpty {
                        Text(selectedSecondaryMuscles.map { $0.name }.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .onChange(of: selectedSecondaryMuscles) { _, newValue in
                exercise.secondaryMuscles = Array(newValue)
            }
        }
    }

    private var photosSection: some View {
        SectionCard(title: "Foto (Max 3)") {
            VStack(spacing: 12) {
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
        }
    }

    private var variantsSection: some View {
        SectionCard(title: "Varianti (\(exercise.variants.count)/10)") {
            VStack(spacing: 12) {
                if exercise.variants.isEmpty {
                    Text("Nessuna variante")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                } else {
                    ForEach(exercise.variants) { variant in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(variant.name)
                                    .font(.body)
                                    .fontWeight(.medium)
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
                                Image(systemName: "trash.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                    }
                }

                Button {
                    showingAddVariant = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Aggiungi Variante", systemImage: "plus.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .disabled(exercise.variants.count >= 10)
            }
        }
    }

    private var videoSection: some View {
        SectionCard(title: "Video") {
            VStack(spacing: 12) {
                TextField("URL YouTube (opzionale)", text: Binding(
                    get: { exercise.youtubeURL ?? "" },
                    set: { exercise.youtubeURL = $0.isEmpty ? nil : $0 }
                ))
                .font(.subheadline)
                .textFieldStyle(.plain)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding(12)

                if let urlString = exercise.youtubeURL,
                   let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Spacer()
                            Label("Apri Video", systemImage: "play.rectangle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            deleteExercise()
        } label: {
            HStack {
                Spacer()
                Label("Elimina Esercizio", systemImage: "trash")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
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
