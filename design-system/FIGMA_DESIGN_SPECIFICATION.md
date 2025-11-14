# Zero Inbox - Complete Figma Design Specification

**Date:** November 10, 2025
**Scope:** All 169 actions, email viewer, and UI components
**Status:** Ready for Figma implementation

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [Design System Foundation](#design-system-foundation)
3. [Action Flow Patterns](#action-flow-patterns)
4. [Email Viewer Design](#email-viewer-design)
5. [Modal Library (30+ Modals)](#modal-library)
6. [Component Library](#component-library)
7. [Implementation Guide](#implementation-guide)

---

## Executive Summary

### What to Build in Figma

**169 Actions** organized into 6 categories:
- 🔥 High-Fidelity Actions (6 premium modals)
- 📧 Mail Mode Actions (40 actions)
- 🛍️ Ads Mode Actions (28 actions)
- ✅ Quick Actions (35 actions)
- 🔗 GO_TO Actions (30 actions)
- 🌐 Universal Actions (30 actions)

**Core UI Components:**
- Email Viewer (full-screen)
- Action Cards (8 priority levels)
- 30+ Modal Templates
- Buttons, inputs, progress indicators
- Toast/Undo system

---

## Design System Foundation

### Resolved: Gradient Colors

✅ **Canonical Gradients** (from iOS):
```
Mail Archetype:  #667eea → #764ba2 (Blue → Purple)
Ads Archetype:   #16bbaa → #4fd19e (Teal → Green)
```

**Update Figma:**
1. Navigate to: 🎨 Design System Components → 🎨 Archetypes
2. Change Mail gradient: Start #667eea, End #764ba2
3. Change Ads gradient: Start #16bbaa, End #4fd19e

### Priority System (8 Levels)

All actions have semantic priorities:

| Priority | Value | Color | Usage |
|----------|-------|-------|-------|
| Critical | 95 | Red | Life-critical, legal, high-stakes financial |
| Very High | 90 | Orange | Time-sensitive, urgent actions |
| High | 85 | Yellow | Important but not urgent |
| Medium-High | 80 | Green | Useful with moderate impact |
| Medium | 75 | Cyan | Standard actions |
| Medium-Low | 70 | Blue | Helpful but not essential |
| Low | 65 | Purple | Nice-to-have |
| Very Low | 60 | Gray | Utility, fallbacks |

---

## Action Flow Patterns

### Pattern 1: High-Fidelity Premium Modals

**6 Actions** with full-screen, rich modals (require premium):

1. **Track Package** (Very High Priority)
   - Full modal with carrier logo
   - Tracking timeline visualization
   - Current status, ETA
   - Context: trackingNumber, carrier, url, expectedDelivery

2. **Pay Invoice** (Critical Priority)
   - Payment amount (large, prominent)
   - Merchant info
   - Due date countdown
   - Confirmation + Undo pattern
   - Context: invoiceId, amount, merchant, paymentLink, dueDate

3. **Check In Flight** (Critical Priority)
   - Flight number, airline logo
   - Departure time, gate, seat
   - Check-in button (large CTA)
   - Context: flightNumber, airline, checkInUrl, departureTime, gate

4. **Write Review** (Medium-Low Priority)
   - Product name/image
   - Star rating (1-5)
   - Text input area
   - Context: productName, reviewLink, orderNumber, productImage

5. **Contact Driver** (High Priority)
   - Driver name, photo
   - Phone number (tap to call)
   - Vehicle info, ETA
   - Context: driverName, driverPhone, vehicleInfo, eta

6. **View Pickup Details** (Medium-High Priority)
   - Pharmacy name, address
   - Prescription number
   - Hours, phone (tap to call/navigate)
   - Context: pharmacy, rxNumber, address, phone, hours

**Figma Components Needed:**
- 6 unique full-screen modal templates
- Premium badge indicators
- Rich media (logos, photos, maps)
- Large CTAs with gradients

---

### Pattern 2: Standard In-App Modals

**~40 Modal Actions** with focused, single-purpose UI:

#### Category: Calendar & Scheduling
- Add to Calendar
- Schedule Meeting
- Schedule Appointment
- Confirm Appointment
- Reschedule Appointment
- Check In Appointment

**Modal Design:**
- Title: Action name
- Context section: Date/time picker, attendees, location
- Primary CTA (Mail gradient button)
- Secondary: Cancel

#### Category: Communication
- Quick Reply
- Reply
- Reply Thanks
- Reply to Thread
- Send Message
- Contact Support

**Modal Design:**
- Recipient info
- Subject line (pre-filled)
- Message body (quick templates or freeform)
- Send button (Mail gradient)

#### Category: Tasks & Reminders
- Add Reminder
- Set Reminder
- Set Payment Reminder
- Delegate
- Add to Notes

**Modal Design:**
- Title input
- Due date/time picker
- Notes/description
- Priority selector
- Save button

#### Category: Shopping & Commerce
- Complete Cart
- Buy Again
- Reorder Item
- Add to Cart
- Add to Wallet
- Shop Now

**Modal Design:**
- Product name/image
- Price
- Quantity selector
- Add to Cart/Buy Now (Ads gradient button)

#### Category: Financial
- Pay Utility Bill
- Pay Property Tax
- Schedule Payment
- Update Payment Method
- Pay Form Fee

**Modal Design:**
- Amount (large, bold)
- Payee name
- Due date
- Payment method selector
- Pay Now button (Critical styling)

#### Category: Document Management
- Sign Form
- Download Attachment
- Download Receipt
- Download Tax Document
- View Document

**Modal Design:**
- Document preview
- File name, size
- Download/Sign button
- Share options

#### Category: Subscriptions
- Manage Subscription
- Cancel Subscription
- Extend Trial
- Upgrade Subscription

**Modal Design:**
- Current plan details
- Billing info
- Next bill date
- Action button (Cancel/Upgrade)

**Figma Components Needed:**
- Base modal template (adaptive)
- Date/time pickers
- Text input fields
- Dropdown selectors
- File preview components
- Template message bubbles

---

### Pattern 3: Quick Actions (Toast + Undo)

**~35 Actions** with optimistic execution (Raya/Hinge pattern):

- Unsubscribe
- Save for Later
- Save Contact
- Add Activity to Calendar
- Apply for Permit
- Register Event
- RSVP Yes/No
- Rate Product
- Claim Deal

**UX Flow:**
1. User taps action
2. Action executes immediately
3. Toast appears at bottom with "Undo" button
4. Progress bar shows 10s countdown
5. After 10s, action commits

**Toast Variants:**
- **Progress Bar Style** (default)
  - Linear progress bar at bottom
  - Message + Undo button

- **Circular Ring Style** (premium feel)
  - Circular progress around Undo button
  - Animated countdown

- **Numeric Style** (explicit)
  - Large countdown number (10, 9, 8...)
  - Message + Undo button

**Figma Components Needed:**
- Toast container (bottom-aligned)
- 3 progress indicator variants
- Undo button (prominent)
- Success/error states

---

### Pattern 4: GO_TO Actions (External Links)

**~30 Actions** that open Safari or external apps:

- Open Link
- Open App
- Get Directions
- Join Meeting
- View Itinerary
- Browse Shopping
- View Product
- Track Delivery

**UX Flow:**
1. User taps action card
2. Brief loading indicator
3. App opens Safari/external app
4. Bounce back to Zero after external action

**No Modal Needed** - just visual feedback:
- Action card press state
- Brief spinner
- Fade to external app

**Figma Components Needed:**
- Action card with "External Link" indicator
- Loading spinner overlay
- Press state animation

---

## Email Viewer Design

### Full-Screen Email View

**Layout Hierarchy:**

```
┌─────────────────────────────────┐
│ Header (Fixed)                  │
│  ← Back    [Avatar]  Subject    │
│  Priority Badge  | Context Badge│
├─────────────────────────────────┤
│                                 │
│ Metadata Bar                    │
│ From: Name                      │
│ To: Me                          │
│ Date: Nov 10, 9:41 AM          │
│ Priority: HIGH PRIORITY (85)    │
│                                 │
├─────────────────────────────────┤
│                                 │
│ Email Body                      │
│ (Scrollable)                    │
│                                 │
│ Lorem ipsum dolor sit amet...   │
│ consectetur adipiscing elit...  │
│                                 │
│ [Extracted Key Info Cards]     │
│ 📅 Deadline: Friday, Nov 10    │
│                                 │
├─────────────────────────────────┤
│ Action Bar (Fixed Bottom)       │
│ ┌───────────────────────────┐  │
│ │ ✓ Primary Action          │  │
│ └───────────────────────────┘  │
│ [Archive] [Snooze] [•••]       │
└─────────────────────────────────┘
```

### Components

#### 1. Header
- Back button (←)
- Avatar (circular, 40px)
- Subject line (truncated, bold)
- Priority badge (colored chip)
- Context badge (white pill)

#### 2. Metadata Bar
- From: Sender name (bold) + email (gray)
- To: Recipient (Me, or full email)
- Date/Time: Relative (2h ago) or absolute
- Priority indicator with icon (⚠️ HIGH PRIORITY)

#### 3. Email Body
- Typography: 15px body text
- Line height: 1.5
- Padding: 20px horizontal
- Links: Blue, underlined
- Extracted info cards: Elevated cards with key details

#### 4. Extracted Key Info Cards
**Design:** Small cards embedded in email body
- Icon (📅 calendar, 💰 money, 📦 package)
- Title (bold): "Deadline", "Amount Due", "Tracking #"
- Value (large): "Friday, Nov 10 at 5:00 PM"
- Subtle background (white with 5% opacity)

#### 5. Action Bar (Bottom)
- **Primary Action Button:**
  - Full width
  - Mail gradient (blue → purple)
  - Height: 56px
  - Text: Action name (e.g., "Acknowledge & Schedule Review")
  - Icon: Checkmark (✓)

- **Secondary Actions:**
  - Archive button (icon only)
  - Snooze button (icon only)
  - More menu (•••)

**Figma Pages Needed:**
- Email Viewer Template (full screen)
- Email variants:
  - Critical priority email
  - High priority email
  - Standard email
  - Email with extracted cards
  - Email with attachments
  - Thread view (expanded messages)

---

## Modal Library

### 30+ Modal Templates Needed

Organize in Figma as **Components** with **Variants**:

#### Base Modal Anatomy
```
┌─────────────────────────────────┐
│  Modal Container (90% width)    │
│  Border Radius: 20px            │
│  Padding: 24px                  │
│  Background: Glassmorphic       │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Icon (48px, circular)   │   │
│  │ Title (20px, bold)       │   │
│  │ Description (15px, gray) │   │
│  └─────────────────────────┘   │
│                                 │
│  [Context Section]              │
│  Input fields / Info display    │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Primary Action (Gradient)│   │
│  └─────────────────────────┘   │
│  Cancel (text link)             │
└─────────────────────────────────┘
```

#### Modal Variants by Action Type

**1. Track Package Modal**
- Carrier logo (top)
- Tracking number (large, monospace)
- Status timeline (vertical, with checkmarks)
- ETA (highlighted)
- "Track on Carrier Website" button

**2. Pay Invoice Modal**
- Amount (HUGE, center)
- Merchant name + logo
- Due date countdown
- Payment method selector
- "Pay $XXX" button (critical color)

**3. Quick Reply Modal**
- To: field (pre-filled)
- Subject: field (pre-filled from thread)
- Message: textarea with templates
- Template shortcuts ("Yes", "Thanks", "Confirmed")
- Send button

**4. Add to Calendar Modal**
- Event title input
- Date picker
- Time picker
- Location input (optional)
- "Add to Calendar" button

**5. Sign Form Modal**
- Document preview (scrollable)
- Signature pad (canvas)
- Typed signature option
- "Sign & Submit" button

**6. Schedule Meeting Modal**
- Title input
- Attendees (multi-select)
- Date/time picker
- Duration selector (30min, 1hr, 2hr)
- "Schedule" button

... *28 more modal templates* (see full list in ActionRegistry)

**Figma Organization:**
```
Components/
  Modals/
    _Base/
      BaseModal (master component)
      ModalHeader
      ModalBody
      ModalFooter
    TrackPackage/
      TrackPackageModal
      TrackingTimeline
    PayInvoice/
      PayInvoiceModal
      PaymentMethodSelector
    QuickReply/
      QuickReplyModal
      TemplateChips
    ... (30 more)
```

---

## Component Library

### Atoms

**Buttons:**
- Primary Gradient (Mail: blue→purple)
- Ads Gradient (teal→green)
- Lifestyle Gradient (purple→pink)
- Shop Gradient (green→emerald)
- Urgent Gradient (orange→yellow)
- Secondary (gray outline)
- Destructive (red)
- Text Link

Variants: Standard (56px), Compact (44px), Small (32px)

**Inputs:**
- Text input (default, focused, error states)
- Textarea
- Date picker
- Time picker
- Dropdown select
- Checkbox
- Radio button
- Toggle switch

**Chips/Pills:**
- Priority badges (8 color variants)
- Context badges (white pill)
- Status tags (success, error, warning, info)

**Progress Indicators:**
- Linear progress bar
- Circular progress ring
- Numeric countdown
- Spinner/loading

**Icons:**
- SF Symbols style
- 20px standard, 24px large, 16px small
- All action icons (169 unique icons)

### Molecules

**Action Card:**
```
┌─────────────────────────────────┐
│ 〇  Title (15px, bold)          │
│     Description (12px, gray)    │
│     [Priority Badge]        →   │
└─────────────────────────────────┘
```

Variants: 8 priority levels (critical to very low)

**Undo Toast:**
- Message text
- Undo button (prominent)
- Progress indicator (3 styles)
- Close button (×)

**Email List Item:**
```
┌─────────────────────────────────┐
│ [Avatar] Sender Name            │
│          Subject (truncated)    │
│          Preview text...        │
│          Priority | Context     │
└─────────────────────────────────┘
```

**Extracted Info Card:**
```
┌─────────────────────────────────┐
│ 📅 Deadline                     │
│    Friday, November 10 at 5PM   │
└─────────────────────────────────┘
```

### Organisms

**Email Viewer** (see above)

**Action Bar** (bottom fixed):
- Primary action button
- Secondary actions (archive, snooze)
- More menu

**Modal Container:**
- Backdrop (50% black)
- Modal card (glassmorphic)
- Close button (×)

**Navigation:**
- Tab bar (Mail | Ads)
- Settings/profile icons

---

## Implementation Guide

### Phase 1: Foundation (Week 1)

**Goals:**
1. ✅ Fix gradient colors in Figma
2. Create design token library (colors, spacing, typography)
3. Set up component structure

**Deliverables:**
- Updated 🎨 Archetypes page
- Color styles (all colors as Figma styles)
- Text styles (all typography as Figma styles)
- Component naming system

### Phase 2: Core Components (Week 2)

**Goals:**
1. Build all atomic components (buttons, inputs, badges)
2. Create 8 priority variants for action cards
3. Build toast/undo system

**Deliverables:**
- Button library (5 gradient variants + 3 sizes)
- Input library (all form elements)
- Action card component with 8 priority variants
- Toast component with 3 progress styles

### Phase 3: Email Viewer (Week 3)

**Goals:**
1. Design full email viewer template
2. Create email variants (5 examples)
3. Build extracted info cards

**Deliverables:**
- Email Viewer template (full frame)
- 5 email examples (different priorities/types)
- Extracted card components
- Action bar component

### Phase 4: Modal Library (Week 4-6)

**Goals:**
1. Build base modal component
2. Create 30+ modal templates
3. Document each modal's context requirements

**Deliverables:**
- Base modal (master component)
- 6 high-fidelity premium modals
- 30+ standard modal templates
- Modal documentation page

### Phase 5: Action Flows (Week 7-8)

**Goals:**
1. Create user flow diagrams for each action
2. Document edge cases (errors, loading, success)
3. Create prototype interactions

**Deliverables:**
- Flow diagrams for all 169 actions
- Error state designs
- Loading state designs
- Success/confirmation designs
- Figma prototypes (clickable flows)

### Phase 6: Polish & Handoff (Week 9-10)

**Goals:**
1. Responsive layouts (iPhone sizes)
2. Dark mode variants (future)
3. Developer handoff documentation

**Deliverables:**
- iPhone 15, 15 Pro Max layouts
- Dev handoff with Inspect panel
- Component usage documentation
- Design system style guide

---

## Quick Start Checklist

### Immediate Actions

- [ ] **Fix gradients in Figma:**
  - Mail: #667eea → #764ba2
  - Ads: #16bbaa → #4fd19e

- [ ] **Re-run token sync:**
  ```bash
  cd design-system/sync
  node sync-all.js
  ```

- [ ] **Create Figma pages:**
  - Foundation (design tokens)
  - Components (atoms, molecules, organisms)
  - Email Viewer
  - Modal Library
  - Action Flows
  - Prototypes

### Priority Components to Build First

**High Impact, Low Effort:**
1. Action Card (with 8 priority variants)
2. Gradient buttons (5 variants)
3. Email Viewer template
4. Base modal template
5. Toast/Undo component

**These 5 components cover 80% of the UI** and unblock development.

---

## Reference Files

- **ActionRegistry.swift**: `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Services/ActionRegistry.swift` (3163 lines, 169 actions)
- **DesignTokens.swift**: `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/DesignTokens.swift`
- **Design System Audit**: `/Users/matthanson/Zer0_Inbox/DESIGN_SYSTEM_AUDIT.md`
- **Gradient Resolution**: `/Users/matthanson/Zer0_Inbox/GRADIENT_MISMATCH_RESOLUTION.md`

---

## Questions?

This specification covers all 169 actions, the email viewer, and complete component library. Ready to start building in Figma!

**Next Step:** Fix the gradients, then start with Phase 1 (Foundation).
