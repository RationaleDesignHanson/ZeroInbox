# Week 5: Performance Testing Plan

**Date**: 2025-11-14
**Purpose**: Verify 98% performance improvement claims
**Status**: Ready to Execute

---

## Testing Overview

We'll verify the performance improvements through:
1. **Manual Timing Tests** - Simple console logging
2. **Xcode Instruments** - Detailed profiling (optional)
3. **Memory Analysis** - Allocation tracking

**Expected Results**:
- Action execution: <5ms (was 200-400ms)
- DataGenerator cache: <1ms (was 500-1000ms)
- Memory: 90% less allocation churn

---

## Test 1: Action Execution Performance (Manual)

### Setup

Add temporary timing code to `ActionRouter.swift`:

```swift
// At top of file
import Foundation

// In executeAction() method (line 32):
func executeAction(_ action: EmailAction, card: EmailCard, from viewController: UIViewController? = nil) {
    let startTime = Date()  // ← ADD THIS

    Logger.info("Executing action \(action.actionId)", category: .action)

    // ... existing code ...

    // At end of method (after analytics, before return):
    let elapsed = Date().timeIntervalSince(startTime) * 1000  // Convert to ms
    Logger.info("⏱️ Action '\(action.actionId)' executed in \(String(format: "%.2f", elapsed))ms", category: .action)
}
```

### Test Procedure

1. **Build and run** the app
2. **Swipe left** on 10 different email cards to trigger actions
3. **Check console** for timing logs

### Expected Output

```
⏱️ Action 'pay_invoice' executed in 3.42ms
⏱️ Action 'track_package' executed in 2.87ms
⏱️ Action 'add_to_calendar' executed in 4.12ms
⏱️ Action 'sign_form' executed in 3.65ms
...
```

### Success Criteria

- ✅ All action executions **< 10ms**
- ✅ Average execution time **< 5ms**
- ✅ No execution **> 20ms** (outliers)

### If Tests Fail

Check:
1. ActionRegistry initialized? (Look for "Total actions in registry" log)
2. JSON actions loaded? (Look for "Loaded X actions from JSON")
3. Any errors during registry init?

---

## Test 2: DataGenerator Caching (Manual)

### Setup

Add temporary timing code to test file or view:

```swift
import Foundation

func testDataGeneratorPerformance() {
    // First call (generates and caches)
    let start1 = Date()
    let cards1 = DataGenerator.generateComprehensiveMockData()
    let elapsed1 = Date().timeIntervalSince(start1) * 1000
    print("⏱️ First DataGenerator call: \(String(format: "%.2f", elapsed1))ms (\(cards1.count) cards)")

    // Second call (cached)
    let start2 = Date()
    let cards2 = DataGenerator.generateComprehensiveMockData()
    let elapsed2 = Date().timeIntervalSince(start2) * 1000
    print("⏱️ Second DataGenerator call: \(String(format: "%.2f", elapsed2))ms (\(cards2.count) cards)")

    // Third call (cached)
    let start3 = Date()
    let cards3 = DataGenerator.generateComprehensiveMockData()
    let elapsed3 = Date().timeIntervalSince(start3) * 1000
    print("⏱️ Third DataGenerator call: \(String(format: "%.2f", elapsed3))ms (\(cards3.count) cards)")

    // Speedup calculation
    let speedup = elapsed1 / elapsed2
    print("⏱️ Speedup: \(String(format: "%.1f", speedup))x faster")
}
```

### Test Procedure

1. Call `testDataGeneratorPerformance()` from a view or test
2. Check console output

### Expected Output

```
⏱️ First DataGenerator call: 523.45ms (104 cards)
Generating mock data for first time (will be cached)
Cached 104 mock emails for future use

⏱️ Second DataGenerator call: 0.12ms (104 cards)
Returning cached mock data (104 emails)

⏱️ Third DataGenerator call: 0.08ms (104 cards)
Returning cached mock data (104 emails)

⏱️ Speedup: 6543.8x faster
```

### Success Criteria

- ✅ First call: Any duration (generation)
- ✅ Second+ calls: **< 1ms**
- ✅ Speedup: **> 500x**
- ✅ Cache logs present

### If Tests Fail

Check:
1. Cache being populated? (Look for "Cached X mock emails")
2. Cache being used? (Look for "Returning cached mock data")
3. `resetCache()` called between tests?

---

## Test 3: Registry Lookup Performance (Manual)

### Setup

Add test code:

```swift
func testActionRegistryPerformance() {
    // Warm up (initialize registry)
    _ = ActionRegistry.shared.getAction("pay_invoice")

    // Test 1000 lookups
    let start = Date()
    for _ in 0..<1000 {
        _ = ActionRegistry.shared.getAction("pay_invoice")
        _ = ActionRegistry.shared.getAction("track_package")
        _ = ActionRegistry.shared.getAction("add_to_calendar")
    }
    let elapsed = Date().timeIntervalSince(start) * 1000
    let perLookup = elapsed / 3000

    print("⏱️ 3000 registry lookups: \(String(format: "%.2f", elapsed))ms")
    print("⏱️ Average per lookup: \(String(format: "%.4f", perLookup))ms")
}
```

