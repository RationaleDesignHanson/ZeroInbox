# GO_TO Action Visual Feedback System

**Date:** November 10, 2025
**Scope:** 103 GO_TO actions (61% of all actions)
**Goal:** Consistent, polished feedback without modals

---

## 🎯 Design Philosophy

**GO_TO actions open external content** (Safari, apps, websites). They don't need modals—just clear, consistent visual feedback that:

1. **Indicates it's external** (icon/badge)
2. **Shows press feedback** (instant response)
3. **Displays loading** (brief spinner)
4. **Transitions smoothly** (fade to external app)
5. **Handles return** (resume state)

**Goal:** User always knows what's happening, feels responsive, looks polished.

---

## 📊 The 103 GO_TO Actions

### Categories

**Education & Learning (15 actions):**
- View Assignment, Check Grade, View LMS
- View Results, Submit Assignment
- View Syllabus, View Course Materials

**Medical & Health (8 actions):**
- View Prescription, Schedule Appointment
- Check In Appointment, View Lab Results
- View Medical Records, Refill Prescription

**Legal & Government (12 actions):**
- View Jury Summons, View Tax Notice
- View Voter Info, View Ballot
- Register to Vote, View Court Document
- Pay Property Tax, File Permit

**Shopping & Commerce (18 actions):**
- Shop Now, View Order, View Product
- Track Delivery, Manage Subscription
- Browse Shopping, View Refund Status
- Return Item, Reorder Item

**Travel & Transportation (10 actions):**
- View Itinerary, Get Directions
- Check Flight Status, View Boarding Pass
- View Reservation, Book Travel

**Work & Productivity (15 actions):**
- View Task, View Ticket, View Incident
- Join Meeting, Open Link, Open App
- View Spreadsheet, View Document

**Finance & Payments (8 actions):**
- View Statement, View Invoice
- View Credit Report, View Portfolio
- Check Application Status

**Communication & Social (12 actions):**
- Unsubscribe, View Social Message
- View Post Comments, Reply to Post
- View Referral, View Introduction

**Miscellaneous (5 actions):**
- View Warranty, View Usage
- View Announcement, View Newsletter

---

## 🎨 Component System

### 1. Action Card (with External Indicator)

**Base Action Card:**
```
┌─────────────────────────────────────────┐
│  〇  Title (15px, semibold)         ↗   │
│     Description (12px, gray)            │
│     [Priority Badge]                    │
└─────────────────────────────────────────┘
```

**External Link Indicator:** `↗` (top right)
- Position: Top right corner
- Icon: Arrow pointing up-right (↗)
- Size: 16px
- Color: Gray (60% opacity)
- Meaning: "Opens external content"

**Variants by Priority:**
- 8 priority levels (Critical → Very Low)
- Each has distinct color accent
- External indicator consistent across all

---

### 2. Press State

**Visual Changes on Tap:**

**Before Press (Idle):**
```
┌─────────────────────────────────────────┐
│  〇  Shop Now                       ↗   │
│     Browse products and deals           │
│     [Medium] [Ads]                      │
└─────────────────────────────────────────┘
Opacity: 100%
Background: Default
Scale: 1.0
```

**During Press (Active):**
```
┌─────────────────────────────────────────┐
│  〇  Shop Now                       ↗   │
│     Browse products and deals           │
│     [Medium] [Ads]                      │
└─────────────────────────────────────────┘
Opacity: 80%
Background: Slightly darker (5% overlay)
Scale: 0.98 (subtle shrink)
Duration: 0.1s (instant feedback)
```

**Specifications:**
- **Opacity:** 100% → 80%
- **Scale:** 1.0 → 0.98 (2% shrink)
- **Background:** Add 5% black overlay
- **Duration:** 0.1s (instant, iOS-like)
- **Easing:** `ease-out`

---

### 3. Loading State

**After Press, Before Opening Link:**

```
┌─────────────────────────────────────────┐
│  ⊙  Shop Now                       ↗   │
│     Browse products and deals           │
│     [Medium] [Ads]                      │
└─────────────────────────────────────────┘
```

