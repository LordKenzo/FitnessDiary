import Foundation
import SwiftData

@Model
final class OneRepMax: Identifiable {
    var id: UUID
    var exercise: Big5Exercise
    var weight: Double // peso in kg
    var recordedDate: Date

    init(exercise: Big5Exercise, weight: Double, recordedDate: Date = Date()) {
        self.id = UUID()
        self.exercise = exercise
        self.weight = weight
        self.recordedDate = recordedDate
    }
}
