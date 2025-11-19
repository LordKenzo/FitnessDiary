import SwiftUI
import SwiftData
import PhotosUI

// Estensione per rendere Muscle conforme a Hashable
extension Muscle: Hashable {
    public static func == (lhs: Muscle, rhs: Muscle) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    @State private var selectedMotorSchemas: Set<MotorSchema> = []
    @State private var referencePlane: ReferencePlane?
    @State private var focusOn = ""
    @State private var selectedTags: Set<ExerciseTag> = []
    @State private var isFavorite = false
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

                    // Video
                    videoSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
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
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .appScreenBackground()
    }

    // MARK: - Sections
    private var informationSection: some View {
        SectionCard(title: "Informazioni Base") {
            VStack(spacing: 12) {
                TextField("Nome esercizio", text: $name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)
                    .padding(12)

                TextField("Descrizione (opzionale)", text: $description, axis: .vertical)
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
                Picker("Struttura Biomeccanica", selection: $biomechanicalStructure) {
                    ForEach(BiomechanicalStructure.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                Picker("Ruolo nell'Allenamento", selection: $trainingRole) {
                    ForEach(TrainingRole.allCases, id: \.self) { role in
                        Label(role.rawValue, systemImage: role.icon)
                            .tag(role)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                Picker("Metabolismo Primario", selection: $primaryMetabolism) {
                    ForEach(PrimaryMetabolism.allCases, id: \.self) { metabolism in
                        Label(metabolism.rawValue, systemImage: metabolism.icon)
                            .tag(metabolism)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                Picker("Categoria", selection: $category) {
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
                Picker("Piano di riferimento", selection: $referencePlane) {
                    Text("Nessuno").tag(nil as ReferencePlane?)
                    ForEach(ReferencePlane.allCases) { plane in
                        Label(plane.rawValue, systemImage: plane.icon)
                            .tag(plane as ReferencePlane?)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)

                TextField("Focus On (opzionale)", text: $focusOn, axis: .vertical)
                    .font(.subheadline)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .padding(12)

                Toggle("Segna come preferito", isOn: $isFavorite)
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
    }

    private var equipmentSection: some View {
        SectionCard(title: "Attrezzo") {
            Picker("Seleziona attrezzo (opzionale)", selection: $selectedEquipment) {
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
        }
    }

    private var photosSection: some View {
        SectionCard(title: "Foto (Max 3)") {
            VStack(spacing: 12) {
                PhotoPickerRow(
                    title: "Foto 1",
                    item: $photoItem1,
                    photoData: $photoData1,
                    photoData1: photoData1,
                    photoData2: photoData2,
                    photoData3: photoData3
                )
                PhotoPickerRow(
                    title: "Foto 2",
                    item: $photoItem2,
                    photoData: $photoData2,
                    photoData1: photoData1,
                    photoData2: photoData2,
                    photoData3: photoData3
                )
                PhotoPickerRow(
                    title: "Foto 3",
                    item: $photoItem3,
                    photoData: $photoData3,
                    photoData1: photoData1,
                    photoData2: photoData2,
                    photoData3: photoData3
                )
            }
        }
    }

    private var videoSection: some View {
        SectionCard(title: "Video") {
            TextField("URL YouTube (opzionale)", text: $youtubeURL)
                .font(.subheadline)
                .textFieldStyle(.plain)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding(12)
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
            motorSchemas: selectedMotorSchemas.sorted(by: { $0.rawValue < $1.rawValue }),
            referencePlane: referencePlane,
            focusOn: focusOn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : focusOn.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: selectedTags.sorted(by: { $0.rawValue < $1.rawValue }),
            isFavorite: isFavorite,
            primaryMuscles: Array(selectedPrimaryMuscles),
            secondaryMuscles: Array(selectedSecondaryMuscles),
            equipment: selectedEquipment
        )
        modelContext.insert(exercise)
        dismiss()
    }
}

// MARK: - Photo Picker Row
struct PhotoPickerRow: View {
    let title: String
    @Binding var item: PhotosPickerItem?
    @Binding var photoData: Data?
    let photoData1: Data?
    let photoData2: Data?
    let photoData3: Data?
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
                photoData = nil
                item = nil
            } label: {
                Label("Elimina", systemImage: "trash")
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
            let allPhotos = [photoData1, photoData2, photoData3].compactMap { $0 }
            if allPhotos.count > 1, let currentPhotoData = photoData, let currentIndex = allPhotos.firstIndex(of: currentPhotoData) {
                MultiPhotoFullscreenView(photos: allPhotos, initialIndex: currentIndex)
            } else if let data = photoData {
                FullscreenPhotoView(imageData: data)
            }
        }
    }
}
