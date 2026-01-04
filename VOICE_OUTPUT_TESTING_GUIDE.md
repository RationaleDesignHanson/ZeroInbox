# Voice Output Service - Testing Guide

**Service**: `VoiceOutputService.swift`
**Created**: 2025-12-12
**Purpose**: Text-to-speech for voice-first wearables (Ray-Ban Meta, AirPods)

---

## Quick Start Testing

### 1. Setup

**Connect AirPods Pro** (or any Bluetooth audio device) to your iPhone/Mac.

### 2. Basic Integration

Add to any SwiftUI view where you want to test voice output:

```swift
import SwiftUI

struct VoiceTestView: View {
    @StateObject private var voiceService = VoiceOutputService.shared

    var body: some View {
        VStack(spacing: 20) {
            // Audio routing indicator
            HStack {
                Circle()
                    .fill(voiceService.isAudioRouted ? .green : .orange)
                    .frame(width: 12, height: 12)

                Text(voiceService.isAudioRouted ? "Bluetooth Connected" : "Using Speaker")
                    .font(.caption)
            }

            // Speaking indicator
            if voiceService.isSpeaking {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)
                    Text("Speaking...")
                }
            }

            // Test buttons
            Button("Test Inbox Summary") {
                testInboxSummary()
            }
            .buttonStyle(.borderedProminent)

            Button("Test Email Reading") {
                testEmailReading()
            }
            .buttonStyle(.bordered)

            Button("Test Simple Text") {
                voiceService.speak("This is a test of the voice output service.")
            }
            .buttonStyle(.bordered)

            // Control buttons
            HStack(spacing: 15) {
                Button("Pause") {
                    voiceService.pause()
                }
                .disabled(!voiceService.isSpeaking)

                Button("Resume") {
                    voiceService.resume()
                }

                Button("Stop") {
                    voiceService.stop()
                }
                .foregroundColor(.red)
            }

            // Speech rate control
            VStack {
                Text("Speech Rate: \(voiceService.config.defaultRate, specifier: "%.2f")")
                Slider(value: Binding(
                    get: { Double(voiceService.config.defaultRate) },
                    set: { voiceService.updateSpeechRate(Float($0)) }
                ), in: 0.3...0.7)
            }
            .padding()
        }
        .padding()
    }

    // MARK: - Test Functions

    private func testInboxSummary() {
        // Create mock emails
        let mockEmails = createMockEmails()

        // Read inbox summary
        voiceService.readInboxSummary(
            unreadCount: 15,
            topEmails: Array(mockEmails.prefix(3))
        )
    }

    private func testEmailReading() {
        let mockEmail = createMockEmails().first!

        // Read full email with body
        voiceService.readEmail(mockEmail, includeBody: true)
    }

    private func createMockEmails() -> [EmailCard] {
        return [
            EmailCard(
                id: "1",
                type: .work,
                state: .active,
                priority: .high,
                hpa: "Schedule Meeting",
                timeAgo: "2 hours ago",
                title: "Quarterly Review Meeting",
                summary: "Let's schedule our quarterly review for next week. I have availability Tuesday through Thursday afternoons.",
                aiGeneratedSummary: "Your manager wants to schedule the quarterly review meeting. They're available Tuesday to Thursday afternoons next week.",
                body: nil,
                htmlBody: nil,
                metaCTA: "Reply",
                sender: SenderInfo(email: "boss@company.com", name: "Sarah Chen"),
                recipientEmail: "you@company.com"
            ),
            EmailCard(
                id: "2",
                type: .shopping,
                state: .active,
                priority: .medium,
                hpa: "Track Package",
                timeAgo: "5 hours ago",
                title: "Your package has shipped",
                summary: "Your order from Amazon is on its way. Expected delivery: Tomorrow by 8 PM.",
                aiGeneratedSummary: "Your Amazon package shipped and will arrive tomorrow evening.",
                body: nil,
                htmlBody: nil,
                metaCTA: "Track",
                sender: SenderInfo(email: "ship-confirm@amazon.com", name: "Amazon"),
                recipientEmail: "you@gmail.com",
                trackingNumber: "1Z999AA10123456784"
            ),
            EmailCard(
                id: "3",
                type: .social,
                state: .active,
                priority: .low,
                hpa: "View",
                timeAgo: "1 day ago",
                title: "You have 5 new LinkedIn connections",
                summary: "Connect with more professionals in your industry.",
                aiGeneratedSummary: "LinkedIn notification about new connection requests.",
                body: nil,
                htmlBody: nil,
                metaCTA: "View",
                sender: SenderInfo(email: "notifications@linkedin.com", name: "LinkedIn"),
                recipientEmail: "you@gmail.com"
            )
        ]
    }
}

// MARK: - Preview

#Preview {
    VoiceTestView()
}
```

