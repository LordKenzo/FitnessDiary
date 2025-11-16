import Foundation

// MARK: - Temporary data structures for workout card editing
// These structures are used to manage workout card data before persisting to SwiftData

/// Temporary structure for editing a workout block
struct WorkoutBlockData: Identifiable {
    let id = UUID()
    var blockType: BlockType
    var methodType: MethodType?
    var order: Int
    var globalSets: Int
    var globalRestTime: TimeInterval?
    var notes: String?
    var exerciseItems: [WorkoutExerciseItemData]
}

/// Temporary structure for editing a workout exercise item within a block
struct WorkoutExerciseItemData: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var order: Int
    var sets: [WorkoutSetData]
    var notes: String?
    var restTime: TimeInterval?
}

/// Temporary structure for editing an individual workout set
struct WorkoutSetData: Identifiable {
    let id = UUID()
    var order: Int
    var setType: SetType
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var notes: String?
    var loadType: LoadType
    var percentageOfMax: Double?
}
