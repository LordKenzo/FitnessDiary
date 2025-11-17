import Foundation

/// Helper class for shared WorkoutBlock logic between Add and Edit views
class WorkoutBlockHelper {

    /// Adds a simple exercise block to the blocks array
    static func addSimpleBlock(to blocks: inout [WorkoutBlockData], exercise: Exercise) {
        let exerciseItem = WorkoutExerciseItemData(
            exercise: exercise,
            order: 0,
            sets: [WorkoutSetData(order: 0, setType: .reps, reps: 10, weight: nil, loadType: .absolute, percentageOfMax: nil)]
        )

        let newBlock = WorkoutBlockData(
            blockType: .simple,
            methodType: nil,
            order: blocks.count,
            globalSets: 3,
            globalRestTime: 90,
            recoveryAfterBlock: nil,  // Opzionale, default nessun rest
            notes: nil,
            exerciseItems: [exerciseItem]
        )
        blocks.append(newBlock)
    }

    /// Adds a method block to the blocks array
    static func addMethodBlock(to blocks: inout [WorkoutBlockData], method: MethodType) {
        let newBlock = WorkoutBlockData(
            blockType: .method,
            methodType: method,
            order: blocks.count,
            globalSets: 3,
            globalRestTime: 120,
            recoveryAfterBlock: nil,  // Opzionale, default nessun rest
            notes: nil,
            exerciseItems: []
        )
        blocks.append(newBlock)
    }

    /// Adds a rest block to the blocks array
    static func addRestBlock(to blocks: inout [WorkoutBlockData], duration: TimeInterval = 120) {
        let newBlock = WorkoutBlockData(
            blockType: .rest,
            methodType: nil,
            order: blocks.count,
            globalSets: 1,  // Non usato per blocchi REST
            globalRestTime: duration,  // Durata del blocco REST
            recoveryAfterBlock: nil,
            notes: nil,
            exerciseItems: []  // Blocco REST non ha esercizi
        )
        blocks.append(newBlock)
    }

    /// Moves a block from one position to another and updates order indices
    static func moveBlock(in blocks: inout [WorkoutBlockData], from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
        for (index, _) in blocks.enumerated() {
            blocks[index].order = index
        }
    }

    /// Deletes blocks at specified indices and updates order indices
    static func deleteBlock(in blocks: inout [WorkoutBlockData], at offsets: IndexSet) {
        blocks.remove(atOffsets: offsets)
        for (index, _) in blocks.enumerated() {
            blocks[index].order = index
        }
    }

    /// Converts WorkoutBlockData to WorkoutBlock for preview/display
    static func workoutBlockToModel(_ blockData: WorkoutBlockData) -> WorkoutBlock {
        let block = WorkoutBlock(
            order: blockData.order,
            blockType: blockData.blockType,
            methodType: blockData.methodType,
            globalSets: blockData.globalSets,
            globalRestTime: blockData.globalRestTime,
            recoveryAfterBlock: blockData.recoveryAfterBlock,
            notes: blockData.notes,
            tabataWorkDuration: blockData.tabataWorkDuration,
            tabataRestDuration: blockData.tabataRestDuration,
            tabataRounds: blockData.tabataRounds,
            tabataRecoveryBetweenRounds: blockData.tabataRecoveryBetweenRounds,
            exerciseItems: []
        )

        for itemData in blockData.exerciseItems {
            let exerciseItem = WorkoutExerciseItem(
                order: itemData.order,
                exercise: itemData.exercise,
                notes: itemData.notes,
                restTime: itemData.restTime,
                targetExpression: itemData.targetExpression
            )

            for setData in itemData.sets {
                let workoutSet = WorkoutSet(
                    order: setData.order,
                    setType: setData.setType,
                    reps: setData.reps,
                    weight: setData.weight,
                    duration: setData.duration,
                    notes: setData.notes,
                    loadType: setData.loadType,
                    percentageOfMax: setData.percentageOfMax,
                    clusterSize: setData.clusterSize,
                    clusterRestTime: setData.clusterRestTime,
                    clusterProgression: setData.clusterProgression,
                    clusterMinPercentage: setData.clusterMinPercentage,
                    clusterMaxPercentage: setData.clusterMaxPercentage,
                    restPauseCount: setData.restPauseCount,
                    restPauseDuration: setData.restPauseDuration
                )
                exerciseItem.sets.append(workoutSet)
            }

            block.exerciseItems.append(exerciseItem)
        }

        return block
    }
}
