# Custom Methods Execution - Design Document

## Current Implementation Analysis

### How Workout Execution Works Currently

**WorkoutExecutionViewModel.Step Types:**
- `.timed(duration, isRest)` - Time-based exercises (EMOM, AMRAP, etc.)
- `.reps(totalSets, repsPerSet)` - Rep-based exercises

**Confirmation Flow:**
1. User completes a set and clicks "Conferma Serie"
2. `confirmSet()` → `advanceSet()` is called
3. `completedSets` counter is incremented
4. If `completedSets >= totalSets`, moves to next step
5. Otherwise, prepares for next set

**Key Variables:**
- `completedSets`: Int - number of completed sets
- `loadText`: String - actual load used
- `actualRepsText`: String - actual reps performed
- `perceivedExertion`: Double - RPE 1-10

## Required Changes for Custom Methods

### 1. New Step Type

Add a new step type to handle custom methods:

```swift
enum StepType: Equatable {
    case timed(duration: TimeInterval, isRest: Bool)
    case reps(totalSets: Int, repsPerSet: Int)
    case customMethodReps(
        totalSets: Int,
        customMethodID: UUID,
        baseLoad: Double?,
        baseLoadType: LoadType // .absolute or .percentage
    )
}
```

### 2. Additional State Variables

Add to `WorkoutExecutionViewModel`:

```swift
// Custom method execution state
@Published var completedReps: Int = 0 // Current rep within set
@Published var currentRepLoad: Double = 0 // Calculated load for current rep
@Published var currentRepRestTime: TimeInterval = 0 // Rest after current rep
@Published private(set) var loadedCustomMethod: CustomTrainingMethod?
```

### 3. Execution Logic

#### Flow for Custom Method Sets:

```
Start Set 1
  ├─> Rep 1: Show load (base × 100%), User confirms
  ├─> [Rest Timer: 0s if configured]
  ├─> Rep 2: Show load (base × 105%), User confirms
  ├─> [Rest Timer: 10s if configured]
  ├─> Rep 3: Show load (base × 105%), User confirms
  ├─> [Rest Timer: 10s if configured]
  ├─> Rep 4: Show load (base × 85%), User confirms
  ├─> [Rest Timer: 15s if configured]
  ├─> Rep 5: Show load (base × 85%), User confirms
  ├─> [Rest Timer: 15s if configured]
  └─> Rep 6: Show load (base × 130%), User confirms
       └─> Set complete! → [Series Rest Timer if configured]

If more sets remaining:
  → Repeat for Set 2, Set 3, etc.

When all sets complete:
  → Move to next exercise/block
```

### 4. Confirmation Modes

The system should automatically determine confirmation mode:

#### Same Load Mode (Current Behavior)
**When:** All reps have 0% load variation
**UI:** "Conferma Serie" button
**Action:** Confirms entire set at once

#### Variable Load Mode (New)
**When:** At least one rep has non-zero load variation
**UI:** "Conferma Rep X di Y" button
**Action:** Confirms one rep at a time
**Show:**
- Current rep load prominently
- Progress: "Rep 3/6"
- Next rep preview if available

#### Rest Timer Between Reps
**When:** Current rep has `restAfterRep > 0`
**Show:** Countdown timer between reps
**Auto-advance:** No - user must click "Inizia prossima rep" after rest

### 5. UI Components

#### CustomMethodRepView
New view component to display during custom method execution:

