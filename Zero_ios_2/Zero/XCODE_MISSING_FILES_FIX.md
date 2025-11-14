# Xcode Missing Files Fix Guide

## Problem
Build is failing with "cannot find" errors for these files:
1. ~~`ContentViewState`~~ ✅ FIXED - You added this
2. ~~`MockDataLoader`~~ ✅ FIXED - You added this
3. **`MainFeedView`** ⚠️  STILL NEEDED - Used in ContentView.swift

These files exist on disk but weren't properly added to the Xcode project target.

## Solution

### ✅ Step 1: ContentViewState.swift - DONE
You already added this file!

### ✅ Step 2: MockDataLoader.swift - DONE
You already added this file!

### ⚠️  Step 3: Add MainFeedView.swift - REQUIRED
**This is the last missing file!**

1. In Xcode Project Navigator, find `Views/MainFeedView.swift`
2. **If not visible**: Right-click on `Views` folder → "Add Files to Zero..."
3. Navigate to: `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/MainFeedView.swift`
4. ✅ Check "Copy items if needed"
5. ✅ Check "Zero" target
6. Click "Add"

**OR use File Inspector (faster):**
1. Select `Views/MainFeedView.swift` in Project Navigator
2. Open File Inspector (⌘⌥1)
3. Under "Target Membership", check "Zero"

### Step 4: Build
1. **Clean Build Folder**: Product → Clean Build Folder (⌘⇧K)
2. **Build**: Product → Build (⌘B)
3. **Expected**: BUILD SUCCEEDED

## Quick Fix Commands

If files are in the correct location but not in target:
1. Select the file in Project Navigator
2. Open File Inspector (⌘⌥1)
3. Under "Target Membership", check "Zero"

## Verification

After adding files, build should succeed with 0 errors.

All integration files are working:
- ✅ ActionModalCoordinator.swift
- ✅ ContentView+Helpers.swift
- ✅ ContentView+URLHelpers.swift
- ✅ ActionLoader.swift
- ✅ Config/Actions/mail-actions.json (15 actions)

## Already Fixed

We've already fixed these issues in this session:
- ✅ Removed duplicate helper methods from ContentView
- ✅ Added missing DesignTokens.Opacity values (textFaded, textPlaceholder)
- ✅ Removed duplicate Color.init(hex:) from DesignTokens.swift