### Expected Output

```
Initializing ActionRegistry with JSON+Swift hybrid registry
Loaded 15 actions from JSON (0 failed)
Registered 200 Swift fallback actions
Total actions in registry: 215

⏱️ 3000 registry lookups: 24.56ms
⏱️ Average per lookup: 0.0082ms
```

### Success Criteria

- ✅ Registry initialization logs present
- ✅ 3000 lookups: **< 50ms** total
- ✅ Average per lookup: **< 0.02ms**

---

## Test 4: Repeated Lookup Elimination (Manual)

### Setup

Add counter to track lookup calls:

```swift
// In ActionRegistry.swift
private static var lookupCount = 0

func getAction(_ actionId: String) -> ActionConfig? {
    ActionRegistry.lookupCount += 1
    return registry[actionId]
}

static func resetLookupCount() {
    lookupCount = 0
}

static func getLookupCount() -> Int {
    return lookupCount
}
```

Then in test:

```swift
func testRepeatedLookupsEliminated() {
    ActionRegistry.resetLookupCount()

    let card = DataGenerator.generateComprehensiveMockData().first!
    let action = card.suggestedActions!.first!

    // Execute action
    ActionRouter.shared.executeAction(action, card: card)

    let lookups = ActionRegistry.getLookupCount()
    print("⏱️ Registry lookups per action execution: \(lookups)")
}
```

### Expected Output

```
⏱️ Registry lookups per action execution: 1
```

### Success Criteria

- ✅ Lookups per action: **= 1** (was 4 before optimization)

**Note**: This test requires adding instrumentation code

---

## Test 5: Memory Allocation (Xcode Instruments)

### Using Allocations Instrument

1. **Open Xcode** → Product → Profile (⌘I)
2. **Select** "Allocations" template
3. **Click Record**
4. **Perform actions**:
   - Navigate to email list
   - Swipe through 20 cards
   - Trigger 10 actions
5. **Stop recording**
6. **Analyze**:
   - Look for `EmailCard` allocations
   - Look for `ActionConfig` allocations
   - Check for repeated allocations

### Expected Results

**DataGenerator**:
- ✅ First `generateComprehensiveMockData()`: ~2-5 MB allocated
- ✅ Subsequent calls: **<1 KB** (just array reference)

**ActionRegistry**:
- ✅ First `getAction()`: Registry init (~1-2 MB)
- ✅ Subsequent calls: **~0 bytes** (dictionary lookup)

### Screenshot Analysis

Look for:
- ✅ Flat allocation graph after initial load
- ✅ No spikes on action execution
- ✅ No repeated `EmailCard[]` allocations

---

## Test 6: Time Profiler (Xcode Instruments)

### Using Time Profiler

1. **Open Xcode** → Product → Profile (⌘I)
2. **Select** "Time Profiler" template
3. **Click Record**
4. **Perform actions**:
   - Swipe left on 20 cards (trigger actions)
5. **Stop recording**
6. **Analyze**:
   - Find `executeAction()` in call tree
   - Check self time and total time
   - Look for JSON parsing (should be gone!)

### Expected Results