---

## Testing Checklist

### Audio Routing Tests

- [ ] **Test 1: Bluetooth Detection**
  - Connect AirPods
  - Launch app
  - Verify green indicator shows "Bluetooth Connected"
  - Disconnect AirPods
  - Verify orange indicator shows "Using Speaker"

- [ ] **Test 2: Audio Playback**
  - With AirPods connected, tap "Test Simple Text"
  - Verify audio plays through AirPods (not iPhone speaker)
  - Check audio quality and clarity
  - Verify no distortion or crackling

- [ ] **Test 3: Screen Lock**
  - Start voice playback
  - Lock iPhone screen
  - Verify audio continues playing
  - Unlock and verify UI updates correctly

---

### Speech Quality Tests

- [ ] **Test 4: Inbox Summary**
  - Tap "Test Inbox Summary"
  - Expected output:
    ```
    "You have 15 unread emails. Top priority:
     1. Quarterly Review Meeting from Sarah Chen.
     2. Your package has shipped from Amazon.
     3. You have 5 new LinkedIn connections from LinkedIn."
    ```
  - Verify:
    - Clear pronunciation
    - Natural pacing (not too fast/slow)
    - Proper pauses between items
    - Numbers spoken correctly ("fifteen" not "one five")

- [ ] **Test 5: Full Email Reading**
  - Tap "Test Email Reading"
  - Expected output:
    ```
    "Email: Quarterly Review Meeting.
     From Sarah Chen.
     Received 2 hours ago.
     This is a high priority email.
     Message: Your manager wants to schedule the quarterly review meeting.
     They're available Tuesday to Thursday afternoons next week."
    ```
  - Verify:
    - All components present (subject, sender, time, body)
    - High priority announcement included
    - Body text clean (no HTML artifacts)

- [ ] **Test 6: Speech Rate Adjustment**
  - Use slider to set rate to 0.3 (slow)
  - Speak test text
  - Verify speech is slow but natural
  - Set rate to 0.7 (fast)
  - Verify speech is faster but still clear
  - Set rate to 0.5 (default)
  - Verify natural, comfortable pace

---

### Control Tests

- [ ] **Test 7: Pause/Resume**
  - Start long speech (inbox summary)
  - Tap "Pause" mid-speech
  - Verify speech stops immediately
  - Wait 2 seconds
  - Tap "Resume"
  - Verify speech continues from where it paused

- [ ] **Test 8: Stop**
  - Start speech
  - Tap "Stop" mid-speech
  - Verify speech stops immediately
  - Verify `isSpeaking` indicator disappears
  - Start new speech
  - Verify previous speech doesn't resume

- [ ] **Test 9: Interruption**
  - Start speech
  - Immediately start new speech (without stopping)
  - Verify first speech stops and second begins
  - No overlapping audio

---

### Edge Case Tests

- [ ] **Test 10: Empty Text**
  - Try to speak empty string: `voiceService.speak("")`
  - Verify no crash
  - Verify warning logged
  - No audio plays

- [ ] **Test 11: Very Long Text**
  - Create email with 1000+ character body
  - Read email with body
  - Verify body is truncated to ~300 characters
  - Verify speech doesn't take excessively long

- [ ] **Test 12: Special Characters**
  - Create email with subject: "Meeting @ 3pm - Q&A Session"
  - Read email
  - Verify special characters handled gracefully:
    - "@" spoken as "at"
    - "&" spoken as "and"
    - "-" as pause

- [ ] **Test 13: HTML in Body**
  - Create email with HTML: `<b>Important:</b> Please review &nbsp; the document`
  - Read email with body
  - Verify HTML tags removed
  - Verify HTML entities decoded (&nbsp; → space)

