# watchOS App Setup Guide
## Zer0 Inbox - Apple Watch Implementation

**Version**: 1.0
**Status**: Week 3-4 Implementation
**Target**: Apple Watch Series 6+ with watchOS 10+
**Date**: 2025-12-12

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Create watchOS App Target](#step-1-create-watchos-app-target)
4. [Step 2: Add Files to Watch Target](#step-2-add-files-to-watch-target)
5. [Step 3: Configure Build Settings](#step-3-configure-build-settings)
6. [Step 4: Test on Simulator](#step-4-test-on-simulator)
7. [Step 5: Test on Physical Watch](#step-5-test-on-physical-watch)
8. [Troubleshooting](#troubleshooting)
9. [Next Steps](#next-steps)

---

## Overview

This guide walks you through setting up the **Zer0 Watch** app target in Xcode. All code is already written and ready to use - you just need to configure the Xcode project.

**What You'll Build**:
- watchOS app target (Zer0Watch)
- Inbox view with swipe actions
- Email detail view
- Bidirectional sync with iPhone

**Time Required**: 30-45 minutes

**Complexity**: Medium (requires Xcode GUI configuration)

---

## Prerequisites

### Required

- ✅ Xcode 15.0+ installed
- ✅ iPhone simulator or physical iPhone
- ✅ Apple Watch simulator or physical Apple Watch Series 6+
- ✅ All watchOS code files created (in `Zero/Watch/` directory)
- ✅ iOS WatchConnectivityManager implemented
- ✅ WatchModels.swift shared models

### Optional (for physical testing)

- Apple Developer account (for device provisioning)
- Apple Watch paired with iPhone

---

## Step 1: Create watchOS App Target

### 1.1 Open Xcode Project

```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2
open Zero.xcodeproj
```

### 1.2 Add New Target

1. In Xcode, go to **File → New → Target**
2. Select **watchOS** tab at the top
3. Choose **Watch App** (NOT "Watch App for iOS App")
4. Click **Next**

### 1.3 Configure Target

| Setting | Value |
|---------|-------|
| **Product Name** | Zer0Watch |
| **Team** | (Select your team) |
| **Organization Identifier** | com.zero |
| **Bundle Identifier** | com.zero.Zer0.watchkitapp |
| **Interface** | SwiftUI |
| **Language** | Swift |

5. Click **Finish**
6. When prompted "Activate 'Zer0Watch' scheme?", click **Activate**

### 1.4 Verify Target Created

You should now see:
- New folder: `Zer0Watch` in Project Navigator
- New scheme: `Zer0Watch` in scheme selector (top-left of Xcode)

---

## Step 2: Add Files to Watch Target

### 2.1 Add Shared Models

`WatchModels.swift` must be added to **BOTH** iOS and watchOS targets:

1. Select `Models/WatchModels.swift` in Project Navigator
2. Open **File Inspector** (right sidebar, first tab)
3. Under **Target Membership**, check:
   - ✅ Zero (iOS)
   - ✅ Zer0Watch (watchOS)

**Important**: This file must be compiled for both targets.

### 2.2 Add watchOS-Only Files

These files should **ONLY** be in the watchOS target:

**From `Zero/Watch/` directory**:
- `WatchConnectivityManager_watchOS.swift`
- `Zer0WatchApp.swift`
- `Views/InboxView.swift`
- `Views/EmailDetailView.swift`

**How to Add**:
1. Select file in Project Navigator
2. Open **File Inspector** (right sidebar)
3. Under **Target Membership**, check:
   - ⚪ Zero (iOS) - **UNCHECKED**
   - ✅ Zer0Watch (watchOS) - **CHECKED**

### 2.3 Rename WatchConnectivityManager (watchOS)

To avoid naming conflicts:

1. In Project Navigator, rename:
   - `WatchConnectivityManager_watchOS.swift` → `WatchConnectivityManager.swift` (for watchOS target)

**Why?** Both iOS and watchOS have a file named `WatchConnectivityManager.swift`, but they're in different targets:
- iOS target: `Services/WatchConnectivityManager.swift` (already exists)
- watchOS target: `Watch/WatchConnectivityManager.swift` (just added)

They won't conflict because they're in separate targets and both use `#if os(iOS)` / `#if os(watchOS)` compiler directives.

### 2.4 Delete Xcode-Generated Files (Optional)

Xcode created placeholder files you don't need:

**Delete these from watchOS target**:
- `Zer0WatchApp.swift` (Xcode's placeholder - replace with ours)
- `ContentView.swift` (we use InboxView instead)

**Keep these**:
- `Assets.xcassets` (for watch app icon)
- `Preview Content` (for SwiftUI previews)

---

## Step 3: Configure Build Settings

### 3.1 Set Minimum Deployment Target

1. Select **Zer0Watch** target (Project Navigator, top section)
2. Go to **General** tab
3. Set **Minimum Deployments** to **watchOS 10.0**

### 3.2 Configure App Groups

Watch app needs access to shared data:

1. Select **Zer0Watch** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Check: `group.com.zero.email` (same as iOS app)

**Important**: Must be the exact same App Group ID as iOS app.

### 3.3 Enable WatchConnectivity

1. Still in **Signing & Capabilities**
2. Verify **WatchConnectivity** is enabled (should be by default)

### 3.4 Configure Logger (if not already global)

If `Logger` utility is not available globally:

**Option A**: Add Logger to watchOS target
1. Select `Utilities/Logger.swift` (or wherever Logger is defined)
2. Add to watchOS target (Target Membership)

**Option B**: Use `print()` fallback
1. In watchOS files, replace `Logger.info()` with `print()`

---

## Step 4: Test on Simulator

### 4.1 Select Watch Simulator

1. In Xcode, scheme selector (top-left), choose:
   - **Zer0Watch** scheme
   - **Apple Watch Series 9 (45mm)** simulator (or any watchOS 10+ simulator)

### 4.2 Build and Run

1. Click **Run** (▶️) or press `Cmd+R`
2. Wait for build to complete (~30 seconds first time)
3. Watch simulator should launch

**Expected Result**:
- Watch app opens to InboxView
- Shows "Syncing with iPhone..." (because iPhone app not running yet)

### 4.3 Pair iPhone Simulator

To test WatchConnectivity:

1. **Stop** watch app (⏹)
2. In scheme selector, switch to **Zero** (iOS app) scheme
3. Select **iPhone 15 Pro** simulator (or any iOS 17+ simulator)
4. Run iOS app (`Cmd+R`)
5. Once iOS app launches, go to **Xcode → Window → Devices and Simulators**
6. Select watch simulator
7. Under **Paired iPhone**, select the iPhone simulator you just launched

**Now test connectivity**:

1. Switch back to **Zer0Watch** scheme
2. Run watch app
3. Watch app should now receive inbox data from iPhone app

### 4.4 Test Swipe Actions

1. In watch app, swipe left on an email
2. Tap **Archive**
3. Email should disappear (or be marked as archived)
4. Check iOS app - email should be archived there too

**Expected Latency**: < 5 seconds from watch tap to iPhone update.

---

## Step 5: Test on Physical Watch

### 5.1 Requirements

- Apple Watch Series 6+ with watchOS 10+
- Watch paired with your iPhone
- Apple Developer account (free tier is fine)

### 5.2 Configure Signing

1. Select **Zer0Watch** target
2. Go to **Signing & Capabilities**
3. Set **Team** to your Apple ID
4. Xcode will auto-generate provisioning profile

### 5.3 Connect Devices

1. Connect iPhone to Mac via USB
2. Unlock iPhone
3. Trust Mac (if prompted)
4. Wait for Xcode to detect watch (appears next to iPhone in Devices window)

### 5.4 Build to Watch

1. In scheme selector, choose:
   - **Zer0Watch** scheme
   - **Your Watch** (appears as "Matt's Apple Watch" or similar)
2. Click **Run** (▶️)
3. Wait for build and install (~1-2 minutes)

**First-time setup**:
- Xcode may ask to enable Developer Mode on watch
- On watch: Settings → Privacy & Security → Developer Mode → Enable
- Watch will restart

### 5.5 Test on Physical Watch

1. On iPhone, open **Zer0** app
2. On watch, open **Zer0Watch** app
3. Watch should sync inbox from iPhone within 1-2 seconds

**Test actions**:
- Archive email on watch → Verify on iPhone
- Flag email on iPhone → Verify on watch
- Walk away from iPhone → Archive on watch → Walk back → Verify sync

---

## Troubleshooting

### Issue: "WatchConnectivity session not activated"

**Cause**: WCSession initialization failed.

**Fix**:
1. Restart both iPhone and watch apps
2. Verify both apps have WatchConnectivity capability enabled
3. Check Xcode console for detailed error logs

---

### Issue: "Inbox not syncing from iPhone"

**Cause**: WatchConnectivity not paired, or iPhone app not calling `pushInboxUpdate()`.

**Fix**:

1. **Verify pairing**:
   - On iPhone: Settings → Bluetooth → Watch should be connected
   - On watch: Settings → Bluetooth → iPhone should be connected

2. **Verify iOS app integration**:
   - Open `AppDelegate.swift` (iOS)
   - Ensure WatchConnectivityManager is initialized:
     ```swift
     WatchConnectivityManager.shared.inboxDataProvider = {
         // Return inbox data
     }
     WatchConnectivityManager.shared.pushInboxUpdate()
     ```

3. **Force push from iOS**:
   - In iOS app, call `WatchConnectivityManager.shared._testForcePush()`

---

### Issue: "Swipe actions don't work"

**Cause**: Actions are queued (iPhone not reachable) but not retrying.

**Fix**:
1. Check red dot indicator (top-right of watch app) - should be green when iPhone reachable
2. Pull down to refresh inbox (triggers retry of queued actions)
3. Check Xcode console for error logs

---

### Issue: "Build fails with 'Logger not found'"

**Cause**: Logger utility not added to watchOS target.

**Fix**:

**Option A**: Add Logger to watch target
1. Find `Logger.swift` file in iOS project
2. Add to watchOS target (Target Membership)

**Option B**: Remove Logger calls
1. Find/replace in watchOS files:
   - `Logger.info(...)` → `print("INFO: ...")`
   - `Logger.error(...)` → `print("ERROR: ...")`
   - `Logger.debug(...)` → `print("DEBUG: ...")`

---

### Issue: "Watch app crashes on launch"

**Cause**: Missing shared models or initialization error.

**Fix**:
1. Verify `WatchModels.swift` is added to **both** iOS and watchOS targets
2. Check for `#if os(watchOS)` wrapping in watch-only files
3. Review Xcode crash logs (Window → Devices and Simulators → View Device Logs)

---

## Next Steps

### Week 3 (Days 4-7)

After watch app is running:

1. **Add Complications** (Week 3, Day 4)
   - Create `InboxComplicationProvider.swift`
   - Support circular, rectangular, and inline families
   - Show unread count + urgent count

2. **Polish UI** (Week 3, Day 5)
   - Add loading states
   - Add error banners
   - Improve empty inbox view

3. **Test Offline Mode** (Week 3, Day 6)
   - Archive email with iPhone off
   - Wait 1 minute
   - Turn iPhone on
   - Verify action syncs

4. **Measure Performance** (Week 3, Day 7)
   - Inbox sync latency (target: < 5s)
   - Action execution latency (target: < 5s)
   - Battery drain (target: < 5% per hour)

### Week 4 (Polish)

1. Add watch face complications
2. Optimize memory usage (target: < 50 MB)
3. Add unit tests (WatchConnectivityManager)
4. Test on physical watch for full day

---

## Summary

### What You Just Built

- ✅ watchOS app target (Zer0Watch)
- ✅ InboxView with swipe actions
- ✅ EmailDetailView
- ✅ Bidirectional iPhone ↔ Watch sync
- ✅ Offline action queuing

### Key Files Created

| File | Purpose | LOC |
|------|---------|-----|
| `WatchConnectivityManager_watchOS.swift` | Watch-side sync manager | 300 |
| `InboxView.swift` | Email list view | 250 |
| `EmailDetailView.swift` | Email detail view | 150 |
| `Zer0WatchApp.swift` | Watch app entry point | 20 |
| **Total** | | **720 LOC** |

### Testing Checklist

- [ ] Build succeeds (no errors)
- [ ] Watch simulator launches
- [ ] Inbox syncs from iPhone
- [ ] Swipe to archive works
- [ ] Email detail view shows correctly
- [ ] Offline actions queue and retry
- [ ] Physical watch pairing works (if available)

### Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| **Inbox sync time** | < 5 seconds | iPhone → Watch |
| **Action execution** | < 5 seconds | Watch → iPhone → Response |
| **Battery drain** | < 5% per hour | Typical usage |
| **Memory usage** | < 50 MB | Watch app only |
| **App size** | < 10 MB | watchOS bundle |

---

**Status**: ✅ watchOS App Implementation Complete (Code Ready)
**Next**: Add watch target in Xcode, test on simulator/device
**ETA**: 30-45 minutes setup, then ready for Week 4 testing

---

*Glanceable email on your wrist.* ⌚️
