# Figma Sync Execution Guide

**Status**: Ready to Execute
**Time Required**: 15-30 minutes
**Difficulty**: Easy

---

## Quick Start (3 Options)

### Option 1: Figma Plugin (Recommended - Most Automated)

```bash
# 1. Prepare sync data
cd design-system/sync
FIGMA_ACCESS_TOKEN=your_token_here node sync-to-figma.js

# 2. Load plugin in Figma Desktop App
# File → Plugins → Development → Import Plugin from Manifest
# Select: design-system/figma-plugin/manifest-sync.json

# 3. Run plugin
# Open file: https://figma.com/file/WuQicPi1wbHXqEcYCQcLfr
# Plugins → Development → Zero Design Sync
# Click "⚡ Sync All Phases"

# Done!
```

### Option 2: Automated Script (Semi-Automated)

```bash
# Run sync preparation script
cd design-system/sync
FIGMA_ACCESS_TOKEN=your_token_here node sync-to-figma.js

# Follow manual steps shown in output
```

### Option 3: Manual Sync (Full Control)

Follow the detailed instructions in `FIGMA_SYNC_PLAN.md`

---

## Option 1: Figma Plugin (Detailed Instructions)

### Step 1: Get Your Figma Access Token

1. Go to https://figma.com/developers/api#access-tokens
2. Click "Get personal access token"
3. Copy the token (starts with `figd_...`)
4. Set environment variable:

```bash
export FIGMA_ACCESS_TOKEN="figd_your_token_here"
```

### Step 2: Prepare Sync Data

```bash
# Navigate to sync directory
cd design-system/sync

# Run sync preparation
node sync-to-figma.js
```

**Expected Output:**
```
╔══════════════════════════════════════════════════╗
║  Figma Design Token Sync                         ║
║  iOS Tokens → Figma Variables                    ║
╚══════════════════════════════════════════════════╝

📊 Analyzing tokens...

Found 27 variables to sync:

  Breakdown:
    - FLOAT: 18 variables
    - COLOR: 4 variables

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 Phase 1: Critical Fixes

  ✅ Ads Gradient Colors:
     Start: RGB(22, 187, 170) = #16BBAA
     End:   RGB(79, 209, 158) = #4FD19E

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Variable list exported to: figma-variables.json

🔍 Fetching Figma file info...

  ✅ File: Zero Inbox Design System
     Last modified: Nov 13, 2025
     Version: 42

  ✅ Found "Design System" page
     Ready for variable sync

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Sync preparation complete!
```

### Step 3: Install Plugin in Figma