**Changes:**
- **Icon:** Action icon → Spinner (⊙)
- **Spinner:** 20px, matches icon size
- **Animation:** Rotating 360°, 0.8s duration, infinite
- **Color:** Same as original icon
- **Duration:** Brief (0.3-0.8s typically)

**Loading Spinner Specs:**
- Type: Circular ring (SF Symbols style)
- Size: 20px (matches icon size)
- Stroke: 2px
- Rotation: 360° clockwise
- Speed: 0.8s per rotation
- Color: Matches priority badge color

---

### 4. Transition Animation

**Card → External App:**

**Phase 1: Fade Out (0.2s)**
```
Action Card
Opacity: 100% → 0%
Duration: 0.2s
Easing: ease-in
```

**Phase 2: App Switch (0.1s)**
```
iOS System Transition
- Screen slides left (iOS default)
- External app/Safari opens
- Zero stays in memory
```

**Phase 3: External Content Visible**
```
User is now in:
- Safari (web links)
- Native app (app links)
- System app (maps, calendar)
```

**Total Perceived Duration:** ~0.3s (feels instant)

---

### 5. Return State

**When User Returns to Zero:**

**If action still visible (email still open):**
```
┌─────────────────────────────────────────┐
│  〇  Shop Now                       ↗   │
│     Browse products and deals           │
│     [Medium] [Ads]                      │
└─────────────────────────────────────────┘
State: Idle (ready to tap again)
No visual indication of previous tap
```

**If action was destructive/one-time:**
```
Action may be removed or marked complete
(Depends on action semantics)
```

---

## 🎬 Animation Timeline

### Complete User Flow

```
Frame 1: Idle State (0s)
┌─────────────────────────────────────────┐
│  〇  Get Directions                 ↗   │
│     Open in Maps app                    │
│     [High] [Both]                       │
└─────────────────────────────────────────┘
User taps

Frame 2: Press State (0.1s)
┌─────────────────────────────────────────┐
│  〇  Get Directions                 ↗   │  ← 80% opacity
│     Open in Maps app                    │  ← 0.98 scale
│     [High] [Both]                       │
└─────────────────────────────────────────┘
Finger down

Frame 3: Loading State (0.2s)
┌─────────────────────────────────────────┐
│  ⊙  Get Directions                 ↗   │  ← Spinner
│     Open in Maps app                    │  ← Back to 100%
│     [High] [Both]                       │
└─────────────────────────────────────────┘
Processing link

Frame 4: Fade Out (0.4s)
┌─────────────────────────────────────────┐
│  ⊙  Get Directions                 ↗   │  ← Fading...
│     Open in Maps app                    │
│     [High] [Both]                       │
└─────────────────────────────────────────┘
Opacity: 100% → 0%

Frame 5: External App (0.5s)
╔═══════════════════════════════════════╗
║           MAPS APP                    ║
║                                       ║
║   [Directions to destination]         ║
║                                       ║
║   Start Navigation >                  ║
╚═══════════════════════════════════════╝
iOS transition complete
```

**Total Timeline:** 0.5s from tap to external app visible

---

## 🎨 Figma Components

### Component Structure

```
Components/
  ActionCards/
    _Base/
      ActionCardBase (master)
      ExternalIndicator (↗ icon)
    WithExternalLink/
      ActionCard_External (with ↗)
      States:
        ├─ Idle
        ├─ Pressed
        └─ Loading
    Priorities/
      ├─ Critical (95) + External
      ├─ VeryHigh (90) + External
      ├─ High (85) + External
      ├─ MediumHigh (80) + External
      ├─ Medium (75) + External
      ├─ MediumLow (70) + External
      ├─ Low (65) + External
      └─ VeryLow (60) + External
```

### Build Order

**1. External Indicator Icon (5 min)**
- Create ↗ icon component
- Size: 16px
- Color: Gray (60% opacity)
- Style: Consistent with SF Symbols

**2. Action Card States (30 min)**
- Base: ActionCard master component
- Add: Idle, Pressed, Loading variants
- Configure auto-layout for responsive behavior

