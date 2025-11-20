# Custom Methods Execution - Design Document

## Overview

Custom training methods allow users to define variable loads and rest times per repetition. During workout execution, the system intelligently groups repetitions based on load and rest patterns, allowing efficient confirmation of rep groups rather than individual reps.

## Core Concept: Smart Grouping

**Key Principle:** Group consecutive reps with the same load AND same rest configuration together.

### Grouping Rules

A new group starts when:
1. **Load changes** (different percentage from previous rep)
2. **Rest pattern changes** (previous had no rest, current has rest, or vice versa)
3. **Rest duration changes** (e.g., previous 10s, current 15s)

### Example Groupings

**Example 1: Variable loads, no intermediate rest**
```
Custom Method: 6 reps
Rep 1: 100kg (0%), no rest
Rep 2: 105kg (+5%), no rest
Rep 3: 105kg (+5%), no rest
Rep 4: 110kg (+10%), no rest
Rep 5: 110kg (+10%), no rest
Rep 6: 115kg (+15%), no rest
Rest between sets: 60s

Groups:
Group 1: [Rep 1] (100kg)
Group 2: [Rep 2, Rep 3] (105kg)
Group 3: [Rep 4, Rep 5] (110kg)
Group 4: [Rep 6] (115kg)
→ Series rest: 60s
```

**Example 2: Same load, rest every 2 reps**
```
Custom Method: 6 reps
Rep 1: 100kg (0%), no rest
Rep 2: 100kg (0%), 15s rest
Rep 3: 100kg (0%), no rest
Rep 4: 100kg (0%), 15s rest
Rep 5: 100kg (0%), no rest
Rep 6: 100kg (0%), no rest
Rest between sets: 60s

Groups:
Group 1: [Rep 1] (100kg, no rest)
Group 2: [Rep 2] (100kg, 15s rest)
Group 3: [Rep 3] (100kg, no rest)
Group 4: [Rep 4] (100kg, 15s rest)
Group 5: [Rep 5, Rep 6] (100kg, no rest)
→ Series rest: 60s
```

**Example 3: Variable loads AND rest**
```
Custom Method: 6 reps
Rep 1: 100kg (0%), no rest
Rep 2: 105kg (+5%), 10s rest
Rep 3: 105kg (+5%), 10s rest
Rep 4: 85kg (-15%), 15s rest
Rep 5: 85kg (-15%), 15s rest
Rep 6: 130kg (+30%), no rest
Rest between sets: 60s

Groups:
Group 1: [Rep 1] (100kg, no rest)
Group 2: [Rep 2, Rep 3] (105kg, 10s rest)
Group 3: [Rep 4, Rep 5] (85kg, 15s rest)
Group 4: [Rep 6] (130kg, no rest)
→ Series rest: 60s
```

## User Flow

### Per Set Execution

```
START SET 1
    ↓
┌─────────────────────────────────┐
│ Group 1: Confirm Reps           │
│ Rep 1: 100 kg ✏️               │
│ [Conferma] [Modifica]           │
└─────────────────────────────────┘
    ↓ (if group has rest)
⏱️ Rest Timer: 0s (no rest)
    ↓
┌─────────────────────────────────┐
│ Group 2: Confirm Reps           │
│ Rep 2: 105 kg ✏️               │
│ Rep 3: 105 kg ✏️               │
│ [Conferma] [Modifica]           │
└─────────────────────────────────┘
    ↓
⏱️ Rest Timer: 10s
    ↓
┌─────────────────────────────────┐
│ Group 3: Confirm Reps           │
│ Rep 4: 85 kg ✏️                │
│ Rep 5: 85 kg ✏️                │
│ [Conferma] [Modifica]           │
└─────────────────────────────────┘
    ↓
⏱️ Rest Timer: 15s
    ↓
┌─────────────────────────────────┐
│ Group 4: Confirm Reps           │
│ Rep 6: 130 kg ✏️               │
│ [Conferma] [Modifica]           │
└─────────────────────────────────┘
    ↓
⏱️ Rest Timer: 60s (series rest)
    ↓
START SET 2 (repeat all groups)
```

## Technical Implementation

### 1. Data Structures

#### RepGroup Model

```swift
struct RepGroup: Identifiable {
    let id = UUID()
    let reps: [CustomRepConfiguration]
    let load: Double // Calculated load for this group
    let loadPercentage: Double // Percentage variation
    let restAfterGroup: TimeInterval // Rest after completing this group

    var firstRepNumber: Int {
        reps.first?.repOrder ?? 0
    }

    var lastRepNumber: Int {
        reps.last?.repOrder ?? 0
    }

    var repCount: Int {
        reps.count
    }

    var repRange: String {
        if repCount == 1 {
            return "Rep \(firstRepNumber)"
        }
        return "Rep \(firstRepNumber)-\(lastRepNumber)"
    }
}
```

#### CustomMethodExecutionState

