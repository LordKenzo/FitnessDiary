import Foundation
import SwiftData

enum WorkoutMood: Int, CaseIterable, Codable, Identifiable {
    case exhausted
    case tired
    case neutral
    case happy
    case unstoppable

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .exhausted: return "Distrutto"
        case .tired: return "Affaticato"
        case .neutral: return "Ok"
        case .happy: return "Carico"
        case .unstoppable: return "Inarrestabile"
        }
    }

    var emoji: String {
        switch self {
        case .exhausted: return "😵‍💫"
        case .tired: return "🥵"
        case .neutral: return "🙂"
        case .happy: return "😃"
        case .unstoppable: return "🤩"
        }
    }
}

@Model
final class WorkoutSessionLog: Identifiable {
    var id: UUID
    var date: Date
    var notes: String
    var moodRawValue: Int
    var rpe: Int?
    var durationSeconds: TimeInterval
    var cardName: String
    @Relationship(deleteRule: .nullify)
    var card: WorkoutCard?

    init(
        card: WorkoutCard?,
        cardName: String,
        notes: String,
        mood: WorkoutMood,
        rpe: Int?,
        durationSeconds: TimeInterval,
        date: Date = .now
    ) {
        self.id = UUID()
        self.card = card
        self.cardName = cardName
        self.notes = notes
        self.moodRawValue = mood.rawValue
        self.rpe = rpe
        self.durationSeconds = durationSeconds
        self.date = date
    }

    var mood: WorkoutMood {
        get { WorkoutMood(rawValue: moodRawValue) ?? .neutral }
        set { moodRawValue = newValue.rawValue }
    }
}