**3. Loading Spinner (15 min)**
- Create rotating spinner component
- Match icon size (20px)
- Animation: 360° rotation, 0.8s, infinite

**4. Priority Variants (1 hour)**
- Create 8 priority + external variants
- Apply color system to each
- Test with real action examples

**Total Build Time:** ~2 hours for complete GO_TO feedback system

---

## 📐 Specifications

### Visual Hierarchy

**External Indicator (↗):**
- **Size:** 16px × 16px
- **Position:** Top right, 12px from edge
- **Color:** Gray-500 (rgb(142, 142, 147), 60% opacity)
- **Style:** Stroke 1.5px, rounded corners
- **z-index:** Above card content

**Loading Spinner:**
- **Size:** 20px × 20px (matches icon)
- **Position:** Replaces action icon
- **Stroke:** 2px
- **Color:** Inherits from priority badge
- **Animation:**
  - Rotation: 0° → 360°
  - Duration: 0.8s
  - Timing: `linear`
  - Iteration: `infinite`

### Animation Specs

**Press State:**
```css
.action-card:active {
  opacity: 0.8;
  transform: scale(0.98);
  background: rgba(0, 0, 0, 0.05);
  transition: all 0.1s ease-out;
}
```

**Loading State:**
```css
.action-card.loading .icon {
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

**Fade Out:**
```css
.action-card.transitioning {
  opacity: 0;
  transition: opacity 0.2s ease-in;
}
```

### Color System

**External Indicator (↗) by Theme:**
- **Light Mode:** Gray-500, 60% opacity
- **Dark Mode:** Gray-400, 60% opacity
- Always subtle, never distracting

**Loading Spinner Colors by Priority:**
- **Critical (95):** Red (#FF3B30)
- **VeryHigh (90):** Orange (#FF9500)
- **High (85):** Yellow (#FFCC00)
- **MediumHigh (80):** Green (#34C759)
- **Medium (75):** Cyan (#32D4E8)
- **MediumLow (70):** Blue (#007AFF)
- **Low (65):** Purple (#AF52DE)
- **VeryLow (60):** Gray (#8E8E93)

---

## 📱 Responsive Behavior

### On Different Devices

**iPhone (Standard):**
- Card height: 80px
- External indicator: 16px, 12px from edge
- Touch target: Full card (min 44px height)

**iPhone Pro Max (Large):**
- Card height: 88px
- External indicator: 18px, 14px from edge
- Slightly larger for readability

**iPad:**
- Card height: 96px
- External indicator: 20px, 16px from edge
- More spacious layout

### Accessibility

**VoiceOver Support:**
```
Announce: "[Action Name], external link button"
Example: "Shop Now, external link button"
```

**Haptic Feedback:**
- **On Press:** Light impact (`UIImpactFeedbackGenerator.light`)
- **On Open:** Medium impact (optional)
- Feels tactile and responsive

**Reduced Motion:**
- If user has reduced motion enabled:
  - Skip scale animation (0.98)
  - Skip fade animation
  - Show instant transition
  - Keep spinner (functional, not decorative)

---

## 🎭 Context-Specific Variants

### Shopping Actions (18 actions)
**Examples:** Shop Now, View Order, View Product

**Enhancement:**
- External indicator: Shopping bag icon (optional)
- Use Ads gradient on press (subtle)
- Priority typically Medium-High

### Navigation Actions (10 actions)
**Examples:** Get Directions, View Itinerary

**Enhancement:**
- External indicator: Arrow + compass icon
- Hint: "Opens Maps" or "Opens [app name]"
- Priority typically High (time-sensitive)

### Document/View Actions (40 actions)
**Examples:** View Assignment, View Invoice, View Document

**Enhancement:**
- External indicator: Document icon + ↗
- Hint: "Opens in browser" or "Opens PDF"
- Priority varies widely

### Utility Actions (15 actions)
**Examples:** Unsubscribe, Open Link, Join Meeting

**Enhancement:**
- Standard ↗ indicator
- Context badge shows destination ("Link", "Meeting", etc.)
- Priority typically Low-Medium

---

## 🧪 Testing Scenarios

### User Flow Tests

**1. Tap External Link**
```
Given: User sees action card with ↗ indicator
When: User taps the card
Then:
  - Card shows press state (0.1s)
  - Loading spinner appears (0.2s)
  - Card fades out (0.2s)
  - External app/Safari opens (0.1s)
  - Total: ~0.5s smooth transition
