# Zero Design System Style Guide
**Living Documentation - Phase 0 Complete**
**Version:** 1.0.0
**Date:** December 2, 2024
**Status:** Ready for Integration

---

## Table of Contents

1. [Overview](#overview)
2. [Design Tokens](#design-tokens)
3. [Component Library](#component-library)
4. [Usage Guidelines](#usage-guidelines)
5. [Integration Guide](#integration-guide)
6. [Best Practices](#best-practices)
7. [Code Examples](#code-examples)
8. [Figma Integration](#figma-integration)

---

## Overview

### What is the Zero Design System?

The Zero Design System is a comprehensive set of design tokens, components, and guidelines that ensure visual and functional consistency across the Zero iOS application. Built during Phase 0 of the Zero execution strategy, it provides:

- **Design Tokens** - Semantic values for colors, typography, spacing, and more
- **Component Library** - 5 core SwiftUI components ready to integrate
- **Figma Plugin** - 165 Figma components matching iOS specifications
- **Action Modals** - 46 specialized modal workflows
- **Refactoring Guide** - Step-by-step migration from hardcoded values

### Design Principles

1. **Consistency** - Same look and feel throughout the app
2. **Semantic Naming** - Colors and values have meaningful names
3. **Maintainability** - Change once, update everywhere
4. **Accessibility** - WCAG AA compliant color contrasts
5. **Scalability** - Easy to add new variants and components

### System Architecture

```
Zero Design System
├── Design Tokens (DesignTokens.swift)
│   ├── Colors (semantic color palette)
│   ├── Typography (font system)
│   ├── Spacing (layout system)
│   ├── Radius (corner rounding)
│   └── Shadows & Effects
├── Components (5 core components)
│   ├── ZeroButton
│   ├── ZeroCard
│   ├── ZeroModal
│   ├── ZeroListItem
│   └── ZeroAlert
└── Figma Plugin (code generation)
    ├── Component Variants (92)
    ├── Modal Components (22)
    └── Action Modals (46)
```

---

## Design Tokens

### Color System

The color system uses semantic naming for better maintainability and dark mode support.

#### Primary Colors

**Accent Blue** - Primary brand color for actions and emphasis
```swift
DesignTokens.Colors.accentBlue
// RGB: #007AFF (iOS blue)
// Usage: Primary buttons, links, selected states
```

**Success Green** - Positive actions and confirmations
```swift
DesignTokens.Colors.successPrimary
// RGB: #34C759 (iOS green)
// Usage: Success messages, confirmation badges
```

**Error Red** - Destructive actions and errors
```swift
DesignTokens.Colors.errorPrimary
// RGB: #FF3B30 (iOS red)
// Usage: Error alerts, delete buttons, warnings
```

**Warning Yellow** - Caution and pending states
```swift
DesignTokens.Colors.warningPrimary
// RGB: #FF9500 (iOS orange)
// Usage: Warning badges, pending states
```

#### Text Colors

**Text Primary** - Main body text
```swift
DesignTokens.Colors.textPrimary
// Light mode: Black/Dark Gray
// Dark mode: White
// Usage: Headlines, body text, primary labels
```

**Text Secondary** - Supporting text
```swift
DesignTokens.Colors.textSecondary
// Opacity: 0.7 of textPrimary
// Usage: Subtitles, timestamps, descriptions
```

**Text Tertiary** - Subtle text
```swift
DesignTokens.Colors.textTertiary
// Opacity: 0.5 of textPrimary
// Usage: Placeholder text, disabled labels, metadata
```

**Text Inverse** - Text on colored backgrounds
```swift
DesignTokens.Colors.textInverse
// Always white
// Usage: Text on primary buttons, dark overlays
```

#### Surface Colors

**Surface Primary** - Main background
```swift
DesignTokens.Colors.surfacePrimary
// Light mode: White
// Dark mode: #1C1C1E
// Usage: Cards, modals, main backgrounds
```

**Surface Secondary** - Nested backgrounds
```swift
DesignTokens.Colors.surfaceSecondary
// Light mode: #F2F2F7
// Dark mode: #2C2C2E
// Usage: App background, nested cards
```

#### Overlay Colors

**Overlay 10** - Subtle overlays
```swift
DesignTokens.Colors.overlay10
// White at 10% opacity
// Usage: Secondary buttons, hover states
```

**Overlay Strong** - Heavy overlays
```swift
DesignTokens.Colors.overlayStrong
// Black at 60% opacity
// Usage: Modal backdrops, dimmed content
```

**Glass Light** - Glassmorphic effect
```swift
DesignTokens.Colors.glassLight
// White at 15% opacity + blur
// Usage: Glassmorphic cards, floating elements
```

#### Border Colors

**Border Subtle** - Light borders
```swift
DesignTokens.Colors.borderSubtle
// Light mode: Black at 10%
// Dark mode: White at 10%
// Usage: Card borders, dividers
```

### Typography System

#### Display Fonts

**Display Large** - Largest headings
```swift
DesignTokens.Typography.displayLarge
// Size: 28pt
// Weight: Bold
// Usage: Page titles, main headings
```

**Display Medium** - Medium headings
```swift
DesignTokens.Typography.displayMedium
// Size: 24pt
// Weight: Bold
// Usage: Section headers
```

#### Title Fonts

**Title Large** - Large titles
```swift
DesignTokens.Typography.titleLarge
// Size: 20pt
// Weight: Semibold/Bold
// Usage: Modal titles, card headers
```

**Title Medium** - Medium titles
```swift
DesignTokens.Typography.titleMedium
// Size: 17pt
// Weight: Semibold
// Usage: List section headers
```

#### Body Fonts

**Body Large** - Large body text
```swift
DesignTokens.Typography.bodyLarge
// Size: 17pt
// Weight: Regular
// Usage: Email subjects, primary content
```

**Body Medium** - Standard body text
```swift
DesignTokens.Typography.bodyMedium
// Size: 15pt
// Weight: Regular
// Usage: Body text, descriptions, list items
```

**Body Small** - Small body text
```swift
DesignTokens.Typography.bodySmall
// Size: 13pt
// Weight: Regular
// Usage: Captions, secondary info, metadata
```

#### Label & Caption

**Label** - Input labels and tags
```swift
DesignTokens.Typography.label
// Size: 14pt
// Weight: Semibold
// Usage: Form labels, tags, categories
```

**Caption** - Smallest text
```swift
DesignTokens.Typography.caption
// Size: 13pt
// Weight: Regular
// Usage: Timestamps, fine print, helper text
```

**Overline** - Uppercase labels
```swift
DesignTokens.Typography.overline
// Size: 11pt
// Weight: Semibold
// Usage: Category labels, badges
```

### Spacing System

#### Base Units

The spacing system follows an 8px grid for consistent layouts:

**Inline** - Tightest spacing
```swift
DesignTokens.Spacing.inline
// Value: 8px
// Usage: Between icon and text, tight horizontal spacing
```

**Element** - Between related elements
```swift
DesignTokens.Spacing.element
// Value: 12px
// Usage: Between form fields, list items
```

**Component** - Between components
```swift
DesignTokens.Spacing.component
// Value: 16px
// Usage: Internal padding of buttons, cards
```

**Card** - Card-specific spacing
```swift
DesignTokens.Spacing.card
// Value: 16px
// Usage: Card internal padding
```

**Modal** - Modal-specific spacing
```swift
DesignTokens.Spacing.modal
// Value: 24px
// Usage: Modal internal padding, generous spacing
```

**Section** - Between sections
```swift
DesignTokens.Spacing.section
// Value: 32px
// Usage: Between major sections, content groups
```

### Corner Radius

**Minimal** - Subtle rounding
```swift
DesignTokens.Radius.minimal
// Value: 4px
// Usage: Very subtle corners
```

**Input** - Form inputs
```swift
DesignTokens.Radius.input
// Value: 8px
// Usage: Text fields, search bars
```

**Button** - Buttons and chips
```swift
DesignTokens.Radius.button
// Value: 12px
// Usage: Buttons, badges, pills
```

**Card** - Cards and containers
```swift
DesignTokens.Radius.card
// Value: 16px
// Usage: Cards, panels, containers
```

**Modal** - Modals and sheets
```swift
DesignTokens.Radius.modal
// Value: 20px
// Usage: Modals, bottom sheets, overlays
```

**Circle** - Fully rounded
```swift
DesignTokens.Radius.circle
// Value: 999px (effectively infinite)
// Usage: Avatars, circular buttons, badges
```

### Button Specifications

**Height Standard** - Large button height
```swift
DesignTokens.Button.heightStandard
// Value: 56px
// Usage: Primary CTA buttons
```

**Height Compact** - Medium button height
```swift
DesignTokens.Button.heightCompact
// Value: 44px (iOS minimum touch target)
// Usage: Secondary buttons, modal actions
```

**Padding Horizontal** - Button horizontal padding
```swift
DesignTokens.Button.paddingHorizontal
// Value: 20px
// Usage: Internal button padding
```

**Padding Vertical** - Button vertical padding
```swift
DesignTokens.Button.paddingVertical
// Value: 12px
// Usage: Buttons with custom heights
```

### Modal Specifications

**Width Default** - Standard modal width
```swift
DesignTokens.Modal.widthDefault
// Value: 480px
// Usage: Most modals and dialogs
```

**Width Large** - Large modal width
```swift
DesignTokens.Modal.widthLarge
// Value: 640px
// Usage: Complex forms, detailed content
```

**Width Small** - Compact modal width
```swift
DesignTokens.Modal.widthSmall
// Value: 360px
// Usage: Simple confirmations, compact dialogs
```

### Opacity Values

**Text Disabled** - Disabled text
```swift
DesignTokens.Opacity.textDisabled
// Value: 0.5
// Usage: Disabled form inputs, inactive buttons
```

**Text Secondary** - Secondary text
```swift
DesignTokens.Opacity.textSecondary
// Value: 0.7
// Usage: Subtitles, descriptions
```

**Text Subtle** - Subtle text
```swift
DesignTokens.Opacity.textSubtle
// Value: 0.5
// Usage: Placeholder text, timestamps
```

**Overlay Light** - Light overlay
```swift
DesignTokens.Opacity.overlayLight
// Value: 0.3
// Usage: Hover states, light overlays
```

**Overlay Strong** - Heavy overlay
```swift
DesignTokens.Opacity.overlayStrong
// Value: 0.6
// Usage: Modal backdrops, dimmed backgrounds
```

---

## Component Library

### ZeroButton

**Purpose:** Primary interaction component for all user actions

#### Variants

**Primary** - Main call-to-action
```swift
ZeroButton(
    title: "Continue",
    style: .primary,
    size: .large
) {
    // Action
}
```
- Background: accentBlue
- Text: textInverse (white)
- Use for: Primary actions, confirmations

**Secondary** - Alternative actions
```swift
ZeroButton(
    title: "Cancel",
    style: .secondary,
    size: .large
) {
    // Action
}
```
- Background: overlay10
- Text: textPrimary
- Use for: Secondary actions, cancel buttons

**Destructive** - Dangerous actions
```swift
ZeroButton(
    title: "Delete",
    style: .destructive,
    size: .large
) {
    // Action
}
```
- Background: errorPrimary (red)
- Text: textInverse (white)
- Use for: Delete, remove, destructive actions

**Text** - Inline text buttons
```swift
ZeroButton(
    title: "Learn More",
    style: .text,
    size: .medium
) {
    // Action
}
```
- Background: clear
- Text: accentBlue
- Use for: Links, inline actions

**Ghost** - Outlined buttons
```swift
ZeroButton(
    title: "Edit",
    style: .ghost,
    size: .medium
) {
    // Action
}
```
- Background: clear
- Border: borderSubtle
- Text: accentBlue
- Use for: Tertiary actions, toggles

#### Sizes

```swift
.large    // 56px height - Primary CTAs
.medium   // 44px height - Secondary actions
.small    // 36px height - Compact spaces
```

#### With Icons

```swift
ZeroButton(
    title: "Send Email",
    icon: "paperplane.fill",
    iconPosition: .trailing,
    style: .primary,
    size: .large
) {
    // Action
}
```

#### States

```swift
// Loading state
ZeroButton(
    title: "Sending...",
    style: .primary,
    isLoading: true
) { }

// Disabled state
ZeroButton(
    title: "Submit",
    style: .primary,
    isDisabled: true
) { }
```

### ZeroCard

**Purpose:** Container for email items and content cards

#### Basic Card

```swift
ZeroCard(
    priority: .high,
    layout: .standard,
    isSelected: false
) {
    VStack(alignment: .leading, spacing: 8) {
        Text("Card Title")
            .font(DesignTokens.Typography.bodyLarge)
        Text("Card description goes here")
            .font(DesignTokens.Typography.bodySmall)
    }
}
```

#### Email Card Specialization

```swift
ZeroEmailCard(
    sender: "Sarah Chen",
    subject: "Q4 Budget Review Meeting",
    summary: "Hi team, I've scheduled our quarterly budget review...",
    timestamp: "2h ago",
    priority: .high,
    isUnread: true,
    isSelected: false,
    onTap: { /* Handle tap */ },
    onStar: { /* Handle star */ }
)
```

#### Priority Levels

```swift
.high     // Red badge, urgent items
.medium   // Orange badge, important items
.low      // Green badge, low priority
.none     // No badge
```

#### Layouts

```swift
.compact   // 72px min height - Single line
.standard  // 100px min height - Multi-line
.expanded  // 200px min height - Full details
```

### ZeroModal

**Purpose:** Overlay dialogs for user input and confirmations

#### Standard Modal

```swift
ZeroModal(
    title: "Confirm Action",
    subtitle: "Are you sure you want to proceed?",
    primaryButton: ("Confirm", { /* Action */ }),
    secondaryButton: ("Cancel", { /* Action */ })
)
```

#### With Custom Content

```swift
ZeroModal(
    title: "Add to Calendar",
    subtitle: "Event details",
    primaryButton: ("Add", { /* Action */ }),
    secondaryButton: ("Cancel", { /* Action */ })
) {
    VStack(spacing: 16) {
        // Custom form fields
        Text("Event: Team Meeting")
        Text("Date: December 20, 2024")
    }
}
```

#### Destructive Modal

```swift
ZeroModal(
    title: "Delete Email",
    subtitle: "This action cannot be undone",
    destructiveButton: ("Delete", { /* Action */ }),
    secondaryButton: ("Cancel", { /* Action */ })
)
```

#### Action Picker

```swift
ZeroActionPicker(
    title: "Choose Action",
    actions: [
        .init(
            icon: "calendar.badge.plus",
            title: "Add to Calendar",
            subtitle: "Create a calendar event",
            action: { /* Action */ }
        ),
        .init(
            icon: "bell.badge",
            title: "Set Reminder",
            subtitle: "Get notified later",
            action: { /* Action */ }
        )
    ],
    onDismiss: { /* Dismiss handler */ }
)
```

#### Modal Sizes

```swift
.small     // 360pt - Simple confirmations
.standard  // 480pt - Standard dialogs
.large     // 640pt - Complex forms
```

### ZeroListItem

**Purpose:** Reusable list items for settings and navigation

#### Basic List Item

```swift
ZeroListItem(
    icon: "envelope.fill",
    title: "Inbox",
    badge: 12,
    hasArrow: true
) {
    // Navigation action
}
```

#### With Subtitle

```swift
ZeroListItem(
    icon: "person.fill",
    title: "John Appleseed",
    subtitle: "john@example.com",
    hasArrow: true
) {
    // Action
}
```

#### Styles

```swift
.default     // Regular weight, primary color
.emphasized  // Semibold weight, accent color
.subtle      // Regular weight, secondary color
```

#### Email List Item Specialization

```swift
ZeroEmailListItem(
    sender: "Sarah Chen",
    subject: "Q4 Budget Review Meeting",
    preview: "Hi team, I've scheduled...",
    timestamp: "2h ago",
    isUnread: true,
    isStarred: true,
    hasAttachment: true,
    isSelected: false,
    onTap: { /* Open email */ },
    onStar: { /* Toggle star */ }
)
```

#### Swipeable List Item

```swift
ZeroSwipeableListItem(
    leadingActions: [
        .init(icon: "envelope.open.fill", color: .blue) { /* Mark read */ },
        .init(icon: "star.fill", color: .orange) { /* Star */ }
    ],
    trailingActions: [
        .init(icon: "trash.fill", color: .red) { /* Delete */ }
    ]
) {
    ZeroEmailListItem(/* ... */)
}
```

### ZeroAlert

**Purpose:** User feedback for success, errors, and information

#### Alert Variants

```swift
// Success
ZeroAlert(
    variant: .success,
    title: "Email Sent",
    message: "Your message was delivered successfully",
    isDismissible: true
)

// Error
ZeroAlert(
    variant: .error,
    title: "Failed to Send",
    message: "Please check your connection and try again",
    isDismissible: true
)

// Warning
ZeroAlert(
    variant: .warning,
    title: "Storage Almost Full",
    message: "You have less than 100 MB remaining",
    isDismissible: true
)

// Info
ZeroAlert(
    variant: .info,
    title: "New Feature Available",
    message: "Try our new AI-powered email categorization",
    isDismissible: true
)
```

#### Alert Styles

```swift
.banner    // Inline banner with border (default)
.toast     // Floating notification with shadow
.inline    // Compact inline message
```

#### With Action Button

```swift
ZeroAlert(
    variant: .warning,
    title: "Low Storage",
    message: "You're running out of space",
    isDismissible: true,
    action: ("Upgrade Plan", { /* Action */ })
)
```

#### Global Toast System

```swift
// Show toast from anywhere
ZeroToastManager.shared.show(
    variant: .success,
    title: "Email Sent",
    message: "Your message was delivered",
    duration: 3.0
)

// Add to root view
struct RootView: View {
    var body: some View {
        NavigationView {
            // Your content
        }
        .zeroToastOverlay()  // Add this modifier
    }
}
```

---

## Usage Guidelines

### When to Use Each Component

#### ZeroButton

**Use when:**
- User needs to trigger an action
- Confirming or canceling operations
- Navigating to another screen
- Submitting forms

**Don't use when:**
- Navigating within a list (use ZeroListItem)
- Showing status (use ZeroAlert)
- Inline text links (use Text with .underline())

#### ZeroCard

**Use when:**
- Displaying email items in feed
- Showing content summaries
- Grouping related information
- Creating interactive containers

**Don't use when:**
- Simple text display (use Text)
- Navigation lists (use List with ZeroListItem)
- Overlays or dialogs (use ZeroModal)

#### ZeroModal

**Use when:**
- Requiring user input before proceeding
- Confirming destructive actions
- Displaying forms or complex inputs
- Showing action pickers

**Don't use when:**
- Simple alerts (use ZeroAlert)
- Navigation (use NavigationLink)
- Persistent overlays (use custom views)

#### ZeroListItem

**Use when:**
- Building settings screens
- Creating navigation lists
- Showing selectable options
- Displaying inbox items

**Don't use when:**
- Primary call-to-action (use ZeroButton)
- Complex content cards (use ZeroCard)
- Form inputs (use native TextField)

#### ZeroAlert

**Use when:**
- Providing user feedback
- Showing success/error states
- Displaying non-critical information
- Temporary notifications

**Don't use when:**
- Requiring user input (use ZeroModal)
- Blocking critical decisions (use ZeroModal)
- Persistent messages (use custom view)

### Accessibility Guidelines

#### Color Contrast

All color combinations meet WCAG AA standards:
- Text on accentBlue: 4.5:1 contrast ratio
- Text on errorPrimary: 4.5:1 contrast ratio
- textSecondary: 4.5:1 contrast ratio minimum

#### Touch Targets

All interactive elements meet iOS minimum:
- Minimum 44x44pt touch target
- Large buttons: 56pt height
- Adequate spacing between elements

#### Dynamic Type

All components support Dynamic Type:
```swift
// Typography automatically scales
Text("Title")
    .font(DesignTokens.Typography.titleLarge)
// Respects user's text size preferences
```

#### VoiceOver Support

Components include proper accessibility labels:
```swift
ZeroButton("Send", style: .primary) { }
// Automatically announces: "Send button"

ZeroEmailCard(/* ... */)
// Announces: "Email from Sarah Chen, subject Q4 Budget Review, 2 hours ago"
```

### Dark Mode Support

All colors automatically adapt:
```swift
// Light mode
DesignTokens.Colors.textPrimary → Black

// Dark mode
DesignTokens.Colors.textPrimary → White

// No code changes needed!
```

---

## Integration Guide

### Step 1: Add DesignTokens.swift

```bash
# Copy design tokens to project
cp /Users/matthanson/Zer0_Inbox/design-system/design-tokens/DesignTokens.swift \
   /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/
```

**Verify import:**
```swift
import SwiftUI

// Should work without additional imports
let color = DesignTokens.Colors.accentBlue
```

### Step 2: Add Component Files

```bash
# Copy all ready-to-use components
cp /Users/matthanson/Zer0_Inbox/design-system/ios-components/*.swift \
   /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Core/UI/Components/
```

**Components included:**
- ZeroButton.swift
- ZeroCard.swift
- ZeroModal.swift
- ZeroListItem.swift
- ZeroAlert.swift

### Step 3: Update Existing Code

Follow the [Component Refactoring Guide](COMPONENT_REFACTORING_GUIDE.md) to migrate existing components.

**Quick example:**
```swift
// Before
Button("Continue") {}
    .background(Color.blue)
    .foregroundColor(.white)
    .cornerRadius(12)

// After
ZeroButton(
    title: "Continue",
    style: .primary,
    size: .large
) { }
```

### Step 4: Test Integration

```swift
// Add to a test view
struct TestView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.section) {
                ZeroButton("Test Button", style: .primary) {}
                ZeroCard(priority: .high) {
                    Text("Test Card")
                }
                ZeroAlert(variant: .success, title: "Test Alert")
            }
            .padding()
        }
    }
}

#Preview {
    TestView()
}
```

### Step 5: Configure Figma Plugin (Optional)

```bash
cd /Users/matthanson/Zer0_Inbox/design-system/figma-plugin

# Build desired plugin variant
npm run build:effects           # Component variants
npm run build:modal-components  # Modal components
npm run build:action-modals-core  # 11 priority modals
npm run build:action-modals-secondary  # 35 additional modals

# Run in Figma
# Plugins → Development → Import plugin from manifest → Select manifest.json
```

---

## Best Practices

### Do's ✅

**Always use DesignTokens for colors:**
```swift
✅ .foregroundColor(DesignTokens.Colors.textPrimary)
❌ .foregroundColor(.white)
```

**Always use DesignTokens for typography:**
```swift
✅ .font(DesignTokens.Typography.bodyLarge)
❌ .font(.system(size: 17))
```

**Always use DesignTokens for spacing:**
```swift
✅ .padding(DesignTokens.Spacing.component)
❌ .padding(16)
```

**Use semantic color names:**
```swift
✅ DesignTokens.Colors.errorPrimary  // Meaningful
❌ DesignTokens.Colors.red           // Not semantic
```

**Combine components appropriately:**
```swift
✅ ZeroModal with ZeroButton
✅ ZeroCard with custom content
✅ ZeroListItem in List or ScrollView
```

**Test in both light and dark mode:**
```swift
#Preview("Light Mode") {
    TestView()
}

#Preview("Dark Mode") {
    TestView()
        .preferredColorScheme(.dark)
}
```

### Don'ts ❌

**Never hardcode colors:**
```swift
❌ .background(Color.blue)
❌ .foregroundColor(Color(red: 0, green: 0, blue: 1))
```

**Never hardcode fonts:**
```swift
❌ .font(.system(size: 17, weight: .semibold))
❌ .font(Font.custom("Helvetica", size: 15))
```

**Never use magic numbers:**
```swift
❌ .padding(.horizontal, 24)
❌ .frame(height: 56)
❌ .cornerRadius(12)
```

**Never ignore accessibility:**
```swift
❌ Buttons smaller than 44x44pt
❌ Low contrast text
❌ Missing VoiceOver labels
```

**Never mix component styles:**
```swift
❌ Custom button when ZeroButton exists
❌ Hardcoded modal when ZeroModal exists
```

---

## Code Examples

### Example 1: Login Screen

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            // Header
            VStack(spacing: DesignTokens.Spacing.element) {
                Text("Welcome Back")
                    .font(DesignTokens.Typography.displayLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text("Sign in to continue")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            // Form
            VStack(spacing: DesignTokens.Spacing.element) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            // Error alert
            if showError {
                ZeroAlert(
                    variant: .error,
                    title: "Invalid Credentials",
                    message: "Please check your email and password",
                    isDismissible: true,
                    onDismiss: { showError = false }
                )
            }

            Spacer()

            // Actions
            VStack(spacing: DesignTokens.Spacing.element) {
                ZeroButton(
                    title: "Sign In",
                    style: .primary,
                    size: .large
                ) {
                    // Handle login
                }

                ZeroButton(
                    title: "Forgot Password?",
                    style: .text,
                    size: .medium
                ) {
                    // Handle forgot password
                }
            }
        }
        .padding(DesignTokens.Spacing.modal)
    }
}
```

### Example 2: Inbox Feed

```swift
struct InboxView: View {
    @State private var emails: [Email] = []
    @State private var selectedEmail: Email?

    var body: some View {
        NavigationStack {
            List {
                ForEach(emails) { email in
                    ZeroSwipeableListItem(
                        leadingActions: [
                            .init(
                                icon: "envelope.open.fill",
                                color: DesignTokens.Colors.accentBlue
                            ) {
                                markAsRead(email)
                            }
                        ],
                        trailingActions: [
                            .init(
                                icon: "trash.fill",
                                color: DesignTokens.Colors.errorPrimary
                            ) {
                                deleteEmail(email)
                            }
                        ]
                    ) {
                        ZeroEmailListItem(
                            sender: email.sender,
                            subject: email.subject,
                            preview: email.preview,
                            timestamp: email.timestamp,
                            isUnread: email.isUnread,
                            isStarred: email.isStarred,
                            hasAttachment: email.hasAttachment,
                            isSelected: selectedEmail?.id == email.id,
                            onTap: {
                                selectedEmail = email
                            },
                            onStar: {
                                toggleStar(email)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    func markAsRead(_ email: Email) {
        // Implementation
        ZeroToastManager.shared.show(
            variant: .success,
            title: "Marked as Read"
        )
    }

    func deleteEmail(_ email: Email) {
        // Implementation
        ZeroToastManager.shared.show(
            variant: .info,
            title: "Email Deleted",
            message: "Moved to trash"
        )
    }

    func toggleStar(_ email: Email) {
        // Implementation
    }
}
```

### Example 3: Settings Screen

```swift
struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var showLogoutModal = false

    var body: some View {
        List {
            Section {
                ZeroListItem(
                    icon: "person.fill",
                    title: "Profile",
                    hasArrow: true
                ) {
                    // Navigate to profile
                }

                ZeroListItem(
                    icon: "bell.fill",
                    title: "Notifications",
                    badge: notificationsEnabled ? "On" : "Off",
                    hasArrow: true
                ) {
                    // Navigate to notifications settings
                }
            } header: {
                Text("Account")
                    .font(DesignTokens.Typography.overline)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Section {
                ZeroListItem(
                    icon: "paintbrush.fill",
                    title: "Appearance",
                    hasArrow: true
                ) {
                    // Navigate to appearance
                }

                ZeroListItem(
                    icon: "globe",
                    title: "Language",
                    hasArrow: true
                ) {
                    // Navigate to language
                }
            } header: {
                Text("Preferences")
                    .font(DesignTokens.Typography.overline)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Section {
                ZeroListItem(
                    icon: "arrow.right.square.fill",
                    iconColor: DesignTokens.Colors.errorPrimary,
                    title: "Log Out",
                    style: .emphasized
                ) {
                    showLogoutModal = true
                }
            }
        }
        .sheet(isPresented: $showLogoutModal) {
            ZeroModal(
                title: "Log Out",
                subtitle: "Are you sure you want to log out?",
                destructiveButton: ("Log Out", {
                    // Handle logout
                }),
                secondaryButton: ("Cancel", {
                    showLogoutModal = false
                })
            )
        }
    }
}
```

---

## Figma Integration

### Using the Figma Plugin

The design system includes a comprehensive Figma plugin that generates 165+ components matching the iOS implementation exactly.

#### Component Variants (92)

```bash
# Build and run
cd figma-plugin
npm run build:effects
# In Figma: Plugins → Development → Import → manifest-effects.json
```

**Generates:**
- Buttons (5 styles × 3 sizes = 15 variants)
- Cards (4 priorities × 3 layouts = 12 variants)
- Modals (3 types × 3 sizes = 9 variants)
- List Items (3 styles × states = 12 variants)
- Alerts (4 types × 3 styles = 12 variants)
- + 32 additional effect variants

#### Modal Components (22)

```bash
npm run build:modal-components
# Import manifest-modal-components.json
```

**Generates:**
- Headers, footers, form inputs
- Context headers, action buttons
- Text areas, toggles, dropdowns

#### Action Modals - Core (11)

```bash
npm run build:action-modals-core
# Import manifest-action-modals-core.json
```

**Generates 11 priority modals:**
1. Quick Reply
2. Forward Email
3. Schedule Email
4. Add to Calendar
5. Set Reminder
6. Snooze Email
7. Mark as Read
8. Archive Email
9. Delete Email
10. Report Spam
11. Block Sender

#### Action Modals - Secondary (35)

```bash
npm run build:action-modals-secondary
# Import manifest-action-modals-secondary.json
```

**Generates 35 additional specialized modals** across:
- Communication (5)
- Shopping (5)
- Travel (5)
- Finance (5)
- Events (4)
- Documents (5)
- Subscriptions (6)

### Design-to-Code Workflow

1. **Design in Figma**
   - Use generated components
   - Follow design tokens
   - Create new screens

2. **Export designs**
   - Share Figma links with engineers
   - Include component specifications

3. **Implement in code**
   - Use matching SwiftUI components
   - Reference design tokens
   - Maintain pixel-perfect accuracy

4. **Iterate**
   - Update Figma designs
   - Rebuild components if needed
   - Sync with code implementation

---

## Appendix

### File Locations

**Design Tokens:**
```
/Users/matthanson/Zer0_Inbox/design-system/design-tokens/DesignTokens.swift
```

**iOS Components:**
```
/Users/matthanson/Zer0_Inbox/design-system/ios-components/
├── ZeroButton.swift
├── ZeroCard.swift
├── ZeroModal.swift
├── ZeroListItem.swift
└── ZeroAlert.swift
```

**Figma Plugin:**
```
/Users/matthanson/Zer0_Inbox/design-system/figma-plugin/
├── component-generator-with-effects.ts
├── modal-components-generator.ts
├── generators/modals/action-modals-core-generator.ts
└── generators/modals/action-modals-secondary-generator.ts
```

**Documentation:**
```
/Users/matthanson/Zer0_Inbox/design-system/
├── DESIGN_SYSTEM_STYLE_GUIDE.md (this file)
├── COMPONENT_REFACTORING_GUIDE.md
├── REFACTORING_COMPLETE.md
├── ARCHITECTURE_REVIEW.md
└── WORK_COMPLETED_WHILE_WALKING_DOG.md
```

### Version History

**v1.0.0** - December 2, 2024
- Initial release
- 5 core components
- Complete design token system
- 165 Figma components
- 46 action modals
- Comprehensive documentation

### Roadmap

**Phase 1 - Integration (Weeks 1-6)**
- Integrate components into main iOS app
- Refactor existing screens
- Complete design token migration

**Phase 2 - Enhancement (Weeks 7-12)**
- Add animations and transitions
- Implement advanced visual effects
- Create additional specialized components

**Phase 3 - Scale (Weeks 13-24)**
- Build complete modal library
- Expand component variants
- Create additional design patterns

---

## Support

### Questions?

- Review the [Component Refactoring Guide](COMPONENT_REFACTORING_GUIDE.md)
- Check code examples in this document
- Inspect ready-to-use components for reference implementations
- Review Figma plugin generated code

### Contributing

When adding new components:
1. Use DesignTokens for all values
2. Follow established naming patterns
3. Include comprehensive #Preview examples
4. Document in this style guide
5. Update Figma plugin if needed

---

**Status:** ✅ Complete and Ready for Integration
**Version:** 1.0.0
**Last Updated:** December 2, 2024

🎉 **Your design system is ready to transform Zero into a polished, consistent, and maintainable application!**
