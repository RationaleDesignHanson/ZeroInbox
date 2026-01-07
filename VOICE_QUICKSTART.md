# Voice Output - Quick Start Guide

**Status**: Ready to test! 🎧
**Files Added**: VoiceTestView.swift, VoiceOutputService.swift

---

## Step 1: Add VoiceTestView to Your App

The easiest way to test voice output is to add a navigation link to `VoiceTestView` in your existing app.

### Option A: Add to Main Navigation (Recommended)

If you have a settings or debug menu, add this:

```swift
// In your settings view or main navigation
NavigationLink(destination: VoiceTestView()) {
    Label("Voice Test", systemImage: "speaker.wave.2")
}
```

### Option B: Temporary Button in ContentView

Add a test button to your main ContentView:

```swift
// In ContentView.swift or ZeroApp.swift
import SwiftUI

struct ContentView: View {
    @State private var showVoiceTest = false

    var body: some View {
        VStack {
            // Your existing content...

            // Temporary test button
            Button("🎧 Test Voice") {
                showVoiceTest = true
            }
            .padding()
        }
        .sheet(isPresented: $showVoiceTest) {
            VoiceTestView()
        }
    }
}
```

### Option C: Run Directly from Preview

1. Open `VoiceTestView.swift` in Xcode
2. Click the "Play" button in the preview pane
3. Or press `⌘ + Shift + Return` to run preview

---

## Step 2: Connect AirPods (or Bluetooth Device)

1. **Pair AirPods** with your Mac/iPhone
2. **Verify Connection**: Settings → Bluetooth → AirPods should show "Connected"
3. **Check Volume**: Make sure volume is at comfortable level

**Expected**: Green "Bluetooth Connected" indicator in VoiceTestView

---

## Step 3: Run the App

```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero
open Zero.xcodeproj

# Build and run
# Select your device/simulator
# Press ⌘ + R
```

---

## Step 4: Test Voice Output

### Test 1: Simple Text (30 seconds)
1. Tap **"Simple Text"** button
2. Expected output: "This is a test of the voice output service..."
3. ✅ Verify audio plays through AirPods
4. ✅ Verify clear audio quality

### Test 2: Inbox Summary (1 minute)
1. Tap **"Inbox Summary (3 emails)"** button
2. Expected output:
   - "You have 15 unread emails. Top priority:"
   - "1. Quarterly Review Meeting from Sarah Chen."
   - "2. Your package has shipped from Amazon."
   - "3. You have 5 new LinkedIn connections from LinkedIn."
3. ✅ Verify all 3 emails are read
4. ✅ Verify natural pacing (not too fast)

### Test 3: Full Email Reading (1 minute)
1. Select email type: Work / Shopping / Social
2. Tap **"Full Email"** button
3. Expected output:
   - Subject
   - Sender name
   - Time received
   - Priority (if high)
   - Email body/summary
4. ✅ Verify complete email details
5. ✅ Verify body text is clean (no HTML)

### Test 4: Playback Controls (1 minute)
1. Start long speech (Inbox Summary)
2. Tap **"Pause"** mid-speech
3. ✅ Verify speech stops
4. Wait 2 seconds
5. Tap **"Resume"**
6. ✅ Verify speech continues from pause point
7. Tap **"Stop"**
8. ✅ Verify speech stops completely

### Test 5: Speech Rate (30 seconds)
1. Move slider to **0.3 (Slow)**
2. Tap "Simple Text"
3. ✅ Verify slow but natural speech
4. Move slider to **0.7 (Fast)**
5. Tap "Simple Text"
6. ✅ Verify fast but clear speech
7. Tap **"Reset to Default"**
8. ✅ Verify rate returns to 0.50

---

## Expected Results

✅ **Pass Criteria**:
- Audio routes to AirPods (green indicator)
- All test cases work without errors
- Speech is clear and natural
- Controls (pause/resume/stop) work reliably
- Speech rate adjustment works smoothly

❌ **Common Issues**:
- **Audio plays through iPhone speaker**: Disconnect and reconnect AirPods
- **No sound**: Check device volume, check Bluetooth connection
- **Robotic/choppy speech**: Lower speech rate to 0.4-0.5
- **App crashes**: Check Xcode console for errors, verify VoiceOutputService.swift compiled