```

**2. Rapid Taps (Double Tap Prevention)**
```
Given: User taps action card
When: User taps again immediately
Then:
  - Second tap ignored while loading
  - Prevents double-opening
  - Loading spinner indicates "processing"
```

**3. Return to App**
```
Given: User is in external app
When: User swipes back to Zero (iOS gesture)
Then:
  - Zero resumes from previous state
  - Action card back to Idle state
  - Ready to tap again if needed
```

**4. Network Error**
```
Given: User taps action card
When: Link fails to open (no internet, broken URL)
Then:
  - Loading spinner stops
  - Error toast appears at bottom
  - Message: "Couldn't open link"
  - Action: "Try Again" button
  - Card returns to Idle state
```

**5. App Not Installed**
```
Given: Action requires specific app (e.g., Maps)
When: App not installed on device
Then:
  - iOS prompts: "Open in Safari?" or "Install app?"
  - Zero stays visible during prompt
  - User can cancel and return
```

---

## 📊 Performance Considerations

### Optimization Targets

**Press Feedback:** < 16ms (single frame)
- Must feel instant
- No perceptible lag
- Use CSS transform (GPU accelerated)

**Loading Display:** < 100ms
- Spinner appears quickly
- User knows action is processing
- Brief enough not to annoy

**Transition to External:** < 500ms total
- From tap to external app visible
- Smooth, polished, professional
- Matches iOS system transitions

### Implementation Notes

**For Developers:**

```swift
// Swift/iOS Implementation
func handleExternalAction(_ action: ActionConfig) {
    // 1. Press feedback (instant)
    cardView.animatePress() // 0.1s

    // 2. Show loading
    cardView.showSpinner() // 0.2s

    // 3. Open URL
    guard let url = action.url else {
        showError("Invalid link")
        return
    }

    // 4. Fade and open
    UIView.animate(withDuration: 0.2) {
        cardView.alpha = 0
    } completion: { _ in
        UIApplication.shared.open(url) // iOS handles transition
    }
}
```

```javascript
// React/Web Implementation
const handleExternalAction = async (action) => {
  // 1. Press feedback
  setPressed(true);
  await delay(100);

  // 2. Loading state
  setPressed(false);
  setLoading(true);

  // 3. Brief delay for spinner visibility
  await delay(200);

  // 4. Open link (in new tab)
  window.open(action.url, '_blank');

  // 5. Reset state
  setLoading(false);
};
```

---

## 🎨 Figma Implementation Guide

### Week 1: Build Components

**Day 1 (2 hours):**

**Step 1: External Indicator Icon (30 min)**
1. Create frame 16×16px
2. Draw arrow pointing up-right (↗)
3. Style: 1.5px stroke, rounded caps
4. Color: Gray (#8E8E93), 60% opacity
5. Create component: `Icon/External`

**Step 2: Action Card with External (1 hour)**
1. Duplicate existing ActionCard
2. Add External indicator to top right
3. Position: 12px from right edge
4. Create component: `ActionCard/External`

**Step 3: States (30 min)**
1. Create variants:
   - `State: Idle` (default)
   - `State: Pressed` (80% opacity, 0.98 scale)
   - `State: Loading` (spinner icon)
2. Configure interactive component
3. Set transitions: 0.1s for press, 0.2s for loading

**Deliverable:** ActionCard with external link support

---

**Day 2 (2 hours):**

**Step 4: Loading Spinner (1 hour)**
1. Create circular ring 20×20px
2. Stroke: 2px, gap on one side
3. Create rotation animation prototype
4. Create component: `Icon/Spinner`
5. Add to Loading state

**Step 5: Priority Variants (1 hour)**
1. Create 8 priority variants of ActionCard/External
2. Apply color system to spinner
3. Test with real action examples:
   - Critical: "View Jury Summons"
   - High: "Get Directions"
   - Medium: "Shop Now"
   - Low: "View Newsletter"

**Deliverable:** Complete GO_TO visual feedback system

---

### Week 2: Integration

**Apply to All 103 GO_TO Actions:**
1. List all GO_TO actions
2. Assign appropriate priority
3. Apply ActionCard/External component
4. Configure transition behaviors

**Create Examples:**
- Shopping flow (Shop Now → Safari)
- Navigation flow (Get Directions → Maps)
- Document flow (View Assignment → LMS website)

---

## ✅ Success Criteria

**For Each GO_TO Action:**
- [ ] External indicator (↗) visible
- [ ] Press state feels responsive (< 16ms)
- [ ] Loading spinner appears briefly (0.2-0.8s)
- [ ] Smooth fade to external app (0.2s)
- [ ] Returns to idle state when user comes back
- [ ] Accessible (VoiceOver, Haptics)
- [ ] Works on iPhone and iPad
- [ ] Respects reduced motion preference

**System-Wide:**
- [ ] All 103 GO_TO actions use same pattern
- [ ] Consistent timing and animations
- [ ] Clear distinction from IN_APP actions (modals)
- [ ] Professional, polished feel
- [ ] No jank or lag

---

## 📚 Examples

### High-Priority External Action

**Get Directions:**
```
┌─────────────────────────────────────────┐
│  📍  Get Directions                ↗   │
│     Open in Maps app                    │
│     [High - 85] [Both]                  │
└─────────────────────────────────────────┘