```swift
struct CustomMethodRepView: View {
    let methodName: String
    let currentSet: Int
    let totalSets: Int
    let currentRep: Int
    let totalReps: Int
    let currentLoad: Double
    let baseLoad: Double
    let loadVariation: Double // percentage
    let restTimeAfterRep: TimeInterval

    var body: some View {
        VStack {
            // Method name and icon
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.purple)
                Text(methodName)
            }

            // Set and rep counters
            Text("Serie \(currentSet) di \(totalSets)")
            Text("Rep \(currentRep) di \(totalReps)")
                .font(.title)
                .bold()

            // Load information
            VStack {
                Text("Carico per questa rep")
                    .font(.caption)
                HStack {
                    Text("\(currentLoad, specifier: "%.1f") kg")
                        .font(.title2)
                    Text("(\(loadVariation > 0 ? "+" : "")\(loadVariation, specifier: "%.0f")%)")
                        .font(.caption)
                        .foregroundColor(loadVariation > 0 ? .green : loadVariation < 0 ? .red : .secondary)
                }
            }

            // Rest preview if applicable
            if restTimeAfterRep > 0 {
                Text("Pausa dopo: \(Int(restTimeAfterRep))s")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            // Confirm button
            Button("Conferma Rep") {
                // confirm action
            }
        }
    }
}
```

### 6. Load Calculation

Helper function in CustomTrainingMethod model:

```swift
extension CustomTrainingMethod {
    /// Calculate actual load for a specific rep
    func loadForRep(_ repNumber: Int, baseLoad: Double) -> Double {
        guard let config = repConfigurations.first(where: { $0.repOrder == repNumber }) else {
            return baseLoad
        }
        let multiplier = config.actualLoadPercentage / 100.0
        return baseLoad * multiplier
    }

    /// Get all loads for all reps given a base load
    func allLoads(baseLoad: Double) -> [Double] {
        return repConfigurations
            .sorted(by: { $0.repOrder < $1.repOrder })
            .map { config in
                let multiplier = config.actualLoadPercentage / 100.0
                return baseLoad * multiplier
            }
    }

    /// Check if all reps have same load (0% variation)
    var hasSameLoadAllReps: Bool {
        return repConfigurations.allSatisfy { $0.loadPercentage == 0 }
    }

    /// Check if any rep has rest time
    var hasRestBetweenReps: Bool {
        return repConfigurations.contains(where: { $0.restAfterRep > 0 })
    }
}
```

### 7. Modified Functions

#### WorkoutExecutionViewModel

```swift
func confirmRep() {
    guard let step = currentStep,
          case let .customMethodReps(totalSets, methodID, baseLoad, _) = step.type,
          let method = loadedCustomMethod else {
        return
    }

    completedReps += 1

    // Check if current rep has rest time
    if let config = method.repConfigurations.first(where: { $0.repOrder == completedReps }),
       config.restAfterRep > 0 {
        // Show rest timer
        startRepRestTimer(duration: config.restAfterRep)
    } else if completedReps >= method.totalReps {
        // Set complete
        completedReps = 0
        confirmSet() // Reuse existing set confirmation logic
    } else {
        // Move to next rep
        updateCurrentRepLoad()
    }
}

private func startRepRestTimer(duration: TimeInterval) {
    // Similar to existing rest timer logic
    // After completion, automatically prepare for next rep
}

private func updateCurrentRepLoad() {
    guard let method = loadedCustomMethod,
          let baseLoad = extractBaseLoad(),
          completedReps < method.totalReps else {
        return
    }

    let nextRep = completedReps + 1
    currentRepLoad = method.loadForRep(nextRep, baseLoad: baseLoad)

    if let config = method.repConfigurations.first(where: { $0.repOrder == nextRep }) {
        currentRepRestTime = config.restAfterRep
    }
}
```

### 8. Step Factory Modification

Update `WorkoutExecutionStepFactory.steps(for:)`:

