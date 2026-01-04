# watchOS Setup Guide - Enable Widgets on Apple Watch

**Goal**: Enable existing iOS widgets to run on Apple Watch as complications
**Time Required**: 30-60 minutes
**Prerequisites**: Xcode 15+, watchOS 10+ simulator

---

## Overview

Your existing widgets in `ZeroWidget.swift` already support watchOS-compatible families:
- ✅ `.accessoryCircular` → Watch complication (circular)
- ✅ `.accessoryRectangular` → Watch complication (rectangular/modular)
- ✅ `.accessoryInline` → Watch complication (inline text)

**We just need to add watchOS as a deployment target!**

---

## Option 1: Xcode GUI (Recommended for Beginners)

### Step 1: Open Xcode Project

```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero
open Zero.xcodeproj
```

### Step 2: Select Widget Target

1. In Xcode's left sidebar (Project Navigator), click the **blue project icon** at the top
2. In the main editor, you'll see "TARGETS" list
3. Look for **ZeroWidget** or **ZeroWidgetExtension** target
4. Click to select it

### Step 3: Add watchOS Deployment

1. With ZeroWidget target selected, click **"General"** tab at top
2. Scroll to **"Supported Destinations"** section
3. You'll see a list showing "iOS" (probably with checkmark)
4. Click the **"+"** button at the bottom of the list
5. In the dropdown that appears, select **"watchOS"**
6. Set **Minimum Deployment** to **"watchOS 10.0"** or later

**Expected Result**: You should now see both "iOS" and "watchOS" in Supported Destinations

### Step 4: Verify App Groups on watchOS

1. Still in ZeroWidget target, click **"Signing & Capabilities"** tab
2. Look for **"App Groups"** capability
3. Verify `group.com.zero.email` is checked
4. If you see a second column for watchOS, verify it's enabled there too

### Step 5: Build for watchOS Simulator

1. At the top of Xcode, click the **device selector** (next to the Run button)
2. In the dropdown, look for **"Apple Watch"** simulators
3. Select **"Apple Watch Series 9 (45mm)"** or any watchOS 10+ simulator
4. Press **⌘ + B** to build

**Expected**: Build succeeds with no errors

### Step 6: Test on watchOS Simulator

1. **Launch iOS simulator first** (widgets need parent app):
   - Select iPhone 15 Pro simulator
   - Run the main Zero app (⌘ + R)

2. **Launch watchOS simulator**:
   - In Terminal:
   ```bash
   # List available watch simulators
   xcrun simctl list devices | grep "Apple Watch"

   # Boot a watch simulator (replace UDID with yours)
   xcrun simctl boot <WATCH_UDID>

   # Pair with iPhone simulator
   open -a Simulator
   ```

3. **Add widget to watch face**:
   - On watch simulator, force-touch the watch face
   - Tap "Customize"
   - Select a complication slot
   - Scroll to find "Zero Inbox"
   - Select it
   - You should see your inbox count!

---

## Option 2: Command Line (Advanced)

### Build for watchOS Simulator

```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero

# Build widget for watchOS
xcodebuild \
  -project Zero.xcodeproj \
  -scheme "ZeroWidget" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
  -configuration Debug \
  build

# Check for errors
# Expected: ** BUILD SUCCEEDED **
```

### Pair iOS and watchOS Simulators

```bash
# List all simulators
xcrun simctl list devices

# Note the UDID of:
# - iPhone 15 Pro (or similar iOS 17+ device)
# - Apple Watch Series 9 (or similar watchOS 10+ device)

# Pair them (replace UDIDs)
xcrun simctl pair <WATCH_UDID> <IPHONE_UDID>

# Boot both simulators
xcrun simctl boot <IPHONE_UDID>
xcrun simctl boot <WATCH_UDID>

# Install widget on watch
xcodebuild \
  -project Zero.xcodeproj \
  -scheme "ZeroWidget" \
  -destination 'platform=watchOS Simulator,id=<WATCH_UDID>' \
  install
```

---

## Troubleshooting

### Issue: "No such module 'WidgetKit' for watchOS"

**Cause**: WidgetKit not linked for watchOS target

**Fix**:
1. Select ZeroWidget target
2. Go to "Build Phases"
3. Expand "Link Binary With Libraries"
4. Click "+" button
5. Add WidgetKit.framework
6. Ensure it's added for watchOS platform

### Issue: "App Group not found on watchOS"

**Cause**: App Group capability not enabled for watchOS

**Fix**:
1. Select ZeroWidget target
2. Go to "Signing & Capabilities"
3. If there are separate tabs for iOS and watchOS, click watchOS tab
4. Ensure "App Groups" capability is added
5. Check `group.com.zero.email`

### Issue: Build succeeds but widget doesn't appear on watch

**Cause**: Widget not installed or watch not paired

**Fix**:
1. Verify iOS and watchOS simulators are paired:
   ```bash
   xcrun simctl list pairs
   ```
2. Rebuild and reinstall widget
3. Restart both simulators
4. Try adding complication again

### Issue: "Cannot find ZeroWidget in Available Complications"

**Cause**: Widget may not be visible due to family restrictions

**Fix**:
1. Try different watch faces (some support more complications)
2. Verify `supportedFamilies` in ZeroWidget.swift includes accessory families
3. Check widget bundle ID matches in Xcode

