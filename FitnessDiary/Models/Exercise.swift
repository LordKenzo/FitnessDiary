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

    var metabolicType: MetabolicType
    var exerciseType: ExerciseType

    // URL YouTube
    var youtubeURL: String?

    // Relazione con muscoli target
    var targetMuscles: [Muscle]

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        photo1Data: Data? = nil,
        photo2Data: Data? = nil,
        photo3Data: Data? = nil,
        metabolicType: MetabolicType,
        exerciseType: ExerciseType,
        youtubeURL: String? = nil,
        targetMuscles: [Muscle] = []
    ) {
        self.id = id
        self.name = name
        self.exerciseDescription = description
        self.photo1Data = photo1Data
        self.photo2Data = photo2Data
        self.photo3Data = photo3Data
        self.metabolicType = metabolicType
        self.exerciseType = exerciseType
        self.youtubeURL = youtubeURL
        self.targetMuscles = targetMuscles
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

enum MetabolicType: String, Codable, CaseIterable {
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

enum ExerciseType: String, Codable, CaseIterable {
    case singleJoint = "Monoarticolare"
    case multiJoint = "Poliarticolare"

    var icon: String {
        switch self {
        case .singleJoint: return "circle.fill"
        case .multiJoint: return "circles.hexagongrid.fill"
        }
    }
}
