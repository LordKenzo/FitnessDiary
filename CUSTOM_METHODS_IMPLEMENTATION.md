# Custom Training Methods - Implementation Notes

## Overview
This document describes the implementation of custom training methods and outlines the remaining work for full execution support.

## What's Implemented ✅

### 1. Data Models
- **CustomTrainingMethod**: Main model for custom methods with name, timestamps, and rep configurations
- **CustomRepConfiguration**: Individual repetition configuration with load percentage and rest time
- Both models integrated with SwiftData

### 2. User Interface
- **CustomMethodsListView**: Manage list of custom methods
- **EditCustomMethodView**: Create and edit custom methods with:
  - Method name input
  - Number of reps stepper (1-20)
  - Per-rep configuration with:
    - Load percentage slider (-50% to +100%)
    - Rest time slider (0-240 seconds)
- **CustomMethodSelectionView**: Select custom method when creating workout

### 3. Workout Card Integration
- Added "Con Metodo Custom" option in workout card creation
- Updated `WorkoutBlock` model with `customMethodID` field
- Updated `WorkoutBlockData` with custom method support
- Updated `WorkoutBlockHelper` with `addCustomMethodBlock()` method
- Updated `WorkoutBlockRow` to display custom methods with purple color and bolt icon

### 4. Settings Integration
- Added "Metodi Custom" section in Settings > Library
- Seamless integration with existing library management

## What Needs Implementation 🚧

### Execution Logic
The custom method execution logic needs to be implemented in the workout execution views. Here's the approach:

#### 1. Load Custom Method During Execution
When executing a workout with custom method blocks:
```swift
// In WorkoutExecutionView or similar
if block.blockType == .customMethod,
   let customMethodID = block.customMethodID {
    // Query custom method from model context
    let descriptor = FetchDescriptor<CustomTrainingMethod>(
        predicate: #Predicate { method in
            method.id == customMethodID
        }
    )
    if let customMethod = try? modelContext.fetch(descriptor).first {
        // Use customMethod.repConfigurations for execution
    }
}
```

#### 2. Apply Rep-by-Rep Logic
For each set in a custom method exercise:
```swift
// Example structure
for (index, repConfig) in customMethod.repConfigurations.enumerated() {
    let repNumber = index + 1
    let loadMultiplier = repConfig.actualLoadPercentage / 100.0
    let actualWeight = baseWeight * loadMultiplier

    // Display rep with weight
    // After rep, show rest timer if repConfig.restAfterRep > 0
}
```

#### 3. UI Components Needed
Create a new view for custom method set execution:
- **CustomMethodRepExecutionView**:
  - Shows current rep number
  - Displays calculated weight for this rep
  - Shows rest timer between reps
  - Visual progress through all reps

#### 4. Weight Calculation
```swift
extension CustomTrainingMethod {
    func calculateWeights(baseWeight: Double) -> [Double] {
        return repConfigurations.sorted(by: { $0.repOrder < $1.repOrder })
            .map { config in
                let multiplier = config.actualLoadPercentage / 100.0
                return baseWeight * multiplier
            }
    }

    func totalDuration() -> TimeInterval {
        return repConfigurations.reduce(0) { $0 + $1.restAfterRep }
    }
}
```

#### 5. Integration Points
Files that need updates:
- `WorkoutExecutionView.swift`: Add custom method execution logic
- Create `CustomMethodSetExecutionView.swift`: New view for custom method sets
- `WorkoutSessionLog.swift`: Ensure proper logging of custom method executions

### Example User Flow
1. User creates custom method "Variabile" with 6 reps:
   - Rep 1: 0%, 0s rest (base weight)
   - Rep 2: +5%, 10s rest
   - Rep 3: +5%, 10s rest
   - Rep 4: -15%, 15s rest
   - Rep 5: -15%, 15s rest
   - Rep 6: +30%, 20s rest

2. User adds exercise "Panca Piana" with custom method "Variabile"
3. During execution:
   - User sets base weight (e.g., 100kg)
   - System shows:
     - Rep 1: 100kg (0s rest)
     - Rep 2: 105kg (10s rest timer)
     - Rep 3: 105kg (10s rest timer)
     - Rep 4: 85kg (15s rest timer)
     - Rep 5: 85kg (15s rest timer)
     - Rep 6: 130kg (20s rest timer)

### Testing Checklist
- [ ] Create custom method in settings
- [ ] Add custom method block to workout card
- [ ] Save workout card with custom method
- [ ] Load workout card and verify custom method displays correctly
- [ ] Execute workout with custom method
- [ ] Verify rep-by-rep weight calculations
- [ ] Verify rest timers between reps
- [ ] Test edge cases (0% load, 0s rest, max values)
- [ ] Test editing existing custom method
- [ ] Test deleting custom method (should warn if used in workouts)

## Architecture Notes

### Why Store customMethodID Instead of Relationship?
We store the UUID of the custom method instead of a direct SwiftData relationship to:
1. Avoid cascade deletion issues (deleting a method doesn't delete all workouts using it)
2. Allow for "orphaned" workout blocks that can still be executed with cached data
3. Provide flexibility for future features like method versioning

### Data Flow
```
Settings > Custom Methods > Create Method
   ↓
Workout Card Creation > Select Custom Method
   ↓
WorkoutBlock (stores customMethodID)
   ↓
Workout Execution (queries CustomTrainingMethod)
   ↓
Apply rep configurations during set execution
```

## Future Enhancements
- Method templates/presets
- Copy/duplicate custom methods
- Export/import custom methods
- Method usage statistics
- Suggest optimal rest times based on load changes
- Progressive overload tracking for custom methods
- Method versioning (track changes to methods over time)
