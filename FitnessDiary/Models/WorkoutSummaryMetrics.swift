import Foundation

struct WorkoutSummaryMetrics {
    struct ExerciseBreakdown: Identifiable {
        let id: UUID
        let exerciseName: String
        let category: ExerciseCategory?
        let region: WorkoutBodyRegion
        let tonnage: Double
        let totalSets: Int
        let totalReps: Int
        let cardioDuration: TimeInterval
    }

    let tonnage: Double
    let cardioDuration: TimeInterval
    let exerciseCount: Int
    let upperBodyCount: Int
    let lowerBodyCount: Int
    let exerciseBreakdown: [ExerciseBreakdown]

    static let empty = WorkoutSummaryMetrics(
        tonnage: 0,
        cardioDuration: 0,
        exerciseCount: 0,
        upperBodyCount: 0,
        lowerBodyCount: 0,
        exerciseBreakdown: []
    )

    init(
        tonnage: Double,
        cardioDuration: TimeInterval,
        exerciseCount: Int,
        upperBodyCount: Int,
        lowerBodyCount: Int,
        exerciseBreakdown: [ExerciseBreakdown]
    ) {
        self.tonnage = tonnage
        self.cardioDuration = cardioDuration
        self.exerciseCount = exerciseCount
        self.upperBodyCount = upperBodyCount
        self.lowerBodyCount = lowerBodyCount
        self.exerciseBreakdown = exerciseBreakdown
    }

    init(card: WorkoutCard, userProfile: UserProfile?) {
        var tonnageAccumulator: Double = 0
        var cardioAccumulator: TimeInterval = 0
        var breakdownArray: [ExerciseBreakdown] = []

        for block in card.blocks.sorted(by: { $0.order < $1.order }) {
            for item in block.exerciseItems.sorted(by: { $0.order < $1.order }) {
                let metrics = WorkoutSummaryMetrics.metrics(for: item, userProfile: userProfile)
                tonnageAccumulator += metrics.tonnage
                cardioAccumulator += metrics.cardioDuration

                let breakdown = ExerciseBreakdown(
                    id: item.id,
                    exerciseName: item.exercise?.name ?? "Esercizio",
                    category: item.exercise?.category,
                    region: WorkoutSummaryMetrics.region(for: item.exercise),
                    tonnage: metrics.tonnage,
                    totalSets: metrics.totalSets,
                    totalReps: metrics.totalReps,
                    cardioDuration: metrics.cardioDuration
                )
                breakdownArray.append(breakdown)
            }
        }

        let upperCount = breakdownArray.filter { $0.region == .upper }.count
        let lowerCount = breakdownArray.filter { $0.region == .lower }.count

        self.init(
            tonnage: tonnageAccumulator,
            cardioDuration: cardioAccumulator,
            exerciseCount: breakdownArray.count,
            upperBodyCount: upperCount,
            lowerBodyCount: lowerCount,
            exerciseBreakdown: breakdownArray
        )
    }

    var hasTonnage: Bool { tonnage > 0 }
    var hasCardioDuration: Bool { cardioDuration > 0 }
}

enum WorkoutBodyRegion: String {
    case upper
    case lower
    case core
    case unknown

    var title: String {
        switch self {
        case .upper: return "Parte alta"
        case .lower: return "Parte bassa"
        case .core: return "Core"
        case .unknown: return "Altro"
        }
    }

    var icon: String {
        switch self {
        case .upper: return "figure.american.football"
        case .lower: return "figure.run"
        case .core: return "figure.core.training"
        case .unknown: return "questionmark.circle"
        }
    }
}

private extension WorkoutSummaryMetrics {
    static func metrics(for item: WorkoutExerciseItem, userProfile: UserProfile?) -> (tonnage: Double, cardioDuration: TimeInterval, totalReps: Int, totalSets: Int) {
        var tonnage: Double = 0
        var cardio: TimeInterval = 0
        var reps: Int = 0
        var sets: Int = 0

        for set in item.sets {
            switch set.setType {
            case .reps:
                sets += 1
                if let repValue = set.reps {
                    reps += repValue
                    if let weight = resolveWeight(for: set, exercise: item.exercise, userProfile: userProfile) {
                        tonnage += Double(repValue) * weight
                    }
                }
            case .duration:
                cardio += set.duration ?? 0
            }
        }

        return (tonnage, cardio, reps, sets)
    }

    static func resolveWeight(for set: WorkoutSet, exercise: Exercise?, userProfile: UserProfile?) -> Double? {
        switch set.actualLoadType {
        case .absolute:
            return set.weight
        case .percentage:
            guard let percentage = set.percentageOfMax,
                  let exercise,
                  let big5 = exercise.big5Exercise,
                  let profile = userProfile,
                  let oneRepMax = profile.getOneRepMax(for: big5) else {
                return nil
            }
            return (percentage / 100.0) * oneRepMax
        }
    }

    static func region(for exercise: Exercise?) -> WorkoutBodyRegion {
        guard let exercise else { return .unknown }
        let primaryRegions = exercise.primaryMuscles.map { $0.category.bodyRegion }

        if primaryRegions.contains(.lower) {
            return .lower
        }
        if primaryRegions.contains(.upper) {
            return .upper
        }
        if primaryRegions.contains(.core) {
            return .core
        }
        return .unknown
    }
}

extension MuscleCategory {
    var bodyRegion: WorkoutBodyRegion {
        switch self {
        case .quadriceps, .hamstrings, .glutes, .calves:
            return .lower
        case .abs:
            return .core
        default:
            return .upper
        }
    }
}
