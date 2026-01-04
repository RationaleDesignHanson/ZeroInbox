# AR Display Architecture
## Zer0 Inbox - Monocular Display for Meta Oakley/Orion Smart Glasses

**Version**: 1.0
**Status**: Foundation Phase (Week 1-2)
**Target Hardware**: Meta Oakley (future), Meta Orion (future)
**Development Fallback**: ARKit + iPhone/iPad
**Author**: Claude Code (Wearables Expert Agent)
**Date**: 2025-12-12

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [AR Display Technology Overview](#ar-display-technology-overview)
3. [Meta Oakley/Orion Specifications](#meta-oakleyorion-specifications)
4. [Design Principles](#design-principles)
5. [Display Zones & Layout System](#display-zones--layout-system)
6. [Email Notification Overlay](#email-notification-overlay)
7. [Persistent Inbox Count Widget](#persistent-inbox-count-widget)
8. [Text Rendering & Sizing](#text-rendering--sizing)
9. [High-Contrast UI for Outdoor Use](#high-contrast-ui-for-outdoor-use)
10. [Display Lifecycle Management](#display-lifecycle-management)
11. [Animation & Transitions](#animation--transitions)
12. [Integration with Voice Navigation](#integration-with-voice-navigation)
13. [Integration with MetaGlassesAdapter](#integration-with-metaglassesadapter)
14. [ARKit Fallback for Development](#arkit-fallback-for-development)
15. [Rendering Pipeline](#rendering-pipeline)
16. [Performance Targets](#performance-targets)
17. [Battery Optimization](#battery-optimization)
18. [Error Handling & Recovery](#error-handling--recovery)
19. [Testing Strategy](#testing-strategy)
20. [Implementation Phases](#implementation-phases)
21. [Code Structure](#code-structure)
22. [Production Integration](#production-integration)

---

## Executive Summary

### What is This?

This document defines the complete architecture for **AR Display** functionality in Zer0 Inbox, enabling:

- **Glanceable email notifications** overlaid in the user's field of view (monocular waveguide display)
- **Persistent inbox count widget** showing unread/urgent email counts at a glance
- **Visual confirmations** for voice commands (archive, flag, delete)
- **High-contrast UI** optimized for outdoor sunlight readability
- **Battery-conscious rendering** with automatic display sleep/wake

### Target Hardware

**Primary**: Meta Oakley (sunglasses with AR display) / Meta Orion (future AR glasses)
**Development**: ARKit on iPhone/iPad for prototyping and testing
**Fallback**: iPhone notifications if AR hardware unavailable

### Key Specifications

| Specification | Value | Notes |
|---------------|-------|-------|
| **Display Type** | Monocular waveguide | Right eye only |
| **Field of View** | ~45° diagonal | Meta Orion estimate |
| **Resolution** | 1280x720 (estimated) | Effective resolution |
| **Eye Relief** | 12-15mm | Distance from eye to display |
| **Focal Distance** | 1-2 meters | Virtual content appears 1-2m away |
| **Brightness** | 2000+ nits | Sunlight-readable |
| **Refresh Rate** | 60 Hz (minimum) | 90 Hz preferred |
| **Color Depth** | 8-bit RGB | ~16.7 million colors |
| **Transparency** | 70-90% | See-through waveguide |

### Design Philosophy

**Glanceable, not intrusive.**

- Email notifications appear for **5 seconds**, then fade
- Inbox widget is **persistent but minimal** (top-right corner)
- High-contrast, large text for instant readability
- Avoid occlusion of real-world view
- Battery-conscious: Display sleeps when not needed

### Architecture at a Glance

```
┌─────────────────────────────────────────────────────────┐
│                    Zer0 iOS App                         │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │          VoiceNavigationService                    │ │
│  │  "Archive this" → executeAction() → sendVisual()  │ │
│  └────────────────┬──────────────────────────────────┘ │
│                   │                                     │
│  ┌────────────────▼──────────────────────────────────┐ │
│  │           ARDisplayService                        │ │
│  │  - showEmailNotification()                        │ │
│  │  - showInboxCountWidget()                         │ │
│  │  - showActionConfirmation()                       │ │
│  │  - dismissAll()                                   │ │
│  └────────────────┬──────────────────────────────────┘ │
│                   │                                     │
│  ┌────────────────▼──────────────────────────────────┐ │
│  │        MetaGlassesAdapter                         │ │
│  │  - renderToDisplay()                              │ │
│  │  - updateDisplayBrightness()                      │ │
│  │  - sleepDisplay() / wakeDisplay()                 │ │
│  └────────────────┬──────────────────────────────────┘ │
│                   │                                     │
└───────────────────┼─────────────────────────────────────┘
                    │
                    │ Meta SDK / Bluetooth LE
                    │
┌───────────────────▼─────────────────────────────────────┐
│            Meta Oakley/Orion Glasses                    │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │         Waveguide Display (Right Eye)             │ │
│  │  ┌──────────────────────────────────────────┐    │ │
│  │  │  [Inbox: 12 unread]  ← Persistent widget │    │ │
│  │  │                                           │    │ │
│  │  │                                           │    │ │
│  │  │      ┌──────────────────────────┐        │    │ │
│  │  │      │  New Email from Boss     │←Overlay│    │ │
│  │  │      │  Subject: Q4 Report      │ 5 sec  │    │ │
│  │  │      │  Priority: High          │        │    │ │
│  │  │      └──────────────────────────┘        │    │ │
│  │  │                                           │    │ │
│  │  └───────────────────────────────────────────┘    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### What's Different from Other Platforms?

| Feature | Apple Watch | Voice-First | AR Display |
|---------|-------------|-------------|------------|
| **Interaction** | Touch, taps, swipes | Voice commands | Visual overlays |
| **Attention** | Requires wrist raise | Requires speaking | Glanceable (no action) |
| **Content** | Full inbox list | Audio narration | Key info only |
| **Battery** | ~5% per hour | ~10% per hour | ~15% per hour (display on) |
| **Privacy** | Private (screen) | Public (voice audible) | Semi-private (only wearer sees) |
| **Context** | Active use | Active use | Passive awareness |

AR Display is for **passive awareness**: "Do I need to check my inbox right now?" without taking action.

---

## AR Display Technology Overview

### What is a Waveguide Display?

A **waveguide display** uses optical waveguides to project images onto a transparent surface (glasses lens). Light from a micro-projector is coupled into the waveguide, travels through internal reflection, and is out-coupled toward the user's eye.

**Key Properties**:
- **See-through**: Real world is visible behind virtual content (70-90% transparency)
- **Monocular**: Typically only one eye (right eye for Meta Oakley/Orion)
- **Fixed focal distance**: Virtual content appears at a fixed distance (1-2 meters), not true depth
- **High brightness**: 2000+ nits for outdoor sunlight readability
- **Low weight**: No bulky optics, integrates into sunglasses frame

### How Meta Oakley/Orion Differ from Current Ray-Ban Meta

| Feature | Ray-Ban Meta (Current) | Meta Oakley/Orion (Future) |
|---------|------------------------|----------------------------|
| **Display** | None (audio only) | Monocular waveguide (right eye) |
| **Audio** | Open-ear speakers | Open-ear speakers |
| **Camera** | 12MP photo/video | 12MP + depth sensor |
| **Microphone** | 5-mic array | 5-mic array + bone conduction |
| **Battery** | 4 hours active | 2-3 hours (display drains faster) |
| **Weight** | ~50g | ~65g (display adds weight) |
| **Price** | $299 | $500-800 (estimated) |

**Important**: Current Ray-Ban Meta glasses do NOT have a display. AR display features will only work on future Meta Oakley/Orion hardware.

### Rendering Constraints

Unlike phone/watch screens, AR displays have unique constraints:

1. **Limited FOV**: Only ~45° diagonal (about the size of a credit card held at arm's length)
2. **Fixed focal distance**: Content appears at 1-2 meters (can't focus on foreground vs background)
3. **Monocular (no depth)**: Only one eye sees the display, so no true 3D depth perception
4. **Sunlight competition**: Display must be bright enough to compete with outdoor sunlight
5. **Minimal occlusion**: Must not block real-world view (safety critical for walking, driving)
6. **Battery drain**: Display consumes significant power (~15% per hour vs ~5% for watch)

---

## Meta Oakley/Orion Specifications

### Official Specs (Meta Orion Prototype)

Based on Meta's public demonstrations and leaked specs:

| Specification | Value | Notes |
|---------------|-------|-------|
| **Display Type** | Silicon carbide waveguide | Next-gen material |
| **Field of View** | 70° diagonal (prototype) | Largest AR FOV to date |
| **Resolution** | 1280x720 effective | Perceived resolution |
| **Brightness** | 2000+ nits | Outdoor-readable |
| **Refresh Rate** | 60-90 Hz | Variable |
| **Transparency** | 80% average | Varies by brightness |
| **Eye Box** | 10mm x 8mm | Area where eye can see display |
| **Interpupillary Distance** | Adjustable (58-72mm) | Fits most adults |
| **Weight** | ~100g (prototype) | Production target: <70g |
| **Battery Life** | 2-3 hours (display on) | 8+ hours (audio only) |

### Comparison: Orion vs Oakley (Expected)

| Feature | Meta Orion (Prototype) | Meta Oakley (Consumer, Expected) |
|---------|------------------------|----------------------------------|
| **Target Audience** | Developers, early adopters | Mainstream consumers |
| **FOV** | 70° | 45-50° (cost reduction) |
| **Resolution** | 1280x720 | 960x540 (cost reduction) |
| **Price** | $1500+ (estimated) | $500-800 (estimated) |
| **Release Date** | 2025-2026 (limited) | 2026-2027 (mass market) |
| **Design** | Bulkier, tech-forward | Sleek, fashion-focused (Oakley brand) |

**For Zer0 Inbox**: We design for **Meta Oakley** specs (45° FOV, 960x540), which will be the consumer hardware most users can afford.

---

## Design Principles

### 1. Glanceable, Not Engaging

**Goal**: User gets information in <2 seconds without taking action.

- Email notification shows: sender, subject, priority (not full body)
- Inbox widget shows: unread count, urgent count (not email list)
- Visual confirmation shows: "Email archived ✓" (not detailed result)

**Anti-pattern**: Requiring user to read paragraphs or make decisions while wearing glasses.

### 2. High Contrast, Low Detail

**Goal**: Maximize readability in all lighting conditions (indoor, outdoor, sunlight).

- White text on black background (or vice versa, depending on ambient light)
- Minimum font size: 24pt (perceived size at 1-2m focal distance)
- Avoid gradients, subtle colors, small icons
- Binary states: Show or hide (avoid partial transparency)

**Anti-pattern**: Low-contrast text, small fonts, detailed graphics.

### 3. Minimal Occlusion

**Goal**: Never block critical real-world view (safety first).

- Inbox widget: Top-right corner (non-critical FOV region)
- Email notifications: Center-right (visible but not central)
- Avoid bottom third (important for walking/navigation)
- Avoid left eye entirely (monocular right eye only)

**Anti-pattern**: Full-screen overlays, center-blocking notifications.

### 4. Battery Conscious

**Goal**: Extend battery life by minimizing display-on time.

- Email notifications auto-dismiss after 5 seconds (don't require manual close)
- Inbox widget sleeps after 30 seconds of inactivity (wakes on voice command)
- Display sleeps entirely after 2 minutes of no interaction
- Use black background (OLED-style power saving, though waveguides differ)

**Anti-pattern**: Always-on display, animations that prevent sleep.

### 5. Context-Aware Brightness

**Goal**: Adapt brightness to ambient light (indoor vs outdoor).

- Indoor: 500 nits (readable, low power)
- Outdoor (shade): 1000 nits
- Outdoor (direct sunlight): 2000 nits
- Use iPhone's ambient light sensor to control glasses display brightness

**Anti-pattern**: Fixed brightness (too dim outdoors, too bright indoors).

### 6. Voice-First, Display-Second

**Goal**: AR display enhances voice interaction, doesn't replace it.

- Voice command: "Archive this" → Visual confirmation: "Email archived ✓"
- Voice command: "Check inbox" → Visual widget appears with count
- Display shows result AFTER action (confirmatory), not during (instructional)

**Anti-pattern**: Requiring user to look at display to know what to say.

---

## Display Zones & Layout System

### Coordinate System

Meta's AR display uses a **head-locked coordinate system**:

- **Origin (0, 0)**: Center of user's field of view
- **X-axis**: Horizontal (left = negative, right = positive)
- **Y-axis**: Vertical (down = negative, up = positive)
- **Z-axis**: Depth (away from user = positive)
- **Units**: Normalized (-1.0 to +1.0) or pixels (0 to screen width/height)

```
        (-1, +1) ────────────────── (+1, +1)
            │                           │
            │     Top-left   Top-right  │
            │                           │
            │                           │
            │        (0, 0)             │  ← Center of FOV
            │                           │
            │                           │
            │   Bottom-left  Bottom-rt  │
            │                           │
        (-1, -1) ────────────────── (+1, -1)
```

### Safe Zones

Not all regions of the display are equally usable:

#### 1. Primary Zone (Center-Right)
- **Location**: (0.2, 0) to (0.8, 0.5)
- **Size**: 60% of display width, 50% of height
- **Use Case**: Email notifications, action confirmations
- **Visibility**: High (user naturally looks here)

#### 2. Persistent Widget Zone (Top-Right)
- **Location**: (0.6, 0.6) to (0.95, 0.9)
- **Size**: Small corner (35% width, 30% height)
- **Use Case**: Inbox count widget (always visible)
- **Visibility**: Medium (peripheral vision)

#### 3. Avoid Zone (Bottom Third)
- **Location**: (-1, -1) to (1, -0.3)
- **Size**: Bottom 30% of display
- **Use Case**: AVOID placing content here
- **Reason**: Occludes ground/stairs (safety hazard)

#### 4. Avoid Zone (Left Side)
- **Location**: (-1, -1) to (-0.5, 1)
- **Size**: Left 50% of display
- **Use Case**: AVOID placing content here
- **Reason**: Monocular display (right eye only), left may feel unbalanced

### Layout Examples

#### Example 1: Email Notification (5 seconds)

```
┌──────────────────────────────────────────────┐
│                              [12 unread] ← Widget
│                                              │
│                                              │
│            ┌──────────────────────┐          │
│            │  New Email           │          │
│            │  From: Sarah Chen    │          │
│            │  Q4 Report Ready     │          │
│            │  Priority: High      │          │
│            └──────────────────────┘          │
│                  ↑ Notification              │
│                  (Center-right)              │
│                                              │
│                                              │
│         [Bottom third: keep clear]          │
└──────────────────────────────────────────────┘
```

#### Example 2: Inbox Widget Only (Persistent)

```
┌──────────────────────────────────────────────┐
│                              ┌──────────┐    │
│                              │ 12 unread│←Widget
│                              │  3 urgent│    │
│                              └──────────┘    │
│                                              │
│                                              │
│                                              │
│                                              │
│                                              │
│                                              │
│                                              │
│         [Bottom third: keep clear]          │
└──────────────────────────────────────────────┘
```

#### Example 3: Action Confirmation (3 seconds)

```
┌──────────────────────────────────────────────┐
│                              [12 → 11] ← Updated
│                                              │
│                                              │
│                ┌─────────────────┐           │
│                │   ✓ Archived    │           │
│                └─────────────────┘           │
│                                              │
│                                              │
│                                              │
│                                              │
│         [Bottom third: keep clear]          │
└──────────────────────────────────────────────┘
```

---

## Email Notification Overlay

### When to Show

Email notifications appear when:
1. **New urgent email arrives** (priority: high, flagged, from VIP)
2. **User says "Check inbox"** and there are <5 unread (show top email)
3. **User explicitly requests**: "Show me the latest email"

Email notifications do NOT appear for:
- Low-priority emails (to avoid distraction)
- Emails older than 1 hour (not time-sensitive)
- When user is actively navigating (walking fast, driving - detected by motion sensors)

### Content Structure

Each notification shows:

```
┌──────────────────────────────────┐
│  New Email                       │ ← Title (always "New Email")
│  From: [Sender Name]             │ ← Sender (max 20 chars)
│  [Subject Line]                  │ ← Subject (max 30 chars, truncate with ...)
│  Priority: [High/Medium/Low]     │ ← Priority badge
└──────────────────────────────────┘
```

**Size**: 400px wide x 200px tall (at 960x540 resolution)
**Position**: Center-right (normalized coords: 0.3, 0.2)
**Duration**: 5 seconds (auto-dismiss)
**Background**: Semi-transparent black (80% opacity)
**Text**: White, 24pt minimum
**Border**: 2px white stroke (high contrast)

### Visual Hierarchy

```
┌──────────────────────────────────┐
│  New Email                       │  ← 18pt, uppercase, bold
│                                  │
│  From: Sarah Chen                │  ← 24pt, regular (most important)
│  Q4 Report Ready for Review      │  ← 22pt, regular
│  Priority: High                  │  ← 20pt, bold, RED color
└──────────────────────────────────┘
```

**Font Weights**:
- Title: Bold (700)
- Sender: Regular (400) - MOST IMPORTANT (largest)
- Subject: Regular (400)
- Priority: Bold (700) with color coding

**Color Coding**:
- High priority: Red (#FF3B30)
- Medium priority: Orange (#FF9500)
- Low priority: Gray (#8E8E93)

### Animation

**Appear (0.3 seconds)**:
1. Fade in from 0% to 100% opacity
2. Slide in from right (+20px) to final position
3. Ease-out curve

**Dismiss (0.3 seconds)**:
1. Fade out from 100% to 0% opacity
2. Slide out to right (+20px)
3. Ease-in curve

**No bounce, no spring**: Subtle, professional animations only.

### Example Code (ARDisplayService)

```swift
func showEmailNotification(email: WatchEmail) {
    let notification = AREmailNotification(
        title: "New Email",
        sender: email.sender,
        subject: email.title,
        priority: email.priority
    )

    // Position: center-right
    notification.position = SIMD3<Float>(0.3, 0.2, -1.5) // 1.5m away
    notification.size = CGSize(width: 0.4, height: 0.2) // Normalized

    // Render to display
    renderNotification(notification, duration: 5.0)

    // Auto-dismiss after 5 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        dismissNotification(notification)
    }
}
```

---

## Persistent Inbox Count Widget

### Purpose

The inbox widget is a **persistent, always-visible indicator** of inbox status:
- Unread count
- Urgent count

Users can glance at glasses and instantly know: "Do I need to check my inbox?"

### When to Show

**Always visible** (persistent), except:
- Display is asleep (after 2 minutes of inactivity)
- User is in "Do Not Disturb" mode
- User explicitly hides it ("Hide inbox widget")

**Wakes from sleep when**:
- User says any voice command
- New urgent email arrives
- User raises head quickly (motion sensor detects "glance up" gesture)

### Content Structure

```
┌───────────────┐
│ 12 unread     │
│  3 urgent     │
└───────────────┘
```

**Size**: 150px wide x 80px tall
**Position**: Top-right corner (normalized coords: 0.7, 0.7)
**Background**: Semi-transparent black (70% opacity)
**Text**: White, 20pt
**Icon**: Envelope icon (24x24px)

### Color Coding

- **Unread count**: White (default)
- **Urgent count**: Red (#FF3B30) if > 0, otherwise gray

```
┌───────────────┐
│ 12 unread     │ ← White
│  3 urgent     │ ← Red (urgent > 0)
└───────────────┘
```

If no urgent emails:

```
┌───────────────┐
│ 12 unread     │ ← White
│  0 urgent     │ ← Gray (no urgents)
└───────────────┘
```

### Update Behavior

Widget updates **immediately** when:
- Email is archived (unread count decreases)
- Email is flagged (urgent count may change)
- New email arrives (unread count increases)

Update is **animated**:
1. Old count fades out (0.2s)
2. New count fades in (0.2s)
3. If count increases: Brief red flash (0.5s)

### Sleep Behavior

Widget enters sleep mode after **30 seconds** of no interaction:
1. Fade out to 30% opacity (still visible, but dimmer)
2. Reduce update frequency (every 60s instead of realtime)
3. Lower display brightness by 50%

Widget wakes immediately on:
- Any voice command
- New urgent email
- User says "Show inbox"

### Example Code (ARDisplayService)

```swift
func showInboxCountWidget(unreadCount: Int, urgentCount: Int) {
    let widget = ARInboxWidget(
        unreadCount: unreadCount,
        urgentCount: urgentCount
    )

    // Position: top-right corner
    widget.position = SIMD3<Float>(0.7, 0.7, -1.5) // 1.5m away
    widget.size = CGSize(width: 0.15, height: 0.08) // Normalized

    // Persistent (no auto-dismiss)
    renderWidget(widget, persistent: true)

    // Update when inbox changes
    observeInboxChanges { newUnread, newUrgent in
        updateWidget(widget, unreadCount: newUnread, urgentCount: newUrgent)
    }
}

func updateWidget(_ widget: ARInboxWidget, unreadCount: Int, urgentCount: Int) {
    // Animate count change
    withAnimation(.easeInOut(duration: 0.2)) {
        widget.unreadCount = unreadCount
        widget.urgentCount = urgentCount
    }

    // Flash red if urgent count increased
    if urgentCount > widget.urgentCount {
        flashWidget(widget, color: .red, duration: 0.5)
    }
}
```

---

## Text Rendering & Sizing

### Focal Distance Challenge

AR displays have a **fixed focal distance** (1-2 meters), meaning virtual content appears at a fixed depth. This is different from phone screens (30cm) or watch screens (15cm).

**Implication**: Text must be sized as if viewed from 1-2 meters away.

### Minimum Font Sizes

| Use Case | Font Size (pt) | Equivalent at 1.5m | Notes |
|----------|----------------|--------------------|-------|
| **Body Text** | 24pt | ~3cm tall letter | Minimum for readability |
| **Sender Name** | 28pt | ~3.5cm tall | Most important info |
| **Subject Line** | 22pt | ~2.8cm tall | Secondary info |
| **Widget Count** | 20pt | ~2.5cm tall | Peripheral vision |
| **Confirmation** | 32pt | ~4cm tall | Quick glance |

**Rule of Thumb**: Text should be readable from 1.5 meters away in bright sunlight.

### Font Choices

**Primary Font**: SF Pro (Apple's San Francisco font)
- Designed for legibility at all sizes
- Available on iOS/macOS by default
- Variable weight (thin to black)

**Fallback Font**: System font (platform default)

**Avoid**:
- Serif fonts (harder to read at distance)
- Script fonts (decorative, low contrast)
- Condensed fonts (letters too narrow)

### Font Weights

- **Regular (400)**: Body text, sender, subject
- **Medium (500)**: Emphasis (not used often)
- **Bold (700)**: Titles, priority labels, confirmations

**Avoid**: Thin weights (< 400) - too hard to read in sunlight.

### Text Layout

**Line Spacing**: 1.5x line height (e.g., 24pt font → 36pt line height)
**Letter Spacing**: Default (0) - no need to adjust
**Alignment**: Left-aligned (easier to scan than centered)
**Max Line Length**: 30 characters (avoid wide paragraphs)

### Text Colors

**High Contrast Combinations**:

| Background | Text | Use Case |
|------------|------|----------|
| Black (100% opacity) | White | Indoor, low ambient light |
| Black (80% opacity) | White | Semi-transparent overlays |
| White (100% opacity) | Black | Outdoor, bright sunlight (if waveguide supports) |

**Accent Colors** (for priority badges):
- Red (#FF3B30): High priority, urgent
- Orange (#FF9500): Medium priority
- Green (#34C759): Success (archived, completed)
- Gray (#8E8E93): Low priority, secondary info

### Example Text Rendering

```swift
struct ARTextRenderer {
    static func renderEmailNotification(email: WatchEmail) -> ARTextNode {
        let container = ARTextNode()

        // Sender (largest, most important)
        let senderText = ARText(
            text: "From: \(email.sender)",
            font: .systemFont(ofSize: 28, weight: .regular),
            color: .white
        )
        senderText.position = SIMD3<Float>(0, 0.05, 0) // Top

        // Subject
        let subjectText = ARText(
            text: email.title.truncated(to: 30),
            font: .systemFont(ofSize: 22, weight: .regular),
            color: .white
        )
        subjectText.position = SIMD3<Float>(0, 0, 0) // Center

        // Priority badge
        let priorityText = ARText(
            text: "Priority: \(email.priority.rawValue.capitalized)",
            font: .systemFont(ofSize: 20, weight: .bold),
            color: priorityColor(email.priority)
        )
        priorityText.position = SIMD3<Float>(0, -0.05, 0) // Bottom

        container.addChild(senderText)
        container.addChild(subjectText)
        container.addChild(priorityText)

        return container
    }

    static func priorityColor(_ priority: WatchEmail.Priority) -> UIColor {
        switch priority {
        case .high:
            return UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // Red
        case .medium:
            return UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0) // Orange
        case .low:
            return UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0) // Gray
        }
    }
}
```

---

## High-Contrast UI for Outdoor Use

### The Sunlight Challenge

AR displays must compete with **direct sunlight** (100,000 lux), which is:
- 100x brighter than indoor lighting (1,000 lux)
- 1,000x brighter than evening lighting (100 lux)

**Solution**: Maximize contrast, minimize detail.

### Contrast Ratio

**Target**: 21:1 (WCAG AAA standard for large text)

Examples:
- White (#FFFFFF) on Black (#000000): 21:1 ✓
- Light Gray (#CCCCCC) on Black (#000000): 15:1 ✓
- Yellow (#FFFF00) on White (#FFFFFF): 1.07:1 ✗ (too low)

**Tool**: Use contrast checker (e.g., WebAIM Contrast Checker) to validate all text/background pairs.

### Adaptive Brightness

Display brightness adapts based on ambient light sensor:

| Ambient Light | Display Brightness | Power Draw | Use Case |
|---------------|-------------------|------------|----------|
| < 100 lux (indoor) | 500 nits | Low | Office, home |
| 100-1000 lux (shade) | 1000 nits | Medium | Outdoors, cloudy |
| > 1000 lux (sunlight) | 2000 nits | High | Direct sunlight |

**Implementation**: Use iPhone's `UIScreen.main.brightness` as proxy for ambient light (iPhone and glasses are typically in same environment).

### Edge Enhancement

To improve readability in sunlight, add **subtle edge glow** to text:

```swift
let textNode = ARText(text: "12 unread")
textNode.strokeColor = .black
textNode.strokeWidth = 2.0  // 2px black stroke around white text
```

This creates a "halo" effect that separates text from background, even in bright light.

### Avoid Transparency in Sunlight

In bright sunlight, **reduce transparency** to increase contrast:

| Ambient Light | Background Opacity | Reason |
|---------------|-------------------|--------|
| Indoor | 70% | See-through, non-intrusive |
| Outdoor (shade) | 80% | Balanced |
| Outdoor (sunlight) | 90% | Maximum contrast |

**Implementation**:

```swift
func adjustBackgroundOpacity(ambientLight: Float) -> Float {
    switch ambientLight {
    case 0..<100:
        return 0.7  // Indoor
    case 100..<1000:
        return 0.8  // Shade
    default:
        return 0.9  // Sunlight
    }
}
```

### Color Blindness Considerations

**Color blindness affects ~8% of males, ~0.5% of females.**

**Solution**: Never rely on color alone to convey information.

Examples:
- Priority badge: Use text ("High Priority") + color (red)
- Urgent indicator: Use icon (!) + color (red)
- Success confirmation: Use text ("Archived ✓") + color (green)

---

## Display Lifecycle Management

### Display States

The AR display has 4 states:

1. **Off**: Display is powered off (no content rendered)
2. **Sleep**: Display is on but dimmed (minimal power, shows widget only)
3. **Active**: Display is on at full brightness (showing notifications + widget)
4. **Error**: Display failed to initialize or lost connection

### State Transitions

```
     Off ──────────────────────────────────────> Error
      │                                            │
      │ activate()                                 │
      ▼                                            │
    Sleep ←──────────────────────────────> Active │
      │                                       │    │
      │ 30s inactivity                       │    │
      │                                       │    │
      │ voice command, notification          │    │
      └───────────────────────────────────────┘    │
                                                   │
                         reset()                   │
                      ◄──────────────────────────────┘
```

### Lifecycle Events

#### 1. Display Initialization (App Launch)

```swift
// Called when ARDisplayService initializes
func activateDisplay() async throws {
    guard MetaGlassesAdapter.shared.isConnected else {
        throw ARDisplayError.glassesNotConnected
    }

    // Wake display from off
    try await MetaGlassesAdapter.shared.wakeDisplay()

    // Render persistent widget
    showInboxCountWidget(unreadCount: currentUnreadCount, urgentCount: currentUrgentCount)

    // Transition to sleep state after 30s
    scheduleDisplaySleep(after: 30.0)

    Logger.info("✓ AR display activated", category: .arDisplay)
}
```

#### 2. Display Sleep (30s Inactivity)

```swift
func sleepDisplay() {
    // Dim widget to 30% opacity
    dimWidget(opacity: 0.3)

    // Reduce refresh rate to 1 Hz (from 60 Hz)
    setRefreshRate(1.0)

    // Lower display brightness by 50%
    adjustBrightness(multiplier: 0.5)

    currentState = .sleep

    Logger.debug("Display entered sleep state", category: .arDisplay)
}
```

#### 3. Display Wake (Voice Command, Notification)

```swift
func wakeDisplay() {
    // Restore widget to 100% opacity
    dimWidget(opacity: 1.0)

    // Restore refresh rate to 60 Hz
    setRefreshRate(60.0)

    // Restore brightness
    adjustBrightness(multiplier: 1.0)

    currentState = .active

    // Schedule sleep after 30s
    scheduleDisplaySleep(after: 30.0)

    Logger.debug("Display woke from sleep", category: .arDisplay)
}
```

#### 4. Display Shutdown (App Quit, Glasses Disconnected)

```swift
func deactivateDisplay() {
    // Dismiss all notifications
    dismissAllNotifications()

    // Hide widget
    hideInboxCountWidget()

    // Power off display
    MetaGlassesAdapter.shared.sleepDisplay()

    currentState = .off

    Logger.info("AR display deactivated", category: .arDisplay)
}
```

### Automatic Sleep/Wake Triggers

**Sleep Triggers** (transition to sleep after 30s):
- No voice commands spoken
- No new notifications
- No user interaction (EMG gestures)
- iPhone screen is locked

**Wake Triggers** (instant wake from sleep):
- User says any voice command
- New urgent email arrives
- User raises head quickly (motion sensor: >30° vertical head tilt in <0.5s)
- User explicitly says "Wake display"

### Error Recovery

If display fails or loses connection:

```swift
func handleDisplayError(_ error: ARDisplayError) {
    Logger.error("AR display error: \(error)", category: .arDisplay)

    currentState = .error

    // Attempt reconnection (max 3 retries)
    retryConnection(maxAttempts: 3, delay: 2.0)

    // If reconnection fails, fall back to voice-only mode
    if !reconnectionSucceeded {
        Logger.warning("Falling back to voice-only mode", category: .arDisplay)
        VoiceOutputService.shared.speak("AR display unavailable. Switching to voice-only mode.")
    }
}
```

---

## Animation & Transitions

### Animation Principles

1. **Subtle, not showy**: Animations should enhance, not distract.
2. **Fast**: All animations complete in <0.5 seconds.
3. **Purposeful**: Every animation serves a functional purpose (draw attention, confirm action).
4. **Consistent**: Use same easing curves throughout.

### Standard Animations

#### 1. Notification Appear

```swift
func animateNotificationAppear(_ notification: ARNotification) {
    // Duration: 0.3 seconds
    // Ease-out curve

    notification.opacity = 0.0
    notification.position.x += 20 // Start 20px to the right

    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut) {
        notification.opacity = 1.0
        notification.position.x -= 20 // Slide to final position
    }
}
```

#### 2. Notification Dismiss

```swift
func animateNotificationDismiss(_ notification: ARNotification, completion: @escaping () -> Void) {
    // Duration: 0.3 seconds
    // Ease-in curve

    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn) {
        notification.opacity = 0.0
        notification.position.x += 20 // Slide to the right
    } completion: { _ in
        completion()
    }
}
```

#### 3. Widget Update

```swift
func animateWidgetUpdate(_ widget: ARInboxWidget, oldCount: Int, newCount: Int) {
    // Duration: 0.2 seconds fade out + 0.2 seconds fade in

    // Phase 1: Fade out old count
    UIView.animate(withDuration: 0.2) {
        widget.countLabel.opacity = 0.0
    } completion: { _ in
        // Update count
        widget.countLabel.text = "\(newCount) unread"

        // Phase 2: Fade in new count
        UIView.animate(withDuration: 0.2) {
            widget.countLabel.opacity = 1.0
        }
    }

    // If count increased, flash red
    if newCount > oldCount {
        flashWidget(widget, color: .red, duration: 0.5)
    }
}
```

#### 4. Action Confirmation

```swift
func animateActionConfirmation(_ action: WatchAction) {
    // Show large checkmark
    let checkmark = ARCheckmarkNode()
    checkmark.scale = 0.5 // Start small
    checkmark.opacity = 0.0

    // Appear: Scale up + fade in (0.3s)
    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut) {
        checkmark.scale = 1.0
        checkmark.opacity = 1.0
    } completion: { _ in
        // Hold for 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Dismiss: Fade out (0.3s)
            UIView.animate(withDuration: 0.3) {
                checkmark.opacity = 0.0
            } completion: { _ in
                checkmark.removeFromParent()
            }
        }
    }
}
```

### Easing Curves

**Ease-Out**: Start fast, end slow (used for appear animations)
**Ease-In**: Start slow, end fast (used for dismiss animations)
**Ease-In-Out**: Start slow, fast in middle, end slow (used for state transitions)

**Avoid**: Linear easing (feels robotic), spring/bounce (feels unprofessional for email app).

### Performance Optimization

**Target**: 60 FPS during animations (16.67ms per frame)

**Techniques**:
1. **Pre-render**: Render notification content before animation starts
2. **GPU acceleration**: Use GPU-backed views (CALayer, Metal)
3. **Limit simultaneous animations**: Max 2 animations at once
4. **Cache assets**: Pre-load icons, fonts, backgrounds

---

## Integration with Voice Navigation

### Voice → Display Flow

When user speaks a command, display provides **visual confirmation**:

| Voice Command | Visual Feedback | Duration |
|---------------|-----------------|----------|
| "Check inbox" | Wake widget, show count | Persistent |
| "Read email" | Highlight email in notification (if visible) | 5s |
| "Archive this" | Show "✓ Archived" confirmation | 3s |
| "Flag email" | Show "✓ Flagged" confirmation | 3s |
| "Delete this" | Show "✓ Deleted" confirmation | 3s |
| "Next email" | Dismiss current notification, show next | 5s |

### Display → Voice Flow

Display events can trigger voice output:

| Display Event | Voice Output |
|---------------|--------------|
| New urgent email notification appears | "You have a new urgent email from [Sender]." |
| Inbox count increases by >5 | "You have 15 unread emails. Would you like a summary?" |
| Action confirmation shown | "Email archived." |

**Note**: Voice output is **optional** (user can disable in settings).

### Example Integration

```swift
// VoiceNavigationService.swift
func processVoiceCommand(_ command: String) {
    switch command {
    case "check inbox":
        // 1. Get inbox data
        let (unread, urgent) = getInboxCounts()

        // 2. Voice output
        VoiceOutputService.shared.speak("You have \(unread) unread emails, \(urgent) urgent.")

        // 3. Visual display
        ARDisplayService.shared.showInboxCountWidget(unreadCount: unread, urgentCount: urgent)

    case "archive this":
        // 1. Execute action
        let success = await archiveCurrentEmail()

        // 2. Voice confirmation
        if success {
            VoiceOutputService.shared.speak("Email archived.")

            // 3. Visual confirmation
            ARDisplayService.shared.showActionConfirmation(.archive)
        }

    default:
        break
    }
}
```

### Display Priority Rules

If both voice output and display are active:
- **Display always shows** (non-intrusive, user can ignore)
- **Voice output is queued** (waits for TTS to finish current utterance)

If multiple notifications arrive simultaneously:
- **Urgent emails take priority** (dismiss low-priority notification)
- **Action confirmations take priority** (user-initiated actions are most important)

---

## Integration with MetaGlassesAdapter

### Architecture

`ARDisplayService` depends on `MetaGlassesAdapter` to communicate with glasses hardware:

```
┌──────────────────────────┐
│    ARDisplayService      │  ← High-level (email notifications, widgets)
│  - showEmailNotification │
│  - showInboxCountWidget  │
│  - showActionConfirmation│
└────────────┬─────────────┘
             │
             │ renderToDisplay(content: ARContent)
             │ adjustBrightness(nits: Int)
             │ wakeDisplay() / sleepDisplay()
             ▼
┌──────────────────────────┐
│   MetaGlassesAdapter     │  ← Low-level (SDK, Bluetooth, hardware)
│  - connectToGlasses()    │
│  - sendDisplayCommand()  │
│  - getDisplayCapabilities│
└────────────┬─────────────┘
             │
             │ Meta SDK / Bluetooth LE
             ▼
┌──────────────────────────┐
│  Meta Oakley/Orion       │  ← Physical hardware
│  (Waveguide Display)     │
└──────────────────────────┘
```

### API Contract

`ARDisplayService` calls methods on `MetaGlassesAdapter`:

#### 1. Render Content to Display

```swift
func renderToDisplay(content: ARContent) async throws {
    // ARContent contains:
    // - position: SIMD3<Float> (x, y, z)
    // - size: CGSize (width, height in normalized coords)
    // - texture: UIImage or CIImage
    // - opacity: Float (0.0 to 1.0)

    guard MetaGlassesAdapter.shared.isConnected else {
        throw ARDisplayError.glassesNotConnected
    }

    try await MetaGlassesAdapter.shared.renderContent(content)
}
```

#### 2. Adjust Display Brightness

```swift
func adjustDisplayBrightness(nits: Int) {
    // nits: 500 (indoor), 1000 (shade), 2000 (sunlight)
    MetaGlassesAdapter.shared.setDisplayBrightness(nits)
}
```

#### 3. Wake/Sleep Display

```swift
func wakeDisplay() {
    MetaGlassesAdapter.shared.wakeDisplay()
}

func sleepDisplay() {
    MetaGlassesAdapter.shared.sleepDisplay()
}
```

#### 4. Get Display Capabilities

```swift
func getDisplayCapabilities() -> DisplayCapabilities {
    return MetaGlassesAdapter.shared.displayCapabilities
}

struct DisplayCapabilities {
    let resolution: CGSize          // e.g., (960, 540)
    let fieldOfView: Float          // e.g., 45° diagonal
    let maxBrightness: Int          // e.g., 2000 nits
    let refreshRate: Int            // e.g., 60 Hz
    let supportsColor: Bool         // true for Oakley/Orion
}
```

### Fallback Behavior

If `MetaGlassesAdapter` reports glasses are not connected:

```swift
func showEmailNotification(email: WatchEmail) {
    guard MetaGlassesAdapter.shared.isConnected else {
        Logger.debug("Glasses not connected, falling back to voice-only", category: .arDisplay)

        // Fall back to voice output
        VoiceOutputService.shared.speak("New email from \(email.sender): \(email.title)")
        return
    }

    // Proceed with AR display
    renderEmailNotification(email)
}
```

### Error Handling

```swift
func handleMetaGlassesError(_ error: MetaGlassesError) {
    switch error {
    case .connectionLost:
        Logger.warning("Glasses connection lost, attempting reconnect", category: .arDisplay)
        attemptReconnect()

    case .displayUnavailable:
        Logger.warning("Display unavailable, falling back to voice-only", category: .arDisplay)
        disableARDisplay()

    case .lowBattery:
        Logger.info("Glasses battery low, disabling display to conserve power", category: .arDisplay)
        sleepDisplay()

    default:
        Logger.error("Unknown Meta Glasses error: \(error)", category: .arDisplay)
    }
}
```

---

## ARKit Fallback for Development

### Why ARKit?

**Problem**: Meta Oakley/Orion glasses are not yet released (2026-2027 expected).

**Solution**: Use **ARKit** on iPhone/iPad to prototype and test AR display functionality.

ARKit allows us to:
- Render 3D content in camera view (simulates see-through display)
- Position content at fixed distances (1-2 meters)
- Test text sizing, readability, layout
- Validate animations and transitions

**Limitation**: ARKit on iPhone is **held-in-hand**, not **head-mounted**, so ergonomics differ. But it's sufficient for development.

### ARKit Implementation

```swift
import ARKit

class ARKitDisplaySimulator: NSObject, ARSCNViewDelegate {
    let sceneView = ARSCNView()

    func setup() {
        sceneView.delegate = self
        sceneView.session.run(ARWorldTrackingConfiguration())
    }

    func showEmailNotification(email: WatchEmail) {
        // Create 3D plane for notification
        let plane = SCNPlane(width: 0.4, height: 0.2) // 40cm x 20cm
        let material = SCNMaterial()

        // Render notification as UIImage
        let notificationImage = renderNotificationToImage(email)
        material.diffuse.contents = notificationImage

        plane.materials = [material]

        // Create node
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3(0.3, 0.2, -1.5) // 1.5m away, center-right

        // Add to scene
        sceneView.scene.rootNode.addChildNode(node)

        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            node.removeFromParentNode()
        }
    }

    func renderNotificationToImage(_ email: WatchEmail) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        return renderer.image { context in
            // Black background
            UIColor.black.withAlphaComponent(0.8).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))

            // White text
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            "New Email".draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)

            let senderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor.white
            ]
            "From: \(email.sender)".draw(at: CGPoint(x: 20, y: 60), withAttributes: senderAttributes)

            let subjectAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .regular),
                .foregroundColor: UIColor.white
            ]
            email.title.draw(at: CGPoint(x: 20, y: 100), withAttributes: subjectAttributes)
        }
    }
}
```

### Testing with ARKit

**To test on iPhone**:
1. Run Zer0 app on physical iPhone (ARKit requires device, not simulator)
2. Enable "ARKit Simulation Mode" in Settings
3. Hold iPhone at arm's length (~1 meter)
4. Trigger email notification via voice command
5. Notification appears overlaid on camera view at 1.5m distance

**To test on iPad**:
- Same as iPhone, but larger screen simulates wider FOV

### Switching Between ARKit and Meta Glasses

```swift
class ARDisplayService {
    enum DisplayMode {
        case metaGlasses  // Real Meta Oakley/Orion hardware
        case arkit        // ARKit simulation on iPhone/iPad
        case disabled     // No AR display
    }

    var currentMode: DisplayMode = .disabled

    func determineDisplayMode() {
        if MetaGlassesAdapter.shared.isConnected && MetaGlassesAdapter.shared.hasDisplay {
            currentMode = .metaGlasses
            Logger.info("Using Meta Glasses display", category: .arDisplay)

        } else if ARWorldTrackingConfiguration.isSupported {
            currentMode = .arkit
            Logger.info("Using ARKit simulation mode", category: .arDisplay)

        } else {
            currentMode = .disabled
            Logger.warning("No AR display available", category: .arDisplay)
        }
    }

    func showEmailNotification(email: WatchEmail) {
        switch currentMode {
        case .metaGlasses:
            showNotificationOnMetaGlasses(email)

        case .arkit:
            showNotificationWithARKit(email)

        case .disabled:
            Logger.debug("AR display disabled, no notification shown", category: .arDisplay)
        }
    }
}
```

---

## Rendering Pipeline

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. VoiceNavigationService detects new urgent email        │
│     └─> Calls ARDisplayService.showEmailNotification()     │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  2. ARDisplayService prepares notification content         │
│     - Extracts sender, subject, priority                   │
│     - Truncates text to fit display                        │
│     - Determines position (center-right)                   │
│     - Sets duration (5 seconds)                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  3. ARRenderer converts to GPU-ready format                │
│     - Renders text to texture (UIImage → CIImage)          │
│     - Applies background, border, shadows                  │
│     - Encodes as Metal texture                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  4. MetaGlassesAdapter sends to glasses                    │
│     - Meta SDK: sendDisplayCommand(texture, position)      │
│     - Bluetooth LE: Send texture as byte array             │
│     - Fallback ARKit: Render to SCNNode in ARSCNView       │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  5. Meta Glasses firmware renders to waveguide display     │
│     - Projects texture onto right eye waveguide            │
│     - Adjusts brightness based on ambient light            │
│     - User sees notification overlaid on real world        │
└─────────────────────────────────────────────────────────────┘
```

### Detailed Pipeline Stages

#### Stage 1: Content Preparation (ARDisplayService)

```swift
func showEmailNotification(email: WatchEmail) {
    // Create notification content
    let content = ARNotificationContent(
        title: "New Email",
        sender: email.sender.truncated(to: 20),
        subject: email.title.truncated(to: 30),
        priority: email.priority,
        position: SIMD3<Float>(0.3, 0.2, -1.5), // Center-right, 1.5m away
        size: CGSize(width: 0.4, height: 0.2),
        duration: 5.0
    )

    // Pass to renderer
    ARRenderer.shared.render(content)
}
```

#### Stage 2: Text Rendering (ARRenderer)

```swift
func render(_ content: ARNotificationContent) -> ARTexture {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
    let image = renderer.image { context in
        // Background (semi-transparent black)
        UIColor.black.withAlphaComponent(0.8).setFill()
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))

        // Border (white, 2px)
        UIColor.white.setStroke()
        context.stroke(CGRect(x: 1, y: 1, width: 398, height: 198), lineWidth: 2.0)

        // Render text
        renderText(content.title, at: CGPoint(x: 20, y: 20), size: 18, weight: .bold, color: .white, in: context)
        renderText("From: \(content.sender)", at: CGPoint(x: 20, y: 60), size: 24, weight: .regular, color: .white, in: context)
        renderText(content.subject, at: CGPoint(x: 20, y: 100), size: 22, weight: .regular, color: .white, in: context)

        // Priority badge
        let priorityColor = colorForPriority(content.priority)
        renderText("Priority: \(content.priority.rawValue)", at: CGPoint(x: 20, y: 140), size: 20, weight: .bold, color: priorityColor, in: context)
    }

    // Convert to Metal texture
    return ARTexture(image: image, position: content.position, size: content.size)
}
```

#### Stage 3: GPU Encoding (Metal)

```swift
func encodeTexture(_ texture: ARTexture) -> MTLTexture {
    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("Metal not available")
    }

    let textureLoader = MTKTextureLoader(device: device)
    let metalTexture = try! textureLoader.newTexture(cgImage: texture.image.cgImage!)

    return metalTexture
}
```

#### Stage 4: Transmission to Glasses (MetaGlassesAdapter)

```swift
func sendToGlasses(texture: MTLTexture, position: SIMD3<Float>, size: CGSize) async throws {
    if let metaSDK = self.metaSDK {
        // Use Meta SDK (preferred)
        try await metaSDK.display.render(
            texture: texture,
            position: position,
            size: size,
            duration: 5.0
        )

    } else if self.bluetoothConnected {
        // Fallback: Send via Bluetooth LE
        let imageData = encodeTextureToJPEG(texture, quality: 0.8)
        try await bluetoothManager.sendDisplayCommand(
            data: imageData,
            position: position,
            size: size
        )

    } else {
        throw ARDisplayError.glassesNotConnected
    }
}
```

#### Stage 5: Glasses Firmware (Meta's Implementation)

*This is handled by Meta's firmware, outside our control. Meta's glasses will:*
- Receive texture + position + size via SDK or Bluetooth
- Decode texture (JPEG or raw RGB)
- Project onto waveguide display using micro-projector
- Adjust brightness based on ambient light sensor
- Display for specified duration (5 seconds)
- Fade out after duration

---

## Performance Targets

### Latency

| Metric | Target | Notes |
|--------|--------|-------|
| **Voice command → Display appear** | < 500ms | "Archive this" → "✓ Archived" |
| **New email → Notification appear** | < 1 second | Backend → Push → Display |
| **Texture render time** | < 50ms | Text → UIImage → Metal texture |
| **Transmission to glasses** | < 100ms | iPhone → Bluetooth → Glasses |
| **Display update rate** | 60 FPS | Smooth animations |

**Total end-to-end**: < 1.5 seconds from trigger to visible on display.

### Frame Rate

- **Target**: 60 FPS (16.67ms per frame)
- **Minimum acceptable**: 30 FPS (33.33ms per frame)
- **During animations**: Must maintain 60 FPS (no dropped frames)

### Memory Usage

| Component | Budget | Notes |
|-----------|--------|-------|
| **ARDisplayService** | < 10 MB | Service + state |
| **Texture cache** | < 5 MB | Pre-rendered textures |
| **Metal buffers** | < 10 MB | GPU memory |
| **Total AR system** | < 25 MB | Combined |

### Battery Impact

| Mode | iPhone Drain | Glasses Drain | Notes |
|------|--------------|---------------|-------|
| **Display off** | 0% per hour | 0% per hour | No impact |
| **Widget only (sleep)** | 1% per hour | 3% per hour | Minimal |
| **Active notifications** | 3% per hour | 10% per hour | Typical usage |
| **Continuous display** | 5% per hour | 15% per hour | Worst case |

**Goal**: User can wear glasses for 8 hours with <20% battery drain (glasses + iPhone combined).

### Network Usage

- **Notification content**: ~1 KB per email (sender, subject, priority only)
- **Widget updates**: ~100 bytes per update (unread count, urgent count)
- **Total per day**: < 1 MB (assuming 50 emails/day)

**No images, no attachments**: AR notifications are text-only to minimize bandwidth.

---

## Battery Optimization

### Display Power Consumption

AR displays are **power-hungry** (15% per hour for glasses, 3% per hour for iPhone).

**Optimization strategies**:

#### 1. Auto-Sleep After Inactivity

- Display sleeps after **30 seconds** of no interaction
- Widget dims to 30% opacity (lower power)
- Refresh rate drops to 1 Hz (from 60 Hz)

#### 2. Adaptive Brightness

- Indoor (< 100 lux): 500 nits (low power)
- Outdoor (shade): 1000 nits (medium power)
- Outdoor (sunlight): 2000 nits (high power, short duration)

**Power savings**: ~30% reduction by avoiding max brightness indoors.

#### 3. Content Caching

- Pre-render notification templates (sender, subject, priority)
- Cache textures in GPU memory (avoid re-encoding)
- Reuse Metal textures when possible

**Power savings**: ~10% reduction by avoiding redundant GPU work.

#### 4. Minimize Animation

- Limit animations to 0.3 seconds (fast, energy-efficient)
- Avoid continuous animations (e.g., spinning icons)
- Use fade in/out instead of slide (less GPU work)

**Power savings**: ~5% reduction by simplifying animations.

#### 5. Batch Updates

- Group multiple widget updates into single transmission
- Update widget every 60 seconds (not realtime) when in sleep mode
- Send textures compressed (JPEG quality 0.8, not lossless)

**Power savings**: ~10% reduction by minimizing Bluetooth transmissions.

### Total Estimated Savings

| Optimization | Power Savings |
|--------------|---------------|
| Auto-sleep | 40% |
| Adaptive brightness | 30% |
| Content caching | 10% |
| Minimize animation | 5% |
| Batch updates | 10% |
| **Total** | **~70% savings** |

**Result**: With all optimizations, display drain drops from 15% per hour → ~5% per hour (comparable to Apple Watch).

---

## Error Handling & Recovery

### Error Types

```swift
enum ARDisplayError: LocalizedError {
    case glassesNotConnected
    case displayUnavailable
    case renderingFailed
    case transmissionFailed
    case lowBattery
    case unsupportedHardware

    var errorDescription: String? {
        switch self {
        case .glassesNotConnected:
            return "Smart glasses are not connected."
        case .displayUnavailable:
            return "AR display is unavailable on this device."
        case .renderingFailed:
            return "Failed to render notification content."
        case .transmissionFailed:
            return "Failed to send content to glasses."
        case .lowBattery:
            return "Glasses battery is too low for display."
        case .unsupportedHardware:
            return "This device does not support AR display."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .glassesNotConnected:
            return "Check that your glasses are paired and nearby."
        case .displayUnavailable:
            return "AR display requires Meta Oakley or Orion glasses."
        case .renderingFailed:
            return "Restart the app and try again."
        case .transmissionFailed:
            return "Move closer to your iPhone and try again."
        case .lowBattery:
            return "Charge your glasses to enable display."
        case .unsupportedHardware:
            return "AR display is not available on your current hardware."
        }
    }
}
```

### Recovery Strategies

#### 1. Glasses Not Connected

```swift
func handleGlassesDisconnected() {
    Logger.warning("Glasses disconnected, falling back to voice-only", category: .arDisplay)

    // Disable AR display
    currentMode = .disabled

    // Notify user via voice
    VoiceOutputService.shared.speak("Smart glasses disconnected. Switching to voice-only mode.")

    // Attempt reconnection in background (every 10 seconds)
    scheduleReconnectionAttempt(interval: 10.0)
}
```

#### 2. Rendering Failed

```swift
func handleRenderingFailed(error: Error) {
    Logger.error("Rendering failed: \(error)", category: .arDisplay)

    // Retry once
    retryCount += 1
    if retryCount < 2 {
        Logger.debug("Retrying render (attempt \(retryCount))", category: .arDisplay)
        renderNotification(lastContent)
    } else {
        // Give up, fall back to voice
        Logger.warning("Rendering failed after retry, falling back to voice", category: .arDisplay)
        VoiceOutputService.shared.speak(lastContent.toSpeech())
    }
}
```

#### 3. Low Battery (Glasses)

```swift
func handleLowBattery() {
    Logger.info("Glasses battery low, disabling display", category: .arDisplay)

    // Sleep display immediately
    sleepDisplay()

    // Notify user
    VoiceOutputService.shared.speak("Glasses battery is low. AR display disabled to conserve power.")

    // Switch to voice-only mode
    currentMode = .disabled
}
```

#### 4. Transmission Failed

```swift
func handleTransmissionFailed(error: Error) {
    Logger.error("Transmission failed: \(error)", category: .arDisplay)

    // Check connection status
    if !MetaGlassesAdapter.shared.isConnected {
        handleGlassesDisconnected()
        return
    }

    // Retry with exponential backoff
    let delay = pow(2.0, Double(retryCount)) // 1s, 2s, 4s
    retryCount += 1

    if retryCount < 4 {
        Logger.debug("Retrying transmission in \(delay)s", category: .arDisplay)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.retransmit()
        }
    } else {
        Logger.warning("Transmission failed after retries, giving up", category: .arDisplay)
    }
}
```

### Graceful Degradation

If AR display fails, the app **continues to function** with voice-only mode:

```
AR Display Available? ────> YES ─> Voice + Display (best experience)
                      │
                      └───> NO ──> Voice Only (fallback)
```

**User experience remains functional** regardless of display availability.

---

## Testing Strategy

### Unit Tests

**File**: `ARDisplayServiceTests.swift`

```swift
import XCTest
@testable import Zero

class ARDisplayServiceTests: XCTestCase {
    var service: ARDisplayService!

    override func setUp() {
        service = ARDisplayService()
        service.currentMode = .disabled // Don't require real glasses
    }

    func testShowEmailNotification() {
        let email = WatchEmail(
            id: "1",
            title: "Test Email",
            sender: "Test Sender",
            senderInitial: "TS",
            timeAgo: "1m ago",
            priority: .high,
            archetype: "work",
            hpa: "Reply",
            isUnread: true,
            isUrgent: true
        )

        service.showEmailNotification(email)

        // Verify notification was prepared
        XCTAssertNotNil(service.currentNotification)
        XCTAssertEqual(service.currentNotification?.sender, "Test Sender")
    }

    func testWidgetUpdate() {
        service.showInboxCountWidget(unreadCount: 10, urgentCount: 2)

        // Verify widget state
        XCTAssertNotNil(service.inboxWidget)
        XCTAssertEqual(service.inboxWidget?.unreadCount, 10)
        XCTAssertEqual(service.inboxWidget?.urgentCount, 2)

        // Update counts
        service.updateInboxWidget(unreadCount: 8, urgentCount: 1)

        XCTAssertEqual(service.inboxWidget?.unreadCount, 8)
        XCTAssertEqual(service.inboxWidget?.urgentCount, 1)
    }

    func testAutoSleep() {
        let expectation = expectation(description: "Display should sleep after 30s")

        service.wakeDisplay()
        XCTAssertEqual(service.currentState, .active)

        // Wait 31 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 31.0) {
            XCTAssertEqual(self.service.currentState, .sleep)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 35.0)
    }
}
```

### Integration Tests

**File**: `ARDisplayIntegrationTests.swift`

Test integration with `MetaGlassesAdapter`:

```swift
func testGlassesFallback() {
    // Simulate glasses disconnected
    MetaGlassesAdapter.shared._testDisconnect()

    let email = mockEmail()
    service.showEmailNotification(email)

    // Verify fallback to voice
    XCTAssertTrue(VoiceOutputService.shared.isSpeaking)
    XCTAssertEqual(service.currentMode, .disabled)
}

func testARKitFallback() {
    // Simulate Meta glasses unavailable, ARKit available
    MetaGlassesAdapter.shared._testDisconnect()
    service.currentMode = .arkit

    let email = mockEmail()
    service.showEmailNotification(email)

    // Verify ARKit rendering
    XCTAssertNotNil(service.arkitSimulator.currentNotification)
}
```

### Manual Testing

#### Test Case 1: Email Notification Appears

**Steps**:
1. Connect Meta Oakley glasses (or enable ARKit simulation)
2. Trigger new urgent email via test interface
3. Observe AR display

**Expected**:
- Notification appears center-right in 0.3s
- Shows sender, subject, priority
- Auto-dismisses after 5s

#### Test Case 2: Inbox Widget Updates

**Steps**:
1. Show inbox widget (say "Check inbox")
2. Archive an email
3. Observe widget count

**Expected**:
- Widget count decreases by 1
- Fade-out/fade-in animation (0.4s total)
- No flash (since count decreased, not increased)

#### Test Case 3: Display Auto-Sleep

**Steps**:
1. Show inbox widget
2. Wait 30 seconds without interaction
3. Observe display brightness

**Expected**:
- Widget dims to 30% opacity after 30s
- Display remains visible but dimmer

#### Test Case 4: Sunlight Readability

**Steps**:
1. Show notification indoors (< 100 lux)
2. Walk outside into direct sunlight (> 1000 lux)
3. Observe display brightness

**Expected**:
- Indoor: 500 nits (readable, comfortable)
- Outdoor: 2000 nits (bright, still readable)
- Automatic adjustment (no manual intervention)

#### Test Case 5: Graceful Degradation

**Steps**:
1. Connect glasses
2. Show notification
3. Disconnect glasses mid-notification
4. Observe behavior

**Expected**:
- Notification disappears from display
- Voice output speaks: "Smart glasses disconnected. Switching to voice-only mode."
- App continues to function (voice commands still work)

### Performance Testing

Use **Xcode Instruments** to profile:

1. **Time Profiler**: Identify slow rendering (target: < 50ms per notification)
2. **Memory Graph**: Check for leaks in Metal textures
3. **Network**: Verify Bluetooth transmission < 100ms
4. **Energy Log**: Measure battery drain (target: < 3% per hour iPhone, < 10% per hour glasses)

---

## Implementation Phases

### Phase 1: ARKit Prototype (Week 5, Days 1-3)

**Goal**: Validate AR display concepts using ARKit on iPhone/iPad.

**Tasks**:
- [ ] Create `ARDisplayService.swift` (300 LOC)
- [ ] Implement ARKit scene view
- [ ] Render email notification to 3D plane
- [ ] Render inbox widget
- [ ] Test on physical iPhone (ARKit requires device)

**Deliverable**: ARKit demo showing notifications at 1.5m distance.

**ETA**: 3 days

---

### Phase 2: MetaGlassesAdapter Integration (Week 5, Days 4-5)

**Goal**: Connect ARDisplayService to MetaGlassesAdapter.

**Tasks**:
- [ ] Implement display rendering API in MetaGlassesAdapter
- [ ] Add brightness control
- [ ] Add wake/sleep display
- [ ] Test fallback behavior (ARKit when glasses unavailable)

**Deliverable**: Seamless switching between Meta glasses and ARKit.

**ETA**: 2 days

---

### Phase 3: Voice Integration (Week 5, Days 6-7)

**Goal**: Trigger AR display from voice commands.

**Tasks**:
- [ ] Integrate with VoiceNavigationService
- [ ] Show visual confirmations for actions (archive, flag, delete)
- [ ] Update inbox widget on voice command ("Check inbox")
- [ ] Test end-to-end: voice → display → voice

**Deliverable**: Voice commands trigger AR display updates.

**ETA**: 2 days

---

### Phase 4: Polish & Optimization (Week 6, Days 1-3)

**Goal**: Optimize performance, battery, readability.

**Tasks**:
- [ ] Implement adaptive brightness (ambient light sensor)
- [ ] Implement auto-sleep (30s inactivity)
- [ ] Optimize texture rendering (cache templates)
- [ ] Test sunlight readability (outdoor)
- [ ] Measure battery drain (target: < 10% per hour glasses)

**Deliverable**: Production-ready AR display with optimizations.

**ETA**: 3 days

---

### Phase 5: Testing & Documentation (Week 6, Days 4-5)

**Goal**: Comprehensive testing, user-facing docs.

**Tasks**:
- [ ] Unit tests (ARDisplayServiceTests)
- [ ] Integration tests (with MetaGlassesAdapter, VoiceNavigationService)
- [ ] Manual testing (5 test cases documented above)
- [ ] Update WEARABLES_PROGRESS_TRACKER.md
- [ ] Create AR_DISPLAY_QUICKSTART.md (user guide)

**Deliverable**: Tested, documented AR display system.

**ETA**: 2 days

---

### Phase 6: Production Integration (Week 7, Days 1-2)

**Goal**: Integrate with production Zer0 iOS app (<50 lines).

**Tasks**:
- [ ] Initialize ARDisplayService in AppDelegate
- [ ] Set callback for inbox data provider
- [ ] Trigger notifications on new urgent emails
- [ ] Feature flag: "Enable AR Display" in Settings

**Deliverable**: AR display live in production app (behind feature flag).

**ETA**: 2 days

---

**Total Implementation Time**: 12 days (2.5 weeks across Week 5-7)

---

## Code Structure

### File Organization

```
Zero/
├── Services/
│   ├── ARDisplayService.swift              (300 LOC) ← Core service
│   ├── MetaGlassesAdapter.swift            (250 LOC) ← Hardware interface
│   └── VoiceNavigationService.swift        (500 LOC) ← Integration
├── Models/
│   ├── ARContent.swift                     (100 LOC) ← Display content models
│   └── WatchModels.swift                   (200 LOC) ← Shared models
├── Views/
│   ├── AR/
│   │   ├── ARNotificationView.swift        (150 LOC) ← Notification UI
│   │   ├── ARInboxWidgetView.swift         (100 LOC) ← Widget UI
│   │   └── ARKitSimulatorView.swift        (200 LOC) ← ARKit fallback
├── Utilities/
│   ├── ARRenderer.swift                    (200 LOC) ← Text → Texture rendering
│   └── ARAnimator.swift                    (150 LOC) ← Animation helpers
└── Tests/
    ├── ARDisplayServiceTests.swift         (200 LOC)
    └── ARDisplayIntegrationTests.swift     (150 LOC)
```

**Total Estimated LOC**: ~2,000 lines

---

### ARDisplayService.swift (Core Service)

```swift
import Foundation
import ARKit
import Metal

@MainActor
class ARDisplayService: NSObject, ObservableObject {
    static let shared = ARDisplayService()

    // MARK: - Published State

    @Published var isDisplayActive: Bool = false
    @Published var currentState: DisplayState = .off
    @Published var currentNotification: ARNotificationContent?
    @Published var inboxWidget: ARInboxWidget?

    enum DisplayState {
        case off
        case sleep
        case active
        case error
    }

    // MARK: - Private Properties

    private var currentMode: DisplayMode = .disabled
    private var renderer: ARRenderer!
    private var animator: ARAnimator!
    private var sleepTimer: Timer?

    enum DisplayMode {
        case metaGlasses
        case arkit
        case disabled
    }

    // MARK: - Initialization

    override init() {
        super.init()

        renderer = ARRenderer()
        animator = ARAnimator()

        determineDisplayMode()

        Logger.info("✓ ARDisplayService initialized (mode: \(currentMode))", category: .arDisplay)
    }

    // MARK: - Public API

    func showEmailNotification(_ email: WatchEmail) {
        guard currentMode != .disabled else {
            Logger.debug("AR display disabled, falling back to voice", category: .arDisplay)
            fallbackToVoice(email)
            return
        }

        let content = ARNotificationContent(
            title: "New Email",
            sender: email.sender,
            subject: email.title,
            priority: email.priority,
            position: SIMD3<Float>(0.3, 0.2, -1.5),
            size: CGSize(width: 0.4, height: 0.2),
            duration: 5.0
        )

        currentNotification = content

        // Render
        switch currentMode {
        case .metaGlasses:
            renderToMetaGlasses(content)
        case .arkit:
            renderToARKit(content)
        case .disabled:
            break
        }

        // Wake display
        wakeDisplay()

        // Auto-dismiss after 5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.dismissNotification()
        }
    }

    func showInboxCountWidget(unreadCount: Int, urgentCount: Int) {
        let widget = ARInboxWidget(
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            position: SIMD3<Float>(0.7, 0.7, -1.5),
            size: CGSize(width: 0.15, height: 0.08)
        )

        inboxWidget = widget

        // Render
        switch currentMode {
        case .metaGlasses:
            renderWidgetToMetaGlasses(widget)
        case .arkit:
            renderWidgetToARKit(widget)
        case .disabled:
            break
        }

        // Schedule sleep
        scheduleSleep(after: 30.0)
    }

    func showActionConfirmation(_ action: WatchAction) {
        let confirmation = ARConfirmationContent(
            message: "\(action.label)d", // "Archived", "Flagged", etc.
            icon: action.icon,
            position: SIMD3<Float>(0.4, 0.1, -1.5),
            size: CGSize(width: 0.2, height: 0.1),
            duration: 3.0
        )

        // Render
        renderConfirmation(confirmation)

        // Auto-dismiss after 3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.dismissConfirmation()
        }
    }

    func wakeDisplay() {
        guard currentState == .sleep else { return }

        currentState = .active

        // Restore brightness
        adjustBrightness(multiplier: 1.0)

        // Restore widget opacity
        inboxWidget?.opacity = 1.0

        // Schedule sleep
        scheduleSleep(after: 30.0)

        Logger.debug("Display woke from sleep", category: .arDisplay)
    }

    func sleepDisplay() {
        currentState = .sleep

        // Dim brightness
        adjustBrightness(multiplier: 0.5)

        // Dim widget
        inboxWidget?.opacity = 0.3

        Logger.debug("Display entered sleep", category: .arDisplay)
    }

    // MARK: - Private Methods

    private func determineDisplayMode() {
        if MetaGlassesAdapter.shared.isConnected && MetaGlassesAdapter.shared.hasDisplay {
            currentMode = .metaGlasses
        } else if ARWorldTrackingConfiguration.isSupported {
            currentMode = .arkit
        } else {
            currentMode = .disabled
        }
    }

    private func renderToMetaGlasses(_ content: ARNotificationContent) {
        Task {
            do {
                let texture = renderer.renderNotification(content)
                try await MetaGlassesAdapter.shared.renderToDisplay(texture)
                Logger.debug("✓ Rendered notification to Meta Glasses", category: .arDisplay)
            } catch {
                Logger.error("Failed to render to Meta Glasses: \(error)", category: .arDisplay)
                handleRenderingError(error)
            }
        }
    }

    private func renderToARKit(_ content: ARNotificationContent) {
        // ARKit rendering handled by ARKitSimulatorView
        NotificationCenter.default.post(
            name: .arDisplayShowNotification,
            object: content
        )
    }

    private func fallbackToVoice(_ email: WatchEmail) {
        VoiceOutputService.shared.speak("New email from \(email.sender): \(email.title)")
    }

    private func scheduleSleep(after interval: TimeInterval) {
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.sleepDisplay()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let arDisplayShowNotification = Notification.Name("ARDisplayShowNotification")
    static let arDisplayDismissNotification = Notification.Name("ARDisplayDismissNotification")
}
```

---

## Production Integration

### Integration Steps (Week 7)

#### Step 1: Initialize Service (AppDelegate)

```swift
// AppDelegate.swift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // ... existing setup ...

        // Initialize AR Display (if enabled)
        if FeatureFlags.arDisplayEnabled {
            Task { @MainActor in
                try? await ARDisplayService.shared.activateDisplay()
                Logger.info("✓ AR Display initialized", category: .app)
            }
        }

        return true
    }
}
```

**LOC**: +5 lines

---

#### Step 2: Trigger Notifications on New Urgent Emails

```swift
// EmailService.swift (existing file)

func handleNewEmail(_ email: EmailCard) async {
    // ... existing handling ...

    // Trigger AR notification if urgent
    if email.urgent == true && FeatureFlags.arDisplayEnabled {
        let watchEmail = convertToWatchEmail(email)
        await ARDisplayService.shared.showEmailNotification(watchEmail)
    }
}
```

**LOC**: +5 lines

---

#### Step 3: Update Widget After Actions

```swift
// EmailService.swift (existing file)

func archiveEmail(_ emailId: String) async -> Bool {
    let success = await performArchive(emailId)

    if success && FeatureFlags.arDisplayEnabled {
        // Update widget
        let (unread, urgent) = getInboxCounts()
        await ARDisplayService.shared.updateInboxWidget(unreadCount: unread, urgentCount: urgent)

        // Show confirmation
        await ARDisplayService.shared.showActionConfirmation(.archive)
    }

    return success
}
```

**LOC**: +8 lines

---

#### Step 4: Feature Flag in Settings

```swift
// FeatureFlags.swift (new file)

struct FeatureFlags {
    static var arDisplayEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "arDisplayEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "arDisplayEnabled")
        }
    }
}
```

**LOC**: +10 lines

---

#### Step 5: Settings UI Toggle

```swift
// SettingsView.swift (existing file)

Toggle("AR Display (Beta)", isOn: $arDisplayEnabled)
    .onChange(of: arDisplayEnabled) { enabled in
        FeatureFlags.arDisplayEnabled = enabled

        if enabled {
            Task {
                try? await ARDisplayService.shared.activateDisplay()
            }
        } else {
            ARDisplayService.shared.deactivateDisplay()
        }
    }
```

**LOC**: +12 lines

---

**Total Production Impact**: **~40 lines of code** (well under 100-line goal)

---

## Summary

### What We Built

A comprehensive **AR Display architecture** for Zer0 Inbox, enabling:
- Glanceable email notifications (5-second overlays)
- Persistent inbox count widget (always-visible)
- Visual confirmations for voice actions
- High-contrast, sunlight-readable UI
- Battery-conscious rendering with auto-sleep
- ARKit fallback for development without physical glasses

### Key Specifications

| Feature | Value |
|---------|-------|
| **Target Hardware** | Meta Oakley/Orion (45° FOV, 960x540) |
| **Development Fallback** | ARKit on iPhone/iPad |
| **Notification Duration** | 5 seconds (auto-dismiss) |
| **Widget Position** | Top-right corner (persistent) |
| **Display Sleep** | After 30 seconds inactivity |
| **Battery Drain** | ~5% per hour (glasses), ~3% per hour (iPhone) |
| **Latency** | <500ms voice command → display |
| **Production Impact** | ~40 lines of code |

### Architecture Benefits

1. **Standalone, testable**: ARDisplayService works independently, no coupling to production
2. **Fallback-ready**: ARKit simulation for development, voice-only mode if display unavailable
3. **Battery-conscious**: Auto-sleep, adaptive brightness, optimized rendering
4. **Sunlight-readable**: 2000 nits max brightness, high-contrast text, edge enhancement
5. **Voice-integrated**: Visual confirmations for voice commands, bidirectional sync

### Implementation Timeline

- **Week 5**: ARKit prototype + MetaGlassesAdapter integration + Voice integration (7 days)
- **Week 6**: Polish, optimization, testing (5 days)
- **Week 7**: Production integration (<40 lines, 2 days)

**Total**: 14 days across 3 weeks (overlaps with watchOS and EMG implementation)

---

## Next Steps

### Immediate (After This Document)

1. **Review with user**: Confirm AR display design aligns with vision
2. **Prioritize implementation**: User requested "3, 2, 1, 4" (MetaGlasses, AR Display, watchOS, tests) - this is priority 2
3. **Begin watchOS implementation**: Priority 1 per user's request

### Week 5 (When Implementation Begins)

1. Create `ARDisplayService.swift` (ARKit prototype)
2. Integrate with MetaGlassesAdapter
3. Test on iPhone with ARKit camera view

### Week 7 (Production Integration)

1. Initialize ARDisplayService in AppDelegate
2. Trigger notifications on new urgent emails
3. Update widget after actions
4. Feature flag in Settings

---

**Status**: ✅ AR Display Architecture Complete
**Next Priority**: watchOS Implementation (per user's "3, 2, 1, 4" request)
**Target Completion**: Week 7 (On Track)

---

*AR Display: See your inbox without looking at your phone.* 🥽