**Before Optimization** (what we'd have seen):
```
executeAction()              400.2ms  (total)
├─ ActionLoader.loadAction   150.3ms  (JSON parsing)
├─ JSONAction.toActionConfig  50.1ms  (conversion)
├─ ValidationResult          180.5ms  (repeated lookups)
└─ Other                      19.3ms
```

**After Optimization**:
```
executeAction()                4.2ms  (total)
├─ registry[actionId]          0.1ms  (dictionary lookup)
├─ validateAction              2.1ms  (validation logic)
├─ Analytics                   1.5ms  (tracking)
└─ Other                       0.5ms
```

### Success Criteria

- ✅ `executeAction()` total time: **< 10ms**
- ✅ No `ActionLoader.loadAction` calls during execution
- ✅ No `JSONAction.toActionConfig` calls during execution
- ✅ Registry lookups: **< 0.5ms** each

---

## Quick Test Script (Copy-Paste)

For quick manual verification, add this to any view:

```swift
// MARK: - Performance Testing (Remove before commit)
func runPerformanceTests() {
    print("\n=== PERFORMANCE TESTS ===\n")

    // Test 1: ActionRegistry Lookup
    print("Test 1: ActionRegistry Lookup")
    let start1 = Date()
    for _ in 0..<1000 {
        _ = ActionRegistry.shared.getAction("pay_invoice")
    }
    let elapsed1 = Date().timeIntervalSince(start1) * 1000
    print("✓ 1000 lookups: \(String(format: "%.2f", elapsed1))ms")
    print("✓ Per lookup: \(String(format: "%.4f", elapsed1/1000))ms")
    print()

    // Test 2: DataGenerator Caching
    print("Test 2: DataGenerator Caching")
    DataGenerator.resetCache()

    let start2a = Date()
    let cards1 = DataGenerator.generateComprehensiveMockData()
    let elapsed2a = Date().timeIntervalSince(start2a) * 1000
    print("✓ First call: \(String(format: "%.2f", elapsed2a))ms (\(cards1.count) cards)")

    let start2b = Date()
    let cards2 = DataGenerator.generateComprehensiveMockData()
    let elapsed2b = Date().timeIntervalSince(start2b) * 1000
    print("✓ Second call: \(String(format: "%.2f", elapsed2b))ms (\(cards2.count) cards)")
    print("✓ Speedup: \(String(format: "%.0f", elapsed2a/elapsed2b))x faster")
    print()

    // Test 3: Action Execution
    print("Test 3: Action Execution")
    if let card = cards1.first, let action = card.suggestedActions?.first {
        let start3 = Date()
        // Note: Can't actually execute without UI context
        _ = ActionRegistry.shared.getAction(action.actionId)
        _ = ActionRegistry.shared.validateAction(action.actionId, context: action.context)
        let elapsed3 = Date().timeIntervalSince(start3) * 1000
        print("✓ Lookup + Validate: \(String(format: "%.2f", elapsed3))ms")
    }

    print("\n=== TESTS COMPLETE ===\n")
}
```

Call from `ContentView.onAppear`:

```swift
.onAppear {
    #if DEBUG
    runPerformanceTests()
    #endif
}
```

---

## Expected Console Output (Summary)

When running all tests, you should see:

```
=== PERFORMANCE TESTS ===

Initializing ActionRegistry with JSON+Swift hybrid registry
Loaded 15 actions from JSON (0 failed)
Registered 200 Swift fallback actions
Total actions in registry: 215

Test 1: ActionRegistry Lookup
✓ 1000 lookups: 18.34ms
✓ Per lookup: 0.0183ms

Test 2: DataGenerator Caching
Generating mock data for first time (will be cached)
Cached 104 mock emails for future use
✓ First call: 486.23ms (104 cards)
Returning cached mock data (104 emails)
✓ Second call: 0.09ms (104 cards)
✓ Speedup: 5403x faster

Test 3: Action Execution
✓ Lookup + Validate: 1.87ms

=== TESTS COMPLETE ===
```

---

## Success Criteria Summary

### All Tests Must Pass:

1. **ActionRegistry Lookup**:
   - ✅ 1000 lookups < 50ms
   - ✅ Per lookup < 0.05ms
   - ✅ Registry initialization logs present

2. **DataGenerator Caching**:
   - ✅ First call: any duration (generation)
   - ✅ Second+ calls: < 1ms
   - ✅ Speedup: > 100x
   - ✅ Cache logs present

3. **Action Execution**:
   - ✅ Lookup + Validate: < 5ms
   - ✅ Full execution: < 10ms

4. **Memory (Instruments)**:
   - ✅ No repeated EmailCard allocations
   - ✅ Flat allocation graph after init

5. **Time (Instruments)**:
   - ✅ No JSON parsing during action execution
   - ✅ executeAction() < 10ms

---

## Running the Tests

### Quick Test (5 minutes)

1. Add `runPerformanceTests()` function to ContentView
2. Call in `.onAppear` with `#if DEBUG`
3. Run app, check console
4. Verify all ✓ marks

### Full Test (30 minutes)

1. Run Quick Test
2. Profile with Allocations (10 min)
3. Profile with Time Profiler (10 min)
4. Review results
5. Document findings

### Minimal Test (1 minute)

1. Run app
2. Swipe left on 5 cards
3. Check console for:
   - "Total actions in registry: X"
   - "Cached X mock emails"
   - No errors

---

## What to Document

After testing, add to WEEK_5_PERFORMANCE_OPTIMIZATIONS.md:

```markdown
## Performance Testing Results

**Date**: [Date]
**Environment**: [Simulator/Device]

### Quick Test Results
- ActionRegistry: 1000 lookups in X ms (X ms per lookup)
- DataGenerator: X speedup (first: X ms, cached: X ms)
- Action Execution: X ms average

### Instruments Results
- Memory: [Screenshot or description]
- Time Profile: [Screenshot or description]

### Conclusion
✅ All performance targets met
✅ 98% improvement verified
```

---

## Next Steps

1. ✅ Code Review Complete (WEEK_5_CODE_REVIEW.md)
2. 🔄 **Run Performance Tests** (use this document)
3. ⏳ User's Additional Pass
4. ✅ Ready to Commit

---

**Testing Guide Status**: Ready to Execute
**Estimated Time**: 5-30 minutes (depending on depth)
**Difficulty**: Easy (mostly copy-paste)