```swift
struct CustomMethodExecutionState {
    let method: CustomTrainingMethod
    let baseLoad: Double
    let loadType: LoadType // .absolute or .percentage
    let totalSets: Int
    let groups: [RepGroup]

    var currentSetNumber: Int = 1
    var currentGroupIndex: Int = 0
    var confirmedLoads: [Int: Double] = [:] // repOrder -> actualLoad

    var currentGroup: RepGroup? {
        groups.indices.contains(currentGroupIndex) ? groups[currentGroupIndex] : nil
    }

    var isSetComplete: Bool {
        currentGroupIndex >= groups.count
    }

    var areAllSetsComplete: Bool {
        currentSetNumber > totalSets
    }
}
```

### 2. Grouping Algorithm

```swift
extension CustomTrainingMethod {
    func createRepGroups(baseLoad: Double) -> [RepGroup] {
        guard !repConfigurations.isEmpty else { return [] }

        let sortedConfigs = repConfigurations.sorted { $0.repOrder < $1.repOrder }
        var groups: [RepGroup] = []
        var currentGroupConfigs: [CustomRepConfiguration] = []
        var previousLoad: Double?
        var previousRest: TimeInterval?

        for config in sortedConfigs {
            let currentLoad = baseLoad * (config.actualLoadPercentage / 100.0)
            let currentRest = config.restAfterRep

            let shouldStartNewGroup = previousLoad != nil && (
                currentLoad != previousLoad ||
                currentRest != previousRest
            )

            if shouldStartNewGroup {
                // Close previous group
                if let firstConfig = currentGroupConfigs.first {
                    let groupLoad = baseLoad * (firstConfig.actualLoadPercentage / 100.0)
                    let groupRest = firstConfig.restAfterRep

                    groups.append(RepGroup(
                        reps: currentGroupConfigs,
                        load: groupLoad,
                        loadPercentage: firstConfig.loadPercentage,
                        restAfterGroup: groupRest
                    ))
                }
                currentGroupConfigs = []
            }

            currentGroupConfigs.append(config)
            previousLoad = currentLoad
            previousRest = currentRest
        }

        // Add last group
        if let firstConfig = currentGroupConfigs.first {
            let groupLoad = baseLoad * (firstConfig.actualLoadPercentage / 100.0)
            let groupRest = firstConfig.restAfterRep

            groups.append(RepGroup(
                reps: currentGroupConfigs,
                load: groupLoad,
                loadPercentage: firstConfig.loadPercentage,
                restAfterGroup: groupRest
            ))
        }

        return groups
    }
}
```

### 3. View Model Updates

Add to `WorkoutExecutionViewModel`:

```swift
// Custom method execution state
@Published var customMethodState: CustomMethodExecutionState?
@Published var isShowingRepGroupConfirmation = false
@Published var isShowingRepGroupRest = false
@Published var repGroupRestRemaining: TimeInterval = 0

func startCustomMethodExecution(
    method: CustomTrainingMethod,
    baseLoad: Double,
    loadType: LoadType,
    totalSets: Int
) {
    let groups = method.createRepGroups(baseLoad: baseLoad)
    customMethodState = CustomMethodExecutionState(
        method: method,
        baseLoad: baseLoad,
        loadType: loadType,
        totalSets: totalSets,
        groups: groups,
        currentSetNumber: 1,
        currentGroupIndex: 0
    )
    isShowingRepGroupConfirmation = true
}

func confirmRepGroup(actualLoads: [Int: Double]) {
    guard var state = customMethodState else { return }

    // Store actual loads
    for (repOrder, load) in actualLoads {
        state.confirmedLoads[repOrder] = load
    }

    // Check if group has rest
    if let currentGroup = state.currentGroup, currentGroup.restAfterGroup > 0 {
        isShowingRepGroupConfirmation = false
        startRepGroupRest(duration: currentGroup.restAfterGroup)
    } else {
        advanceToNextGroup()
    }
}

private func startRepGroupRest(duration: TimeInterval) {
    repGroupRestRemaining = duration
    isShowingRepGroupRest = true

    // Timer logic to countdown
    // When timer finishes, call advanceToNextGroup()
}

private func advanceToNextGroup() {
    guard var state = customMethodState else { return }

    state.currentGroupIndex += 1
    customMethodState = state

    if state.isSetComplete {
        // Set complete, check for series rest
        if let seriesRest = /* get series rest from block */ {
            startSeriesRest(duration: seriesRest)
        } else {
            advanceToNextSet()
        }
    } else {
        // Show next group
        isShowingRepGroupRest = false
        isShowingRepGroupConfirmation = true
    }
}

private func advanceToNextSet() {
    guard var state = customMethodState else { return }

    state.currentSetNumber += 1
    state.currentGroupIndex = 0
    state.confirmedLoads.removeAll()
    customMethodState = state

    if state.areAllSetsComplete {
        completeCustomMethodExecution()
    } else {
        isShowingRepGroupConfirmation = true
    }
}

private func completeCustomMethodExecution() {
    customMethodState = nil
    isShowingRepGroupConfirmation = false
    isShowingRepGroupRest = false
    skipToNextStep()
}
```

### 4. UI Components

#### RepGroupConfirmationView