States:
1. Idle: 100% opacity, location icon
2. Pressed: 80% opacity, 0.98 scale
3. Loading: Spinner (yellow), 0.3s
4. Transition: Fade out → Maps app opens
5. Return: Back to Idle

Total Time: ~0.5s tap to Maps visible
```

---

### Medium-Priority External Action

**Shop Now:**
```
┌─────────────────────────────────────────┐
│  🛍️  Shop Now                      ↗   │
│     Browse products and deals           │
│     [Medium - 75] [Ads]                 │
└─────────────────────────────────────────┘

States:
1. Idle: 100% opacity, shopping bag icon
2. Pressed: 80% opacity, 0.98 scale
3. Loading: Spinner (cyan), 0.3s
4. Transition: Fade out → Safari opens
5. Return: Back to Idle

Total Time: ~0.5s tap to website visible
```

---

### Low-Priority External Action

**View Newsletter:**
```
┌─────────────────────────────────────────┐
│  📰  View Newsletter               ↗   │
│     Read full newsletter online         │
│     [Low - 65] [Both]                   │
└─────────────────────────────────────────┘

States:
1. Idle: 100% opacity, newsletter icon
2. Pressed: 80% opacity, 0.98 scale
3. Loading: Spinner (purple), 0.3s
4. Transition: Fade out → Safari opens
5. Return: Back to Idle

Total Time: ~0.5s tap to article visible
```

---

## 🎊 Summary

**Visual Feedback System for 103 GO_TO Actions:**

✅ **Components Built:**
- External indicator icon (↗)
- Action card with 3 states (Idle, Pressed, Loading)
- Loading spinner (8 priority colors)
- 8 priority variants

✅ **Animations Defined:**
- Press: 0.1s, 80% opacity, 0.98 scale
- Loading: 0.2-0.8s, rotating spinner
- Transition: 0.2s fade out
- Total: ~0.5s tap to external app

✅ **Benefits:**
- Consistent across 103 actions
- No modals needed (61% of actions!)
- Clear, professional, polished
- Fast and responsive
- Accessible

✅ **Build Time:**
- Components: 2 hours
- Integration: Ongoing as needed
- Maintenance: Minimal (reusable system)

**The GO_TO visual feedback system is complete and ready to build! 🚀**

---

**Next Steps:**
1. Build external indicator icon (30 min)
2. Create action card states (1 hour)
3. Add loading spinner (30 min)
4. Apply to all 103 GO_TO actions

**Start with Figma Build Guide, then implement this GO_TO system for immediate impact.**
