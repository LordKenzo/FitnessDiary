import Foundation
import SwiftData
import SwiftUI

@Model
final class Exercise: Identifiable {
    var id: UUID
    var name: String
    var exerciseDescription: String?

    // Foto (max 3)
    @Attribute(.externalStorage) var photo1Data: Data?
    @Attribute(.externalStorage) var photo2Data: Data?
    @Attribute(.externalStorage) var photo3Data: Data?

    // Tassonomia esercizio
    var biomechanicalStructure: BiomechanicalStructure
    var trainingRole: TrainingRole
    var primaryMetabolism: PrimaryMetabolism
    var category: ExerciseCategory

    // URL YouTube
    var youtubeURL: String?

    // Relazione con muscoli target
    var primaryMuscles: [Muscle]
    var secondaryMuscles: [Muscle]

    // Attrezzo primario (opzionale)
    var equipment: Equipment?

    // Varianti dell'esercizio (max 10, relazione bidirezionale)
    var variants: [Exercise]

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        photo1Data: Data? = nil,
        photo2Data: Data? = nil,
        photo3Data: Data? = nil,
        biomechanicalStructure: BiomechanicalStructure = .multiJoint,
        trainingRole: TrainingRole = .base,
        primaryMetabolism: PrimaryMetabolism = .mixed,
        category: ExerciseCategory = .training,
        youtubeURL: String? = nil,
        primaryMuscles: [Muscle] = [],
        secondaryMuscles: [Muscle] = [],
        equipment: Equipment? = nil,
        variants: [Exercise] = []
    ) {
        self.id = id
        self.name = name
        self.exerciseDescription = description
        self.photo1Data = photo1Data
        self.photo2Data = photo2Data
        self.photo3Data = photo3Data
        self.biomechanicalStructure = biomechanicalStructure
        self.trainingRole = trainingRole
        self.primaryMetabolism = primaryMetabolism
        self.category = category
        self.youtubeURL = youtubeURL
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.variants = variants
    }

    // Helper per aggiungere una variante (bidirezionale)
    func addVariant(_ variant: Exercise) {
        // Previeni duplicati e auto-referenza
        guard variant.id != self.id,
              !variants.contains(where: { $0.id == variant.id }),
              variants.count < 10 else { return }

        variants.append(variant)

        // Aggiungi reciprocamente (solo se non già presente)
        if !variant.variants.contains(where: { $0.id == self.id }) {
            variant.variants.append(self)
        }
    }

    // Helper per rimuovere una variante (bidirezionale)
    func removeVariant(_ variant: Exercise) {
        variants.removeAll { $0.id == variant.id }

        // Rimuovi reciprocamente
        variant.variants.removeAll { $0.id == self.id }
    }

    // Helper per ottenere le foto come UIImage
    var photos: [UIImage] {
        var images: [UIImage] = []
        if let data = photo1Data, let image = UIImage(data: data) {
            images.append(image)
        }
        if let data = photo2Data, let image = UIImage(data: data) {
            images.append(image)
        }
        if let data = photo3Data, let image = UIImage(data: data) {
            images.append(image)
        }
        return images
    }

    var hasPhotos: Bool {
        photo1Data != nil || photo2Data != nil || photo3Data != nil
    }
}

// MARK: - 1. Struttura Biomeccanica
enum BiomechanicalStructure: String, Codable, CaseIterable {
    case singleJoint = "Monoarticolare"
    case multiJoint = "Multiarticolare"

    var icon: String {
        switch self {
        case .singleJoint: return "circle.fill"
        case .multiJoint: return "circles.hexagongrid.fill"
        }
    }
}

// MARK: - 2. Ruolo nell'Allenamento
enum TrainingRole: String, Codable, CaseIterable {
    case fundamental = "Fondamentale"
    case base = "Base"
    case accessory = "Accessorio"
    case technicalSpecific = "Tecnico Specifico"

    var icon: String {
        switch self {
        case .fundamental: return "star.fill"
        case .base: return "square.stack.3d.up.fill"
        case .accessory: return "wrench.and.screwdriver.fill"
        case .technicalSpecific: return "target"
        }
    }

    var color: Color {
        switch self {
        case .fundamental: return .orange
        case .base: return .green
        case .accessory: return .cyan
        case .technicalSpecific: return .indigo
        }
    }
}

// MARK: - 3. Metabolismo Primario
enum PrimaryMetabolism: String, Codable, CaseIterable {
    case aerobic = "Aerobico"
    case anaerobic = "Anaerobico"
    case mixed = "Misto"

    var icon: String {
        switch self {
        case .aerobic: return "wind"
        case .anaerobic: return "bolt.fill"
        case .mixed: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .aerobic: return .blue
        case .anaerobic: return .red
        case .mixed: return .purple
        }
    }
}

// MARK: - 4. Categoria/Contesto
enum ExerciseCategory: String, Codable, CaseIterable {
    case training = "Allenamento"
    case warmup = "Riscaldamento"
    case stretching = "Stretching"
    case mobility = "Mobilità"
    case breathing = "Respirazione"
    case other = "Altro"

    var icon: String {
        switch self {
        case .training: return "figure.strengthtraining.traditional"
        case .warmup: return "flame.fill"
        case .stretching: return "figure.flexibility"
        case .mobility: return "figure.roll"
        case .breathing: return "lungs.fill"
        case .other: return "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .training: return .primary
        case .warmup: return .orange
        case .stretching: return .mint
        case .mobility: return .teal
        case .breathing: return .cyan
        case .other: return .gray
        }
    }
}