---

### Performance Tests

- [ ] **Test 14: Battery Drain**
  - Fully charge AirPods
  - Note battery percentage
  - Continuously play voice output for 1 hour (use timer)
  - Check battery percentage
  - **Target**: < 10% drain per hour
  - **Acceptable**: 10-15% drain
  - **Fail**: > 15% drain

- [ ] **Test 15: Memory Leaks**
  - Open Xcode Instruments
  - Run "Leaks" tool
  - Start/stop voice output 20 times rapidly
  - Check for memory leaks
  - **Target**: 0 leaks

- [ ] **Test 16: Latency**
  - Measure time from button tap to audio start
  - Use Instruments "Time Profiler"
  - **Target**: < 500ms from tap to speech
  - **Acceptable**: 500ms - 1 second
  - **Fail**: > 1 second

---

## Integration with Inbox View

To add voice output to your existing inbox:

```swift
// In InboxView.swift or EmailDetailView.swift

import SwiftUI

struct InboxView: View {
    @StateObject private var voiceService = VoiceOutputService.shared
    @ObservedObject var viewModel: InboxViewModel

    var body: some View {
        VStack {
            // Existing inbox UI...

            // Add voice control button
            Button(action: readInboxSummary) {
                Label(
                    voiceService.isSpeaking ? "Speaking..." : "Read Inbox",
                    systemImage: voiceService.isSpeaking ? "waveform" : "speaker.wave.2"
                )
            }
            .buttonStyle(.bordered)
        }
    }

    private func readInboxSummary() {
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
}
```

### Email Detail View Integration

```swift
// In EmailDetailView.swift

struct EmailDetailView: View {
    let email: EmailCard
    @StateObject private var voiceService = VoiceOutputService.shared

    var body: some View {
        VStack {
            // Existing email detail UI...

            // Voice control toolbar
            HStack(spacing: 20) {
                Button(action: {
                    voiceService.readEmail(email, includeBody: true)
                }) {
                    Label("Read Aloud", systemImage: "speaker.wave.2")
                }

                if voiceService.isSpeaking {
                    Button(action: {
                        voiceService.stop()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
}
```

---

## Common Issues & Troubleshooting

### Issue: Audio plays through iPhone speaker instead of AirPods

**Cause**: Audio route not properly configured

**Solution**:
1. Verify AirPods are connected in iOS Settings → Bluetooth
2. Check `isAudioRouted` property is `true`
3. Try disconnecting and reconnecting AirPods
4. Check if other apps can route to AirPods

### Issue: Speech sounds robotic or choppy

**Cause**: Speech rate too fast or audio session interruption

**Solution**:
1. Lower speech rate to 0.4-0.5
2. Check for audio interruptions in logs
3. Try closing other apps using audio
4. Restart device if issue persists

### Issue: Voice output doesn't start

**Cause**: Audio permissions or session configuration

**Solution**:
1. Check logs for audio session errors
2. Verify no other audio is playing
3. Check device volume is > 0
4. Try restarting the app

### Issue: Memory usage increases over time

**Cause**: Utterances not being released

**Solution**:
1. Check `synthesizer.stopSpeaking()` is called before new speech
2. Verify delegate methods are updating `currentUtterance = nil`
3. Profile with Instruments to identify leaks

---

## Next Steps

Once voice output is tested and working:

1. **Week 2**: Integrate into InboxView and EmailDetailView
2. **Week 3-4**: Build VoiceNavigationService (command processing)
3. **Week 5**: Test with physical Ray-Ban Meta glasses (if available)

---

## Success Criteria

**Voice Output Service is considered ready when**:
- [ ] Audio routes to AirPods reliably
- [ ] Inbox summary reads clearly (all 3 top emails)
- [ ] Full email reading works (subject + sender + body)
- [ ] Pause/resume/stop controls work perfectly
- [ ] Speech rate adjustment works
- [ ] No memory leaks after 50+ uses
- [ ] Battery drain < 10% per hour on AirPods
- [ ] Latency < 500ms from command to speech

---

**Document Version**: 1.0
**Last Updated**: 2025-12-12
**Status**: Ready for testing