```swift
// For custom method blocks
if block.blockType == .customMethod,
   let customMethodID = block.customMethodID {

    // Load custom method from context
    let descriptor = FetchDescriptor<CustomTrainingMethod>(
        predicate: #Predicate { $0.id == customMethodID }
    )

    guard let customMethod = try? modelContext.fetch(descriptor).first else {
        continue
    }

    for exercise in exercises {
        let sets = exercise.sets.sorted { $0.order < $1.order }
        guard let firstSet = sets.first else { continue }

        let baseLoad: Double?
        let loadType: LoadType

        if let weight = firstSet.weight {
            baseLoad = weight
            loadType = .absolute
        } else if let percentage = firstSet.percentageOfMax {
            baseLoad = percentage
            loadType = .percentage
        } else {
            baseLoad = nil
            loadType = .absolute
        }

        // Determine if needs rep-by-rep confirmation
        let needsRepByRep = !customMethod.hasSameLoadAllReps || customMethod.hasRestBetweenReps

        if needsRepByRep {
            result.append(
                WorkoutExecutionViewModel.Step(
                    title: exercise.exercise?.name ?? "Esercizio",
                    subtitle: "\(customMethod.name) - \(customMethod.totalReps) reps per serie",
                    zone: .zone4,
                    estimatedDuration: TimeInterval(customMethod.totalReps * block.globalSets * 5), // estimate
                    type: .customMethodReps(
                        totalSets: block.globalSets,
                        customMethodID: customMethod.id,
                        baseLoad: baseLoad,
                        baseLoadType: loadType
                    ),
                    highlight: "Segui le variazioni di carico del metodo \(customMethod.name)"
                )
            )
        } else {
            // Use standard reps mode if no variations
            result.append(
                WorkoutExecutionViewModel.Step(
                    title: exercise.exercise?.name ?? "Esercizio",
                    subtitle: "\(customMethod.name) - \(customMethod.totalReps) reps",
                    zone: .zone4,
                    estimatedDuration: TimeInterval(customMethod.totalReps * block.globalSets),
                    type: .reps(totalSets: block.globalSets, repsPerSet: customMethod.totalReps),
                    highlight: "Metodo \(customMethod.name) con carico costante"
                )
            )
        }
    }
}
```

## Summary of Changes

### Files to Modify:

1. **WorkoutExecutionViewModel** (in WorkoutExecutionView.swift)
   - Add new `StepType.customMethodReps`
   - Add state variables for rep tracking
   - Add `confirmRep()` function
   - Add rep rest timer logic
   - Modify `stepProgress` to handle rep-level progress

2. **WorkoutExecutionView** (UI)
   - Add `customMethodRepView` function
   - Handle rep-by-rep confirmation UI
   - Show rep rest timers
   - Display current rep load prominently

3. **CustomTrainingMethod** (model extensions)
   - Add `loadForRep()` helper
   - Add `hasSameLoadAllReps` computed property
   - Add `hasRestBetweenReps` computed property

4. **WorkoutExecutionStepFactory**
   - Add logic to create custom method steps
   - Determine if rep-by-rep confirmation needed
   - Load CustomTrainingMethod from database

### User Experience:

**Scenario 1: Same Load (Simple)**
- Method has all reps at 0% variation
- UI shows: "Serie 1 di 3 - 6 reps @ 100kg"
- User clicks "Conferma Serie" once
- Moves to next set

**Scenario 2: Variable Load (Advanced)**
- Method has varying loads per rep
- UI shows: "Rep 1 di 6 - 100kg (base)"
- User completes rep, clicks "Conferma Rep"
- UI shows: "Rep 2 di 6 - 105kg (+5%)"
- Continue for all 6 reps
- After rep 6, "Serie 1 completata!"
- Moves to Set 2

**Scenario 3: Variable Load + Rest**
- Same as Scenario 2, but after each rep:
- "Pausa: 10s" countdown timer
- After timer, "Inizia Rep 2" button enabled
- User continues

## Implementation Priority

1. **Phase 1** (Minimum Viable):
   - Add new StepType
   - Basic rep-by-rep confirmation
   - Load calculation and display

2. **Phase 2** (Enhanced):
   - Rep rest timers
   - Automatic progression after rest
   - Better UI/UX for rep tracking

3. **Phase 3** (Polish):
   - Animations between reps
   - Load preview for next rep
   - Summary stats after set completion
