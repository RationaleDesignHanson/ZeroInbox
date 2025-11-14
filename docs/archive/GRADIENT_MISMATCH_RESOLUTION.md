# Gradient Color Mismatch - Resolution

**Date:** November 10, 2025
**Decision:** Use iOS gradients as source of truth

---

## 🎨 Problem

Your iOS app and Figma file use different gradient colors for archetypes:

### iOS (Current Implementation)
```swift
// Mail Archetype
mailGradientStart = #667eea  // Blue
mailGradientEnd = #764ba2    // Purple

// Ads Archetype
adsGradientStart = #16bbaa   // Teal
adsGradientEnd = #4fd19e     // Green
```

### Figma (Current Design)
```
// Mail Archetype
Start: #3b82f6  // Blue
End: #0ea5e9    // Cyan

// Ads Archetype
Start: #10b981  // Green
End: #34ecb3    // Emerald
```

---

## ✅ Decision: Use iOS Colors

**Rationale:**
1. iOS app is live/implemented - these are the colors users see
2. iOS colors have been tested and validated
3. Comment in iOS code says "matching web demo"
4. Safer to update Figma than change deployed code

---

## 🎨 Canonical Gradient Colors

### Mail Archetype (Blue → Purple)
```
Start: #667eea  // rgb(102, 126, 234) - Soft Blue
End:   #764ba2  // rgb(118, 75, 162) - Deep Purple

Gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
```

**Use cases:**
- Mail actions
- Email-related features
- Primary archetype
- Inbox views

### Ads Archetype (Teal → Green)
```
Start: #16bbaa  // rgb(22, 187, 170) - Bright Teal
End:   #4fd19e  // rgb(79, 209, 158) - Mint Green

Gradient: linear-gradient(135deg, #16bbaa 0%, #4fd19e 100%)
```

**Use cases:**
- Ad-related content
- Marketing emails
- Secondary archetype
- Ad filtering features

---

## 📋 Action Items

### Update Figma File

1. **Navigate to:** Design System Components → 🎨 Archetypes

2. **Update Mail Gradient:**
   - Change Start color: #3b82f6 → **#667eea**
   - Change End color: #0ea5e9 → **#764ba2**
   - Update gradient swatch to show blue → purple

3. **Update Ads Gradient:**
   - Change Start color: #10b981 → **#16bbaa**
   - Change End color: #34ecb3 → **#4fd19e**
   - Update gradient swatch to show teal → green

4. **Apply to Components:**
   - Update any button components using these gradients
   - Update action card examples
   - Update email view examples

### Re-run Token Sync

After updating Figma:

```bash
cd design-system/sync
node sync-all.js
```

This will export the corrected gradients to:
- `design-tokens.json`
- `DesignTokens.swift`
- `design-tokens.css`
- `design-tokens.js`

---

## 🎨 Visual Reference

### Mail Gradient (Blue → Purple)
```
┌────────────────────────────────────┐
│ #667eea ──────────────→ #764ba2   │
│ Soft Blue              Deep Purple │
└────────────────────────────────────┘
```

**Color breakdown:**
- **Start (#667eea):** Calming blue, professional, trustworthy
- **End (#764ba2):** Rich purple, sophisticated, premium
- **Transition:** 135° diagonal creates dynamic movement

### Ads Gradient (Teal → Green)
```
┌────────────────────────────────────┐
│ #16bbaa ──────────────→ #4fd19e   │
│ Bright Teal            Mint Green  │
└────────────────────────────────────┘
```

**Color breakdown:**
- **Start (#16bbaa):** Vibrant teal, energetic, attention-grabbing
- **End (#4fd19e):** Fresh green, growth, positive action
- **Transition:** 135° diagonal creates vibrant energy

---

## 🔄 Impact Analysis

### What Changes
- ✅ Figma gradient swatches
- ✅ Figma component examples
- ✅ Generated CSS/JS tokens
- ✅ Documentation

### What Stays The Same
- ✅ iOS app code (already correct)
- ✅ iOS DesignTokens.swift (already correct)
- ✅ User experience (no visual changes)

---

## 📚 Additional Gradient Opportunities

While we're standardizing gradients, consider defining additional archetype gradients:

### Personal (Purple → Pink)
```
Start: #a855f7  // Vibrant Purple
End:   #ec4899  // Hot Pink
```

### Shop (Green → Emerald)
```
Start: #10b981  // Green
End:   #34ecb3  // Emerald
```

### Urgent (Orange → Yellow)
```
Start: #f97316  // Orange
End:   #fbbf24  // Yellow
```

These are already defined in iOS (`ColorExtensions.swift`) as vibrant colors and used in `GradientButtonStyle.swift`.

---

## ✅ Verification Steps

After updating Figma and re-running sync:

1. **Check design-tokens.json:**
   ```json
   {
     "gradients": {
       "mail": {
         "start": "#667eea",
         "end": "#764ba2"
       },
       "ads": {
         "start": "#16bbaa",
         "end": "#4fd19e"
       }
     }
   }
   ```

2. **Check design-tokens.css:**
   ```css
   --gradient-mail-start: #667eea;
   --gradient-mail-end: #764ba2;
   --gradient-mail: linear-gradient(135deg, #667eea, #764ba2);
   ```

3. **Visual check:** Mail gradient should be blue→purple, Ads should be teal→green

---

## 📝 Implementation Checklist

- [ ] Update Figma Mail gradient: #667eea → #764ba2
- [ ] Update Figma Ads gradient: #16bbaa → #4fd19e
- [ ] Apply to all Figma components
- [ ] Re-run `node sync-all.js`
- [ ] Verify design-tokens.json
- [ ] Verify design-tokens.css
- [ ] Verify design-tokens.js
- [ ] Test Web implementation with new gradients
- [ ] Update design system documentation
- [ ] Consider adding additional archetype gradients

---

**Status:** ✅ Decision Made - Ready to Implement in Figma