**On Mac:**
1. Open Figma Desktop App (download from https://figma.com/downloads)
2. Open any file (or create a new one)
3. Go to: Menu → Plugins → Development → Import plugin from manifest...
4. Navigate to: `design-system/figma-plugin/`
5. Select: `manifest-sync.json`
6. Click "Open"

**Plugin Installed!** You'll see "Zero Design Sync" in your Development plugins

### Step 4: Open Your Figma File

```bash
# Open in browser (or use desktop app)
open https://figma.com/file/WuQicPi1wbHXqEcYCQcLfr
```

### Step 5: Run the Plugin

1. In Figma, go to: **Plugins → Development → Zero Design Sync**
2. Plugin window appears with 6 phases
3. Click **"⚡ Sync All Phases"** button
4. Wait for completion (10-15 seconds)
5. See success notification: "✅ Sync complete!"

**What Gets Created:**

✅ **Color Styles:**
- `Archetype/Mail/Gradient Start` (#667eea)
- `Archetype/Mail/Gradient End` (#764ba2)
- `Archetype/Ads/Gradient Start` (#16bbaa) ← **FIXED!**
- `Archetype/Ads/Gradient End` (#4fd19e) ← **FIXED!**

✅ **Text Styles:**
- `Card/CardTitle` (19px, Bold)
- `Card/CardSummary` (15px, Regular)
- `Card/CardSectionHeader` (15px, Bold)
- `Card/ThreadTitle` (14px, Semibold)
- `Card/ThreadSummary` (16px, Regular)
- `Card/ThreadMessageSender` (13px, Bold)
- `Card/ThreadMessageBody` (13px, Regular)

✅ **Effect Styles (Shadows):**
- `Shadow/Card` (blur 20, y:10, opacity 40%)
- `Shadow/Button` (blur 10, y:5, opacity 20%)
- `Shadow/Subtle` (blur 8, y:2, opacity 10%)

✅ **Documentation:**
- Spacing values (8 tokens)
- Radius values (7 tokens)
- Opacity values (10 levels)

### Step 6: Verify Sync

1. Check **Local Styles** panel in Figma:
   - Colors → Should see "Archetype" folder
   - Text → Should see "Card" folder
   - Effects → Should see "Shadow" folder

2. **Test the Ads Gradient:**
   - Create a rectangle
   - Apply gradient fill
   - Add color stops with:
     - Start: `Archetype/Ads/Gradient Start`
     - End: `Archetype/Ads/Gradient End`
   - Should see teal (#16BBAA) → green (#4FD19E)

3. **Test Typography:**
   - Create a text layer
   - Apply text style: `Card/CardTitle`
   - Should be 19px Bold

---

## Option 2: Automated Script

### Step 1: Run Sync Script

```bash
cd design-system/sync
FIGMA_ACCESS_TOKEN=your_token_here node sync-to-figma.js
```

### Step 2: Follow Output Instructions

The script will:
1. ✅ Analyze iOS tokens (27 variables)
2. ✅ Validate Figma file access
3. ✅ Export variable list to `figma-variables.json`
4. ℹ️ Show you what needs to be done manually

### Step 3: Manual Steps

Based on script output:
1. Open Figma file
2. Create color styles manually
3. Create text styles manually
4. Create effect styles manually
5. Document spacing/radius/opacity values

---

## Option 3: Full Manual Sync

Follow the comprehensive guide in `FIGMA_SYNC_PLAN.md`:
- Phase 1: Color fixes (15 min)
- Phase 2: Typography (20 min)
- Phase 3: Spacing variables (10 min)
- Phase 4: Radius variables (10 min)
- Phase 5: Opacity variables (10 min)
- Phase 6: Shadow effects (10 min)

**Total: ~75 minutes**

---

## Verification Checklist

After sync, verify these items:

### Phase 1: Colors ✓
- [ ] Mail gradient start is #667eea
- [ ] Mail gradient end is #764ba2
- [ ] **Ads gradient start is #16BBAA** (was wrong before!)
- [ ] **Ads gradient end is #4FD19E** (was wrong before!)

### Phase 2: Typography ✓
- [ ] Card Title is 19px Bold
- [ ] Card Summary is 15px Regular
- [ ] Card Section Header is 15px Bold
- [ ] Thread styles are present (4 styles)

### Phase 3: Spacing ✓
- [ ] Card spacing is 24px
- [ ] Component spacing is 16px
- [ ] Minimal spacing is 4px

### Phase 4: Radius ✓
- [ ] Card radius is 16px
- [ ] Button radius is 12px
- [ ] Chip radius is 8px

### Phase 5: Opacity ✓
- [ ] Text primary is 1.0
- [ ] Text disabled is 0.6
- [ ] Glass ultra-light is 0.05

### Phase 6: Shadows ✓
- [ ] Card shadow: blur 20, y:10, opacity 40%
- [ ] Button shadow: blur 10, y:5, opacity 20%
- [ ] Subtle shadow: blur 8, y:2, opacity 10%

---

## Troubleshooting

### Plugin Won't Load

**Problem:** "Failed to load plugin"

**Solutions:**
1. Check manifest-sync.json is valid JSON
2. Ensure sync-plugin.js exists (run `npm run build:sync`)
3. Restart Figma Desktop App
4. Try importing manifest again

### Styles Not Appearing

**Problem:** Created styles don't show in Figma

**Solutions:**
1. Check you're on correct page (not a temporary file)
2. Refresh Figma (Cmd+R / Ctrl+R)
3. Check Local Styles panel (not Team Styles)
4. Run plugin again (it's safe to re-run)

### Wrong Colors

**Problem:** Ads gradient is wrong color

**Solutions:**
1. Check iOS tokens are correct in `design-system/tokens.json`
2. Re-run sync-to-figma.js
3. Re-run plugin (will update existing styles)
4. Manually verify hex values:
   - Start: #16BBAA (not #10b981)
   - End: #4FD19E (not #34ecb3)

### Access Token Error

**Problem:** "FIGMA_ACCESS_TOKEN not set"

**Solutions:**
1. Get token from https://figma.com/developers/api#access-tokens
2. Export in terminal: `export FIGMA_ACCESS_TOKEN="figd_..."`
3. Verify: `echo $FIGMA_ACCESS_TOKEN`
4. Run script again

---

## What's Next?

After successful sync:

1. **Update Components**
   - Apply new styles to existing components
   - Test gradient cards with fixed ads colors
   - Verify typography in card layouts

2. **Share with Team**
   - Publish styles to team library (if applicable)
   - Document new style names in team wiki
   - Train designers on token usage

3. **Maintain Sync**
   - When iOS tokens change, re-run sync
   - Keep Figma variables in sync with code
   - Document any Figma-specific adjustments

4. **Expand Coverage**
   - Add more component variants
   - Create dark mode styles (future)
   - Add animation documentation

---

## Success Metrics

- [ ] All 6 phases completed
- [ ] 4 color styles created
- [ ] 7 text styles created
- [ ] 3 effect styles created
- [ ] **Ads gradient colors corrected**
- [ ] Components using new styles
- [ ] Team trained on new system
- [ ] Documentation updated

---

## Support

**Issues?**
- Check: `design-system/FIGMA_SYNC_PLAN.md`
- Review: iOS tokens in `design-system/tokens.json`
- Inspect: Generated variables in `design-system/sync/figma-variables.json`

**Need Help?**
- Re-run sync script: Always safe to run again
- Rebuild plugin: `npm run build:sync`
- Check plugin logs: Open Console in Figma (Cmd+Option+I)

---

## Quick Reference

**Files:**
- Sync script: `design-system/sync/sync-to-figma.js`
- Plugin: `design-system/figma-plugin/sync-plugin.js`
- UI: `design-system/figma-plugin/sync-ui.html`
- Manifest: `design-system/figma-plugin/manifest-sync.json`
- iOS tokens: `design-system/tokens.json`

**Commands:**
```bash
# Prepare sync
FIGMA_ACCESS_TOKEN=xxx node design-system/sync/sync-to-figma.js

# Build plugin
cd design-system/figma-plugin
npm run build:sync

# View file
open https://figma.com/file/WuQicPi1wbHXqEcYCQcLfr
```

**Critical Fix:**
- Ads Gradient Start: `#16BBAA` (was #10b981)
- Ads Gradient End: `#4FD19E` (was #34ecb3)
