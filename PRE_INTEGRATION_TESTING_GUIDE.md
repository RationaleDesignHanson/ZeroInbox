# Pre-Integration Testing Guide
## Test All Wearables Features BEFORE Production Integration

**Version**: 1.0
**Date**: 2025-12-12
**Purpose**: Test every wearables service in isolation, no production code modifications needed

---

## ✅ All Critical Issues Fixed!

Before testing, all compilation issues have been resolved:

1. ✅ **Logger categories added** (audio, voice, watch, wearables, arDisplay, emg)
2. ✅ **WearablesTestView.swift fixed** (stopSpeaking → stop, description → summary)
3. ✅ **Platform guards added** (#if os(iOS) wrapper)
4. ✅ **Duplicate Logger extension removed** from WatchModels.swift

**You're ready to test!** 🎉

---

## Quick Start: 3 Ways to Test

### Option 1: Use WearablesTestView (Easiest) ⭐️
```swift
// Add to your iOS app's navigation or present modally
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            WearablesTestView()
        }
    }
}
```

### Option 2: Direct Service Testing (Playground/Console)
```swift
// In Xcode console or Swift Playground
import UIKit

// Test voice
VoiceOutputService.shared.speak("Hello from Zer0!")

// Test Meta Glasses connection
Task {
    try await MetaGlassesAdapter.shared.connect()
    print("Tier: \(MetaGlassesAdapter.shared.connectionTier)")
}

// Test EMG gestures
EMGGestureRecognizer.shared.startRecognition()
```

### Option 3: Individual Test Views
Create standalone test views for each service (examples below)

---

## Test Plan: All Services

### 1. Voice Output Service ✅ (5 minutes)

**What You're Testing**: Text-to-speech, audio routing, Bluetooth connection

**Steps**:
1. Open Zer0 app
2. Navigate to `WearablesTestView`
3. Select "Voice" tab
4. **Optional**: Connect AirPods or Bluetooth headphones

**Test Cases**:

```swift
// Test 1: Simple speech
VoiceOutputService.shared.speak("Testing voice output")
// Expected: Hear speech through iPhone speaker or connected Bluetooth device

// Test 2: Check Bluetooth routing
let isRouted = VoiceOutputService.shared.isAudioRouted
print("Audio routed to Bluetooth: \(isRouted)")
// Expected: true if AirPods connected, false if using iPhone speaker

// Test 3: Read email summary
let mockEmail = EmailCard(...)
VoiceOutputService.shared.readEmail(mockEmail, includeBody: false)
// Expected: Hear "Email from [sender]: [subject]"

// Test 4: Inbox summary
VoiceOutputService.shared.readInboxSummary(unreadCount: 3, topEmails: mockEmails)
// Expected: Hear "You have 3 unread emails. First: [email 1]..."

// Test 5: Pause/resume
VoiceOutputService.shared.speak("This is a long sentence that can be paused")
// Tap pause button after 2 seconds
VoiceOutputService.shared.pause()
// Expected: Speech pauses mid-sentence

// Wait 2 seconds
VoiceOutputService.shared.resume()
// Expected: Speech resumes where it left off

// Test 6: Stop
VoiceOutputService.shared.speak("This will be stopped")
// Tap stop button after 1 second
VoiceOutputService.shared.stop()
// Expected: Speech stops immediately

// Test 7: Speech rate
VoiceOutputService.shared.config.defaultRate = 0.7  // Faster
VoiceOutputService.shared.speak("This is faster speech")
// Expected: Speech is noticeably faster
```

**Success Criteria**:
- ✅ Hear all speech through correct audio route
- ✅ Pause/resume works correctly
- ✅ Stop interrupts speech immediately
- ✅ Speech rate affects speed

**Console Output to Check**:
```
🔊 [Audio] Speaking: Testing voice output | VoiceOutputService.swift:90
🔊 [Audio] Audio routed to: AirPods Pro | VoiceOutputService.swift:92
```

---

### 2. Voice Navigation Service ✅ (10 minutes)

**What You're Testing**: State machine, command processing, email navigation

**Steps**:
1. Navigate to `WearablesTestView` → "Voice" tab
2. Tap "Start Navigation"
3. Observe state changes

**Test Cases**:

```swift
// Test 1: Start navigation
let mockEmails = createMockEmails()  // 3 emails
VoiceNavigationService.shared.startNavigation(with: mockEmails)
// Expected: State changes to .inboxSummary
// Expected: Hear "You have 3 unread emails"

// Test 2: Check state
print("Current state: \(VoiceNavigationService.shared.currentState)")
// Expected: .inboxSummary

// Test 3: Read first email (simulated voice command)
// In production, this would come from Speech recognition
// For testing, we check the state machine logic
print("Emails available: \(VoiceNavigationService.shared.currentEmails.count)")
// Expected: 3

// Test 4: Stop navigation
VoiceNavigationService.shared.stopNavigation()
// Expected: State returns to .idle
// Expected: Speech stops
```

**Success Criteria**:
- ✅ State machine transitions correctly
- ✅ Email list is loaded
- ✅ Voice output narrates inbox summary
- ✅ Stop navigation works

**Note**: Full voice command testing requires Speech framework permissions and microphone access. For now, test state machine logic and voice output.

---

### 3. Meta Glasses Adapter ✅ (5 minutes)

**What You're Testing**: 4-tier connection system, audio routing, fallback logic

**Steps**:
1. **Test without any Bluetooth devices** (iPhone speaker fallback)
2. **Test with AirPods connected** (Tier 3 fallback)
3. **Check connection tier**

**Test Cases**:

```swift
// Test 1: Connect (no Bluetooth devices)
Task {
    await MetaGlassesAdapter.shared.connect()
    print("Connection tier: \(MetaGlassesAdapter.shared.connectionTier)")
    // Expected: .tier4_speaker
    print("Audio route: \(MetaGlassesAdapter.shared.audioRoute)")
    // Expected: "iPhone Speaker"
}

// Test 2: Connect with AirPods
// 1. Connect AirPods to iPhone
// 2. Re-run connection
Task {
    await MetaGlassesAdapter.shared.connect()
    print("Connection tier: \(MetaGlassesAdapter.shared.connectionTier)")
    // Expected: .tier3_airpods
    print("Audio route: \(MetaGlassesAdapter.shared.audioRoute)")
    // Expected: "AirPods Pro" (or your device name)
}

// Test 3: Play audio through glasses
Task {
    try await MetaGlassesAdapter.shared.playAudio("Testing audio routing")
    // Expected: Hear through AirPods or iPhone speaker
}

// Test 4: Check capabilities
print("Has display: \(MetaGlassesAdapter.shared.hasDisplay)")
// Expected: false (current Ray-Ban Meta doesn't have display)

print("Is connected: \(MetaGlassesAdapter.shared.isConnected)")
// Expected: false for tier4_speaker, true for tier1-3

// Test 5: Disconnect
MetaGlassesAdapter.shared.disconnect()
// Expected: Connection tier resets to .tier4_speaker
```

**Success Criteria**:
- ✅ Tier detection works (speaker → AirPods → speaker)
- ✅ Audio routes correctly
- ✅ Capabilities reported accurately
- ✅ Disconnect works

**Console Output to Check**:
```
📱 [Wearables] MetaGlassesAdapter initialized | MetaGlassesAdapter.swift:92
⚠️ [Wearables] Using iPhone speaker (Tier 4 fallback) | MetaGlassesAdapter.swift:93
```

**With AirPods**:
```
✓ [Wearables] Connected via AirPods/Bluetooth Audio (Tier 3) | MetaGlassesAdapter.swift:124
```

---

### 4. AR Display Service ✅ (5 minutes)

**What You're Testing**: Display mode detection, notification rendering, widget management

**Steps**:
1. Check display mode (will be .disabled or .arkit on iPhone)
2. Test notification rendering
3. Test widget display

**Test Cases**:

```swift
// Test 1: Check display mode
print("Display mode: \(ARDisplayService.shared.displayMode)")
// Expected: .arkit (if ARKit supported) or .disabled

// Test 2: Activate display
Task {
    do {
        try await ARDisplayService.shared.activateDisplay()
        print("Display activated: \(ARDisplayService.shared.isDisplayActive)")
        // Expected: true (if ARKit supported)
    } catch {
        print("Display error: \(error)")
        // Expected: ARDisplayError.displayUnavailable if not supported
    }
}

// Test 3: Show email notification
let mockEmail = WatchEmail(
    id: "1",
    title: "Test Email",
    sender: "Test Sender",
    senderInitial: "TS",
    timeAgo: "1m ago",
    priority: .high,
    archetype: "work",
    hpa: "Review",
    isUnread: true,
    isUrgent: true
)

ARDisplayService.shared.showEmailNotification(mockEmail)
// Expected: Notification queued (ARKit view would show it if implemented)

// Test 4: Show inbox widget
ARDisplayService.shared.showInboxCountWidget(unreadCount: 12, urgentCount: 3)
// Expected: Widget state updated
print("Widget unread: \(ARDisplayService.shared.inboxWidget?.unreadCount ?? 0)")
// Expected: 12

// Test 5: Update widget
ARDisplayService.shared.updateInboxWidget(unreadCount: 11, urgentCount: 3)
print("Widget unread after update: \(ARDisplayService.shared.inboxWidget?.unreadCount ?? 0)")
// Expected: 11

// Test 6: Show action confirmation
ARDisplayService.shared.showActionConfirmation(.archive)
// Expected: Confirmation queued

// Test 7: Sleep/wake display
ARDisplayService.shared.sleepDisplay()
print("Display state: \(ARDisplayService.shared.currentState)")
// Expected: .sleep

ARDisplayService.shared.wakeDisplay()
print("Display state after wake: \(ARDisplayService.shared.currentState)")
// Expected: .active
```

**Success Criteria**:
- ✅ Display mode detected correctly
- ✅ Notifications queue properly
- ✅ Widget state updates
- ✅ Sleep/wake transitions work

**Console Output to Check**:
```
🥽 [ARDisplay] ARDisplayService initialized (mode: arkit) | ARDisplayService.swift:68
✓ [ARDisplay] AR display activated | ARDisplayService.swift:94
```

**Note**: Visual AR rendering requires ARKit view implementation (not included yet). For now, test state management and notification queueing.

---

### 5. EMG Gesture Recognizer ✅ (10 minutes) ⭐️ **Most Fun!**

**What You're Testing**: Touch simulator, gesture detection, confidence thresholding

**Steps**:
1. Start EMG recognition (will use touch simulator)
2. Perform touch gestures on iPhone screen
3. Observe detected gestures in console

**Test Cases**:

```swift
// Test 1: Start recognition (touch simulator mode)
EMGGestureRecognizer.shared.startRecognition()
print("Using simulator: \(EMGGestureRecognizer.shared.isUsingSimulator)")
// Expected: true
print("Is active: \(EMGGestureRecognizer.shared.isActive)")
// Expected: true

// Test 2: Perform gestures (touch iPhone screen)
// You should see a transparent touch overlay

// Gesture 1: TAP (quick touch)
// Action: Tap screen quickly
// Expected console: "🤌 [EMG] Gesture: tap (95%) | EMGGestureRecognizer.swift:..."

// Gesture 2: HOLD (long press)
// Action: Touch and hold for 1 second
// Expected console: "🤌 [EMG] Gesture: hold (95%) | EMGGestureRecognizer.swift:..."

// Gesture 3: SWIPE LEFT
// Action: Swipe left across screen
// Expected console: "🤌 [EMG] Gesture: swipeLeft (95%) | EMGGestureRecognizer.swift:..."

// Gesture 4: SWIPE RIGHT
// Action: Swipe right across screen
// Expected console: "🤌 [EMG] Gesture: swipeRight (95%) | EMGGestureRecognizer.swift:..."

// Gesture 5: PINCH (vertical swipe or ambiguous)
// Action: Swipe vertically
// Expected console: "🤌 [EMG] Gesture: pinch (95%) | EMGGestureRecognizer.swift:..."

// Gesture 6: DOUBLE-PINCH (two rapid taps)
// Action: Tap twice quickly (< 0.5s between)
// Expected console: "🤌 [EMG] Gesture: doublePinch (95%) | EMGGestureRecognizer.swift:..."

// Test 3: Gesture callback
EMGGestureRecognizer.shared.onGestureRecognized = { gesture in
    print("App received gesture: \(gesture.type.rawValue)")
    // This is where you'd handle gestures in production
}

// Test 4: Stop recognition
EMGGestureRecognizer.shared.stopRecognition()
print("Is active: \(EMGGestureRecognizer.shared.isActive)")
// Expected: false
```

**Success Criteria**:
- ✅ Touch simulator starts
- ✅ All 6 gesture types detectable
- ✅ Gestures logged with confidence scores
- ✅ Callback fires for each gesture
- ✅ Stop recognition works

**Gesture Mapping Reference**:
| Touch Action | EMG Gesture | Use Case |
|--------------|-------------|----------|
| Quick tap | Tap | Select/confirm |
| Long press (0.8s+) | Hold | Show details |
| Swipe left | Swipe Left | Next email |
| Swipe right | Swipe Right | Previous email |
| Vertical swipe | Pinch | Archive email |
| Two quick taps | Double-Pinch | Flag email |

---

### 6. Watch Connectivity (iOS Side) ✅ (5 minutes)

**What You're Testing**: WCSession activation, state management

**Steps**:
1. Check watch connection status
2. Test session activation
3. **Optional**: Pair iPhone + watch simulators

**Test Cases**:

```swift
// Test 1: Check initial state
print("Watch paired: \(WatchConnectivityManager.shared.isWatchPaired)")
print("Watch reachable: \(WatchConnectivityManager.shared.isWatchReachable)")
print("Watch app installed: \(WatchConnectivityManager.shared.isWatchAppInstalled)")
// Expected: All false if no watch paired

// Test 2: Check session state
let (paired, reachable, installed) = WatchConnectivityManager.shared._testGetSessionState()
print("Session state: paired=\(paired), reachable=\(reachable), installed=\(installed)")

// Test 3: Set callbacks (required for production)
WatchConnectivityManager.shared.inboxDataProvider = {
    // Return mock data
    let mockEmails = createMockEmails()
    return (mockEmails.count, 1, mockEmails)
}

WatchConnectivityManager.shared.onActionReceived = { action, emailId in
    print("Watch requested action: \(action.rawValue) on \(emailId)")
    return true  // Success
}

// Test 4: Force push (will queue if watch not connected)
WatchConnectivityManager.shared._testForcePush()
// Expected: Console log showing push attempt
```

**Success Criteria**:
- ✅ Session activates without errors
- ✅ State properties update correctly
- ✅ Callbacks can be set
- ✅ Push attempt completes (even if watch not connected)

**Console Output to Check**:
```
📱 [Watch] WatchConnectivity initialized | WatchConnectivityManager.swift:68
✓ [Watch] WCSession activated | WatchConnectivityManager.swift:282
⚠️ [Watch] Cannot push inbox update: watch not ready | WatchConnectivityManager.swift:83
```

**To Test with Paired Watch**:
1. In Xcode: Window → Devices and Simulators
2. Select iPhone simulator
3. Under "Paired Watches", pair with a watch simulator
4. Run both simulators
5. Repeat tests above

---

### 7. Watch App (watchOS) ✅ (30 minutes) - Requires Xcode Target

**What You're Testing**: InboxView, swipe actions, offline queuing

**Prerequisites**:
1. Follow WATCHOS_APP_SETUP_GUIDE.md to create watch target
2. Build watch app on paired simulators

**Test Cases**:

Once watch app is running:

```
Test 1: Initial sync
- Expected: InboxView shows "Syncing with iPhone..."
- Expected: After 2-3 seconds, inbox data appears

Test 2: Email list
- Expected: See 3 mock emails
- Expected: Summary section shows "3 unread, 1 urgent"

Test 3: Swipe to archive
- Swipe left on first email
- Tap "Archive"
- Expected: Haptic feedback (success)
- Expected: Email disappears from list
- Expected: iPhone receives action within 5 seconds

Test 4: Email detail view
- Tap on an email
- Expected: Detail view shows sender, subject, HPA
- Tap "Archive" button
- Expected: Haptic feedback
- Expected: Alert: "Action Complete"

Test 5: Offline mode
- Disconnect watch (turn off iPhone Bluetooth)
- Archive an email on watch
- Expected: Haptic feedback (notification)
- Expected: Email marked for archive
- Reconnect (turn on Bluetooth)
- Expected: Within 10 seconds, action syncs to iPhone

Test 6: Pull to refresh
- Pull down on inbox
- Expected: "Syncing..." appears
- Expected: Fresh data from iPhone
```

**Success Criteria**:
- ✅ Inbox syncs from iPhone
- ✅ Swipe actions work
- ✅ Detail view renders correctly
- ✅ Offline actions queue and retry
- ✅ Pull to refresh works

---

## Integration Test Scenarios

Once individual services work, test combinations:

### Scenario 1: Voice → Watch Sync
```swift
// 1. Start voice navigation
VoiceNavigationService.shared.startNavigation(with: mockEmails)

// 2. Say "Archive this" (or simulate state machine)
// (In production, this would trigger email service)

// 3. Push update to watch
WatchConnectivityManager.shared._testForcePush()

// Expected: Watch inbox updates to show email archived
```

### Scenario 2: Meta Glasses → Voice Output
```swift
// 1. Connect to Meta Glasses (or AirPods)
await MetaGlassesAdapter.shared.connect()

// 2. Play audio through glasses
try await MetaGlassesAdapter.shared.playAudio("New email from Sarah")

// Expected: Hear audio through AirPods (simulating glasses)
```

### Scenario 3: EMG → Voice Confirmation
```swift
// 1. Start EMG recognition
EMGGestureRecognizer.shared.startRecognition()

// 2. Set callback
EMGGestureRecognizer.shared.onGestureRecognized = { gesture in
    if gesture.type == .pinch {
        // Archive email
        VoiceOutputService.shared.speak("Email archived")
        ARDisplayService.shared.showActionConfirmation(.archive)
    }
}

// 3. Perform pinch gesture
// Expected: Hear "Email archived" via voice
// Expected: AR confirmation (if display active)
```

---

## Troubleshooting

### Issue: "No such module 'WatchConnectivity'"
**Solution**: WatchConnectivity is iOS/watchOS only. Ensure `#if os(iOS)` or `#if os(watchOS)` wrappers are present.

### Issue: "Cannot find 'Logger' in scope"
**Solution**: Ensure Logger.swift is in your iOS target. Check that new categories were added.

### Issue: "Cannot find 'EmailCard' in scope"
**Solution**: WearablesTestView references EmailCard model. Ensure it's accessible.

### Issue: Simulator doesn't show EMG touch overlay
**Solution**:
1. Check that `EMGSimulator` created the touch window
2. Verify `touchWindow?.isHidden = false`
3. Try tapping in different screen areas

### Issue: Voice output not heard
**Solution**:
1. Check iPhone volume (not muted)
2. Check that audio session activated: `try? AVAudioSession.sharedInstance().setActive(true)`
3. Verify Bluetooth routing if using AirPods

### Issue: Watch simulator won't pair
**Solution**:
1. Xcode → Window → Devices and Simulators
2. Ensure iPhone simulator is running first
3. Select iPhone, then pair watch under "Paired Watches"
4. Wait 30 seconds for pairing to complete

---

## Success Checklist

Before production integration, verify:

**Voice Services**:
- [ ] Speech output works (iPhone speaker)
- [ ] Speech output works (Bluetooth/AirPods)
- [ ] Pause/resume works
- [ ] Speech rate configurable
- [ ] Inbox summary narration works
- [ ] Email reading works

**Meta Glasses**:
- [ ] Tier detection works (Tier 4 without BT, Tier 3 with AirPods)
- [ ] Audio routing correct
- [ ] Play audio through glasses/AirPods
- [ ] Disconnect/reconnect works

**AR Display**:
- [ ] Display mode detected
- [ ] Notifications queue properly
- [ ] Widget state updates
- [ ] Sleep/wake transitions

**EMG Gestures**:
- [ ] Touch simulator starts
- [ ] All 6 gestures detected
- [ ] Confidence scores shown
- [ ] Callback fires

**Watch (iOS)**:
- [ ] WCSession activates
- [ ] Callbacks can be set
- [ ] Force push works

**Watch (watchOS)** - After Xcode setup:
- [ ] Inbox syncs
- [ ] Swipe actions work
- [ ] Detail view renders
- [ ] Offline queueing works

**Integration**:
- [ ] Voice + Watch sync
- [ ] Meta Glasses + Voice output
- [ ] EMG + Voice confirmation

---

## Next Steps

Once all tests pass:

1. **Review WEARABLES_INTEGRATION_ROADMAP.md** for Week 7 integration plan
2. **<50 lines of code** to integrate into production
3. **Feature flags** for gradual rollout
4. **Week 8**: End-to-end testing with real users

---

## Quick Command Reference

```swift
// Voice
VoiceOutputService.shared.speak("Hello")
VoiceOutputService.shared.stop()

// Meta Glasses
await MetaGlassesAdapter.shared.connect()
print(MetaGlassesAdapter.shared.connectionTier)

// AR Display
try await ARDisplayService.shared.activateDisplay()
ARDisplayService.shared.showEmailNotification(email)

// EMG
EMGGestureRecognizer.shared.startRecognition()
EMGGestureRecognizer.shared.stopRecognition()

// Watch
WatchConnectivityManager.shared._testForcePush()
```

---

**Status**: ✅ All services ready for pre-integration testing
**Estimated Time**: 1-2 hours for full test suite
**Required**: Xcode, iOS simulator (watch target optional)

---

*Test with confidence. Ship with pride.* 🚀