---

## Verification Checklist

After setup, verify the following:

### Build Verification
- [ ] Project builds successfully for watchOS Simulator
- [ ] No compilation errors or warnings
- [ ] App Group accessible (check logs)

### Simulator Verification
- [ ] iOS simulator running Zero app
- [ ] watchOS simulator paired with iOS simulator
- [ ] Both simulators booted and responsive

### Widget Verification
- [ ] ZeroWidget appears in watch face customization
- [ ] Can add widget to complication slot
- [ ] Widget displays inbox count
- [ ] Inbox count matches iOS app data

### Data Sync Verification
- [ ] Archive email in iOS app
- [ ] Watch complication updates within 15 minutes
- [ ] Correct unread count displayed
- [ ] Widget doesn't crash when tapped

---

## Expected Complications on Apple Watch

Your widgets should appear in these forms:

### 1. Circular Complication (`accessoryCircular`)
```
┌─────────┐
│    📧   │
│   12    │  ← Unread count
│  INBOX  │
└─────────┘
```
**Best for**: Corner complications on Modular, Infograph faces

### 2. Rectangular Complication (`accessoryRectangular`)
```
┌─────────────────────────┐
│ 📧  Zero Inbox          │
│     12 unread           │
└─────────────────────────┘
```
**Best for**: Modular Large, Infograph Modular

### 3. Inline Complication (`accessoryInline`)
```
📧 Zero: 12 unread
```
**Best for**: Top of Modular, Infograph faces

---

## Testing the Complication

### Test 1: Data Display (2 minutes)
1. Add circular complication to watch face
2. Expected: Shows inbox count (e.g., "12")
3. ✅ Verify number is readable
4. ✅ Verify icon displays correctly

### Test 2: Data Update (15 minutes)
1. Note current inbox count on watch
2. In iOS app, archive an email
3. Wait up to 15 minutes (widget refresh interval)
4. Expected: Watch complication updates to new count
5. ✅ Verify count decreased by 1

### Test 3: Tap Complication (1 minute)
1. Tap the complication on watch face
2. Expected: Opens Zero app on iPhone (if implemented)
3. ✅ Verify tap is recognized
4. ✅ Verify app launches (or appropriate behavior)

### Test 4: Multiple Complications (2 minutes)
1. Add all 3 complication types to watch face
2. Circular, Rectangular, Inline
3. Expected: All show same inbox count
4. ✅ Verify consistency across types
5. ✅ Verify no rendering issues

---

## Next Steps After watchOS Widgets Work

### Phase 1 Complete ✅
- [x] Widgets running on watchOS simulator
- [x] Complications displaying inbox count
- [x] Data syncing from iOS app

### Phase 2: Native Watch App (Week 3-4)
- [ ] Create watchOS app target (Zer0Watch)
- [ ] Implement WatchConnectivityManager
- [ ] Build inbox list view on watch
- [ ] Add email detail view
- [ ] Implement watch-specific actions (archive, flag)

### Phase 3: Physical Device Testing (Week 3)
- [ ] Acquire Apple Watch Series 6+
- [ ] Test on physical hardware
- [ ] Measure battery drain
- [ ] Test complication reliability
- [ ] Test in real-world conditions (outdoors, bright light, etc.)

---

## Performance Targets

After watchOS widgets are working, verify:

| Metric | Target | Status |
|--------|--------|--------|
| **Build time** | < 30 seconds | [ ] |
| **Widget update latency** | < 15 minutes | [ ] |
| **Complication render time** | < 100ms | [ ] |
| **Memory usage (watch)** | < 20MB | [ ] |
| **Simulator stability** | No crashes | [ ] |

---

## Advanced: Enable Background Updates

For more frequent widget updates, enable background app refresh:

1. Select main Zero target (not widget)
2. Go to "Signing & Capabilities"
3. Add **"Background Modes"** capability
4. Check **"Background fetch"**
5. Implement background sync in AppLifecycleObserver.swift

```swift
// In AppLifecycleObserver.swift (iOS app)
func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    Task {
        do {
            // Sync inbox
            let newEmails = try await emailService.syncInbox()

            // Update widget data
            WidgetDataService.updateWidgetData(/* ... */)

            completionHandler(newEmails.isEmpty ? .noData : .newData)
        } catch {
            completionHandler(.failed)
        }
    }
}
```

---

## Success Criteria

**watchOS widgets are considered ready when**:
- [ ] Build succeeds for watchOS Simulator
- [ ] All 3 complication types display correctly
- [ ] Inbox count updates within 15 minutes
- [ ] No crashes or rendering issues
- [ ] Data syncs reliably from iOS app
- [ ] Memory usage < 20MB
- [ ] Ready for physical device testing

---

## Estimated Time

**Total Setup**: 30-60 minutes
- Xcode configuration: 10 minutes
- Simulator setup: 10 minutes
- Widget testing: 20-30 minutes
- Troubleshooting: 10 minutes (if needed)

**You'll unlock**:
- ✅ Glanceable inbox status on watch
- ✅ Foundation for native watch app (Week 3-4)
- ✅ Proof of concept for wearables integration

---

**Ready to enable watchOS?** Follow Option 1 if you're comfortable with Xcode GUI, or Option 2 for command-line approach. Let me know if you hit any issues! ⌚️