---

## Next Steps After Testing

### If Tests Pass ✅

**Integrate into InboxView**:

```swift
// In InboxView.swift
@StateObject private var voiceService = VoiceOutputService.shared

// Add button to toolbar
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: readInboxAloud) {
            Image(systemName: voiceService.isSpeaking ? "waveform" : "speaker.wave.2")
        }
    }
}

private func readInboxAloud() {
    if voiceService.isSpeaking {
        voiceService.stop()
    } else {
        let unreadEmails = viewModel.emails.filter { !$0.state.isArchived }
        voiceService.readInboxSummary(
            unreadCount: unreadEmails.count,
            topEmails: Array(unreadEmails.prefix(3))
        )
    }
}
```

**Integrate into EmailDetailView**:

```swift
// In EmailDetailView.swift
@StateObject private var voiceService = VoiceOutputService.shared

// Add read button
Button(action: { voiceService.readEmail(email, includeBody: true) }) {
    Label("Read Aloud", systemImage: "speaker.wave.2")
}
.buttonStyle(.borderedProminent)
```

### If Tests Fail ❌

**Check Logs**:
```swift
// VoiceOutputService logs with category .voice
// Look for:
// ✓ Audio session configured
// ✓ Audio routing to Bluetooth
// ✓ Selected voice: [name]
// 🔊 Speaking: "..."
```

**Common Fixes**:
1. Restart Xcode
2. Clean build folder (⌘ + Shift + K)
3. Restart device
4. Check microphone/speech permissions in Settings

---

## Performance Benchmarks

After 1 hour of testing, check:

| Metric | Target | Check |
|--------|--------|-------|
| Battery drain (AirPods) | < 10%/hour | [ ] |
| Latency (tap → speech) | < 500ms | [ ] |
| Memory leaks | 0 leaks | [ ] |
| Crash rate | 0 crashes | [ ] |

**Tools**:
- Battery: Settings → Bluetooth → AirPods → Battery level
- Latency: Feels instant (no noticeable delay)
- Memory: Xcode → Product → Profile → Leaks
- Crashes: Xcode console

---

## Troubleshooting

### Issue: "Bluetooth Connected" shows orange, not green

**Cause**: AirPods not connected or not detected

**Fix**:
1. Open iOS/macOS Settings → Bluetooth
2. Verify AirPods show "Connected"
3. If not connected, tap to connect
4. Relaunch app
5. Green indicator should appear

### Issue: Speech sounds robotic

**Cause**: Speech rate too high or poor quality voice selected

**Fix**:
1. Lower speech rate to 0.40-0.45
2. App will automatically select best "enhanced" voice
3. If issue persists, check device storage (low storage can affect voice quality)

### Issue: App crashes when tapping voice buttons

**Cause**: VoiceOutputService.swift not compiled or missing dependencies

**Fix**:
1. Clean build folder: ⌘ + Shift + K
2. Rebuild: ⌘ + B
3. Check Xcode errors
4. Verify VoiceOutputService.swift is in target membership

### Issue: No sound at all

**Cause**: Device volume at 0, or audio session not configured

**Fix**:
1. Check device volume (side buttons)
2. Check ringer/silent switch (if applicable)
3. Check Xcode console for audio session errors
4. Try disconnecting and reconnecting AirPods

---

## Success! What You've Achieved

🎉 **You now have**:
- ✅ Production-ready text-to-speech service
- ✅ Bluetooth audio routing to wearables
- ✅ Email reading capability
- ✅ Inbox summary narration
- ✅ Full playback controls
- ✅ Ready for Meta Ray-Ban glasses integration

🚀 **This unlocks**:
- Voice-first email management (hands-free)
- Ray-Ban Meta glasses support (Week 3)
- Voice navigation (Week 3-4)
- Accessibility features (VoiceOver enhancement)

---

## Estimated Time

**Total Testing Time**: 30-60 minutes
- Setup: 5 minutes
- Basic tests: 15 minutes
- Control tests: 10 minutes
- Performance tests: 30 minutes

**Next Development**:
- Integration into InboxView: 30 minutes
- Integration into EmailDetailView: 30 minutes
- watchOS widget testing: 1-2 hours

---

**Ready to test?** Connect your AirPods and let's hear your emails! 🎧
