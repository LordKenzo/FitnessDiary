import SwiftUI

struct WorkoutBlockRow: View {
    let block: WorkoutBlock
    let order: Int

    var body: some View {
        HStack(spacing: 12) {
            // Order badge
            Text("\(order)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(blockColor)
                .clipShape(Circle())

            // Icon
            Image(systemName: blockIcon)
                .font(.title3)
                .foregroundStyle(blockColor)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(blockTitle)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let subtitle = subtitleText {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if block.blockType != .rest, let restTime = block.formattedRestTime {
                        if subtitleText != nil {
                            Text("•")
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(restTime)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                if let notes = block.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

private extension WorkoutBlockRow {
    var blockColor: Color {
        if block.blockType == .method, let method = block.methodType {
            return method.color
        } else if block.blockType == .rest {
            return .orange
        }
        return .blue
    }

    var blockIcon: String {
        if block.blockType == .method, let method = block.methodType {
            return method.icon
        } else if block.blockType == .rest {
            return "moon.zzz.fill"
        }
        return "figure.strengthtraining.traditional"
    }

    var blockTitle: String {
        switch block.blockType {
        case .method:
            return block.methodType?.rawValue ?? block.title
        case .rest:
            return BlockType.rest.rawValue
        case .simple:
            return block.title
        }
    }

    var subtitleText: String? {
        switch block.blockType {
        case .rest:
            return block.formattedRestTime ?? "Durata personalizzata"
        default:
            return block.subtitle
        }
    }
}

#Preview {
    let exercise = Exercise(
        name: "Panca Piana",
        biomechanicalStructure: .multiJoint,
        trainingRole: .fundamental,
        primaryMetabolism: .anaerobic,
        category: .training
    )

    let exerciseItem = WorkoutExerciseItem(
        order: 0,
        exercise: exercise,
        notes: nil,
        restTime: nil
    )
    exerciseItem.sets.append(WorkoutSet(order: 0, setType: .reps, reps: 10, weight: 80))
    exerciseItem.sets.append(WorkoutSet(order: 1, setType: .reps, reps: 8, weight: 85))
    exerciseItem.sets.append(WorkoutSet(order: 2, setType: .reps, reps: 6, weight: 90))

    let simpleBlock = WorkoutBlock(
        order: 0,
        blockType: .simple,
        globalSets: 3,
        globalRestTime: 90,
        exerciseItems: [exerciseItem]
    )

    let exercise2 = Exercise(
        name: "Panca Inclinata",
        biomechanicalStructure: .multiJoint,
        trainingRole: .base,
        primaryMetabolism: .anaerobic,
        category: .training
    )

    let exerciseItem2 = WorkoutExerciseItem(
        order: 0,
        exercise: exercise2,
        notes: nil,
        restTime: nil
    )
    let exerciseItem3 = WorkoutExerciseItem(
        order: 1,
        exercise: exercise2,
        notes: nil,
        restTime: nil
    )

    let methodBlock = WorkoutBlock(
        order: 1,
        blockType: .method,
        methodType: .superset,
        globalSets: 4,
        globalRestTime: 120,
        notes: "Superset petto",
        exerciseItems: [exerciseItem2, exerciseItem3]
    )

    let restBlock = WorkoutBlock(
        order: 2,
        blockType: .rest,
        globalRestTime: 90,
        notes: "Pausa tra i blocchi"
    )

    return List {
        WorkoutBlockRow(block: simpleBlock, order: 1)
        WorkoutBlockRow(block: methodBlock, order: 2)
        WorkoutBlockRow(block: restBlock, order: 3)
    }
}