```swift
struct RepGroupConfirmationView: View {
    let group: RepGroup
    let setNumber: Int
    let totalSets: Int
    let methodName: String
    let onConfirm: ([Int: Double]) -> Void

    @State private var editedLoads: [Int: String] = [:]
    @State private var showingEditSheet = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "bolt.circle.fill")
                        .foregroundColor(.purple)
                    Text(methodName)
                        .font(.headline)
                }

                Text("Serie \(setNumber) di \(totalSets)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(group.repRange)
                    .font(.title)
                    .bold()
            }

            Divider()

            // Reps list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(group.reps, id: \.id) { rep in
                    HStack {
                        Text("Rep \(rep.repOrder)")
                            .font(.body)

                        Spacer()

                        Text("\(editedLoads[rep.repOrder] ?? String(format: "%.1f", group.load)) kg")
                            .font(.title3)
                            .bold()

                        if rep.loadPercentage != 0 {
                            Text("(\(rep.formattedLoadPercentage))")
                                .font(.caption)
                                .foregroundColor(rep.loadPercentage > 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)

            // Rest preview
            if group.restAfterGroup > 0 {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("Pausa dopo: \(Int(group.restAfterGroup))s")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    confirmWithCurrentLoads()
                }) {
                    Text("Conferma")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("Modifica Carichi")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingEditSheet) {
            EditLoadsSheet(
                group: group,
                editedLoads: $editedLoads
            )
        }
    }

    private func confirmWithCurrentLoads() {
        var actualLoads: [Int: Double] = [:]
        for rep in group.reps {
            if let editedString = editedLoads[rep.repOrder],
               let editedValue = Double(editedString) {
                actualLoads[rep.repOrder] = editedValue
            } else {
                actualLoads[rep.repOrder] = group.load
            }
        }
        onConfirm(actualLoads)
    }
}
```

#### RepGroupRestView

```swift
struct RepGroupRestView: View {
    let remainingTime: TimeInterval
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Pausa tra ripetizioni")
                .font(.headline)

            Text(formatTime(remainingTime))
                .font(.system(size: 48, weight: .bold))
                .monospacedDigit()

            ProgressView(value: 1.0 - (remainingTime / /* original duration */))
                .tint(.orange)
                .padding(.horizontal, 40)

            Button(action: onSkip) {
                Text("Salta pausa")
                    .font(.subheadline)
            }
        }
        .padding()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        if seconds >= 60 {
            let mins = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", mins, secs)
        }
        return "\(seconds)s"
    }
}
```

### 5. Step Factory Integration

Update `WorkoutExecutionStepFactory`:

```swift
// For custom method blocks
if block.blockType == .customMethod,
   let customMethodID = block.customMethodID {

    guard let customMethod = try? modelContext.fetch(
        FetchDescriptor<CustomTrainingMethod>(
            predicate: #Predicate { $0.id == customMethodID }
        )
    ).first else {
        continue
    }

    for exercise in exercises {
        let sets = exercise.sets.sorted { $0.order < $1.order }
        guard let firstSet = sets.first else { continue }

        let baseLoad: Double
        let loadType: LoadType

        if let weight = firstSet.weight {
            baseLoad = weight
            loadType = .absolute
        } else if let percentage = firstSet.percentageOfMax,
                  let oneRM = /* calculate 1RM */ {
            baseLoad = oneRM * (percentage / 100.0)
            loadType = .percentage
        } else {
            continue
        }

        result.append(
            WorkoutExecutionViewModel.Step(
                title: exercise.exercise?.name ?? "Esercizio",
                subtitle: "\(customMethod.name) - \(customMethod.totalReps) reps",
                zone: .zone4,
                estimatedDuration: TimeInterval(
                    customMethod.totalReps * block.globalSets * 5
                ),
                type: .customMethodReps(
                    totalSets: block.globalSets,
                    customMethodID: customMethod.id,
                    baseLoad: baseLoad,
                    baseLoadType: loadType
                ),
                highlight: "Segui le variazioni di carico del metodo \(customMethod.name)"
            )
        )
    }
}
```

## Benefits of Group-Based Approach

1. **Efficiency**: Confirm multiple reps at once when they share characteristics
2. **Flexibility**: Still allows load modification before confirmation
3. **Clarity**: See all reps in the group together
4. **Intelligence**: System automatically determines optimal grouping
5. **Progressive**: Rest timers only appear when needed

## Implementation Phases

### Phase 1: Core Grouping Logic ✓ Next
- Implement `RepGroup` model
- Implement grouping algorithm in `CustomTrainingMethod`
- Add tests for various grouping scenarios

### Phase 2: View Model Integration
- Add custom method state to `WorkoutExecutionViewModel`
- Implement group confirmation flow
- Implement rest timer between groups

### Phase 3: UI Components
- Create `RepGroupConfirmationView`
- Create `RepGroupRestView`
- Integrate with existing workout execution UI

### Phase 4: Step Factory
- Update step creation for custom methods
- Load method from database
- Calculate base loads correctly

### Phase 5: Testing & Polish
- Test various custom method configurations
- Ensure smooth transitions between groups
- Add animations and feedback
