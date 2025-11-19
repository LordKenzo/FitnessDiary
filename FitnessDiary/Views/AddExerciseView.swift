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
                Section("Piano di riferimento e Focus") {
                    Picker("Piano di riferimento", selection: $referencePlane) {
                        Text("Nessuno").tag(nil as ReferencePlane?)
                        ForEach(ReferencePlane.allCases) { plane in
                            Label(plane.rawValue, systemImage: plane.icon)
                                .tag(plane as ReferencePlane?)
                        }
                    }
                    TextField("Focus On (opzionale)", text: $focusOn, axis: .vertical)
                        .lineLimit(1...3)
                    Toggle("Segna come preferito", isOn: $isFavorite)
                }
                Section("Schemi Motori (max 3)") {
                    NavigationLink {
                        MotorSchemaSelectionView(selection: $selectedMotorSchemas)
                    } label: {
                        HStack {
                            Label("Schemi Motori", systemImage: "square.grid.3x3")
                            Spacer()
                            Text(selectedMotorSchemas.isEmpty ? "Nessuno" : "\(selectedMotorSchemas.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !selectedMotorSchemas.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedMotorSchemas.sorted(by: { $0.rawValue < $1.rawValue })) { schema in
                                    MetadataChip(title: schema.rawValue, systemImage: schema.icon, tint: schema.color)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                Section("Tag esercizio") {
                    NavigationLink {
                        ExerciseTagSelectionView(selection: $selectedTags)
                    } label: {
                        HStack {
                            Label("Tag", systemImage: "tag")
                            Spacer()
                            Text(selectedTags.isEmpty ? "Nessuno" : "\(selectedTags.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedTags.sorted(by: { $0.rawValue < $1.rawValue })) { tag in
                                    MetadataChip(title: tag.rawValue, systemImage: tag.icon, tint: tag.color)
                                }
                            }
                            .padding(.vertical, 4)
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
