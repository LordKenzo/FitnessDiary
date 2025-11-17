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
                .background(blockBadgeColor)
                .clipShape(Circle())

            // Icon
            Image(systemName: blockIcon)
                .font(.title3)
                .foregroundStyle(blockIconColor)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(block.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let restTime = block.formattedRestTime {
                        Text("•")
                            .foregroundStyle(.secondary)
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

    // MARK: - Helpers

    private var blockBadgeColor: Color {
        if block.blockType == .rest {
            return .orange
        } else if block.blockType == .method, let method = block.methodType {
            return method.color
        } else {
            return .blue
        }
    }

    private var blockIcon: String {
        if block.blockType == .rest {
            return "pause.circle.fill"
        } else if block.blockType == .method, let method = block.methodType {
            return method.icon
        } else {
            return "figure.strengthtraining.traditional"
        }
    }

    private var blockIconColor: Color {
        if block.blockType == .rest {
            return .orange
        } else if block.blockType == .method, let method = block.methodType {
            return method.color
        } else {
            return .blue
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

    return List {
        WorkoutBlockRow(block: simpleBlock, order: 1)
        WorkoutBlockRow(block: methodBlock, order: 2)
    }
}
