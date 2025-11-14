# Figma Build Guide - Optimized Component System

**Date:** November 10, 2025
**Optimized:** 47 modals → 12 templates (60% reduction)
**Start Here:** Step-by-step guide to build Zero Inbox in Figma

---

## 🎯 What You're Building

### The Numbers
- **169 Actions** across Zero Inbox
- **103 GO_TO Actions** (61%) → Just visual feedback, NO modals
- **66 IN_APP Actions** (39%) → **Only 12 modal templates needed!**

### Why This Approach?
Instead of designing 47 unique modals, we've consolidated to **12 reusable templates** that handle all actions through configuration.

**Result:** 60% less work, infinitely easier to maintain.

---

## 📅 8-Week Build Plan

### Week 1: Foundation (Atoms)
**Goal:** Build all atomic components

**Checklist:**
- [ ] Fix gradient colors (Mail & Ads)
- [ ] **Create GO_TO visual feedback system (2 hours)** ⭐ NEW
  - [ ] External indicator icon (↗)
  - [ ] Action card with press/loading states
  - [ ] Loading spinner (8 priority colors)
  - [ ] Apply to 103 GO_TO actions
- [ ] Create 5 gradient button variants × 3 sizes (15 total)
- [ ] Create 8 input types (text, textarea, date, time, dropdown, checkbox, radio, toggle)
- [ ] Create 8 priority badge variants (Critical → Very Low)
- [ ] Create 4 progress indicators (bar, ring, numeric, spinner)
- [ ] Set up all typography styles as Figma text styles
- [ ] Create icon library structure (169 action icons)

**Output:** Complete atomic component library + GO_TO feedback system

**Note:** GO_TO system covers 103 actions (61%) with just visual feedback—no modals needed!

---

### Week 2: Molecules
**Goal:** Combine atoms into reusable groups

**Checklist:**
- [ ] ModalHeader (icon + title + close button)
- [ ] ModalFooter (primary CTA + cancel)
- [ ] InputGroup (label + input + helper/error)
- [ ] InfoCard (icon + label + value)
- [ ] RecipientField (email chips)
- [ ] AmountDisplay (large currency)
- [ ] TimelineStep (tracking steps)
- [ ] RatingStars (5-star rating)
- [ ] ProductCard (image + name + price)
- [ ] ContactCard (avatar + name + phone)
- [ ] TemplateChip (quick replies)
- [ ] ActionCard (inbox list item)
- [ ] ExtractedInfoCard (email key info)
- [ ] ToastContainer (undo system)
- [ ] EmailListItem (inbox item)

**Output:** 15 molecule components

---

### Week 3: Core Modal Templates (Part 1)
**Goal:** Build the 3 most-used templates (covers 52 actions!)

#### 1. GenericActionModal
**Replaces:** 30 unique modals
**Used by:** Add to Calendar, Schedule Meeting, Add Reminder, Save for Later, Set Alert, etc.

**Build:**
```
Component: GenericActionModal
Variants: None (configured via props)

Layout:
┌─────────────────────────────────┐
│ [ModalHeader]                   │
│   Icon (configurable)           │
│   Title (configurable)          │
│   Close button                  │
├─────────────────────────────────┤
│ Description (optional text)     │
│                                 │
│ [Content Slot]                  │
│   Flexible area:                │
│   - 1-5 input fields            │
│   - Info cards                  │
│   - Date/time pickers           │
│   - Dropdowns                   │
│                                 │
├─────────────────────────────────┤
│ [ModalFooter]                   │
│   Primary CTA (configurable)    │
│   Cancel                        │
└─────────────────────────────────┘
```

**Test with 3 examples:**
1. Add to Calendar (date + time + title + location)
2. Add Reminder (title + due date + notes)
3. Save for Later (folder selector + reminder)

**Deliverable:** 1 master component + 3 example instances

---

#### 2. CommunicationModal
**Replaces:** 8 modals (QuickReply, Reply, Email Composer, Send Message)
**Used by:** All email/message actions

**Build:**
```
Component: CommunicationModal
Variants: None (configured via props)

Layout:
┌─────────────────────────────────┐
│ To: [RecipientField]            │
│ Subject: [TextField - prefilled]│
├─────────────────────────────────┤
│ [Message Body - Textarea]       │
│                                 │
│ [Template Chips - Optional]     │
│ [Yes] [Thanks] [Confirmed]      │
│                                 │
├─────────────────────────────────┤
│ [Send Button - Mail Gradient]   │
│ Cancel                          │
└─────────────────────────────────┘
```

**Test with 2 examples:**
1. Quick Reply (subject prefilled, templates visible)
2. Email Composer (blank, no templates)

**Deliverable:** 1 master component + 2 example instances

---

#### 3. ViewContentModal
**Replaces:** 14 modals (View Details, View Document, View Announcement, etc.)
**Used by:** All "View X" actions

**Build:**
```
Component: ViewContentModal
Variants: None (configured via content)

Layout:
┌─────────────────────────────────┐
│ [Header with Title]             │
│ Close button                    │
├─────────────────────────────────┤
│ [Scrollable Content Area]       │
│                                 │
│ Flexible content:               │
│ - Document preview              │
│ - Info cards grid               │
│ - Rich text                     │
│ - Images                        │
│                                 │
├─────────────────────────────────┤
│ [Action Buttons - Optional]     │
│ [Download] [Share] [Print]      │
│ Close                           │
└─────────────────────────────────┘
```

**Test with 3 examples:**
1. View Document (PDF preview + download)
2. View Benefits (info cards grid)
3. View Announcement (rich text + image)

**Deliverable:** 1 master component + 3 example instances

---

**Week 3 Total:** 3 templates covering **52 actions** (80% of IN_APP modals!)

---

### Week 4: Core Modal Templates (Part 2)
**Goal:** Build 3 more commonly-used templates

#### 4. FinancialTransactionModal
**Used by:** Pay Invoice, Pay Bill, Pay Tax, Pay Fee (4 actions)

**Build:**
```
Component: FinancialTransactionModal

Layout:
┌─────────────────────────────────┐
│ Pay [Merchant]                  │
├─────────────────────────────────┤
│ [AMOUNT - HUGE]                 │
│ $999.99                         │
├─────────────────────────────────┤
│ [InfoCard] To: Merchant + logo  │
│ [InfoCard] Due: Date + countdown│
│ [InfoCard] Description          │
│                                 │
│ Payment Method:                 │
│ [Dropdown - cards]              │
├─────────────────────────────────┤
│ [Pay $XXX - Critical Button]    │
│ Cancel                          │
└─────────────────────────────────┘
```

**Test with 2 examples:**
1. Pay Invoice ($1,234.56, due in 3 days)
2. Pay Utility Bill ($89.32, due today)

---

#### 5. ReviewRatingModal
**Used by:** Write Review, Rate Product (2 actions)

**Build:**
```
Component: ReviewRatingModal

Layout:
┌─────────────────────────────────┐
│ [ProductCard]                   │
│   Image + Name                  │
├─────────────────────────────────┤
│ Rating:                         │
│ [RatingStars - Interactive]     │
│ ⭐⭐⭐⭐⭐                      │
│                                 │
│ Review (optional):              │
│ [Textarea]                      │
│                                 │
├─────────────────────────────────┤
│ [Submit Review Button]          │
│ Skip                            │
└─────────────────────────────────┘
```

---

#### 6. ShoppingCartModal
**Used by:** Add to Cart, Buy Again, Reorder, Complete Cart (5 actions)

**Build:**
```
Component: ShoppingCartModal

Layout:
┌─────────────────────────────────┐
│ [ProductCard]                   │
│   Image + Name + Price          │
├─────────────────────────────────┤
│ Quantity:                       │
│ [-] [  2  ] [+]                 │
│                                 │
│ Total: $XX.XX                   │
│                                 │
├─────────────────────────────────┤
│ [Add to Cart - Ads Gradient]    │
│ OR                              │
│ [Buy Now - Ads Gradient]        │
│                                 │
│ Continue Shopping               │
└─────────────────────────────────┘
```

**Week 4 Total:** 3 more templates covering 11 actions

---

### Week 5: Specialized Templates
**Goal:** Build remaining 6 specialized templates

#### 7. TrackingModal
**Used by:** Track Package (1 action, but iconic)

**Build:**
```
Component: TrackingModal

Layout:
┌─────────────────────────────────┐
│ [Carrier Logo - Large]          │
│ Tracking: XXXXXXXXXXXX          │
├─────────────────────────────────┤
│ [Timeline - Vertical]           │
│ ✓ Ordered      Jan 5            │
│ ✓ Shipped      Jan 6            │
│ ⊙ In Transit   Jan 8 ← Current  │
│ ○ Delivered    Est. Jan 10      │
│                                 │
│ ETA: Friday, Jan 10 at 2:00 PM  │
├─────────────────────────────────┤
│ [Track on Website Button]       │
│ Close                           │
└─────────────────────────────────┘
```

**Note:** Most beautiful modal in the app. Make it shine!

---

#### 8. CheckInModal
**Used by:** Check In Flight (1 action)

**Build:**
```
Component: CheckInModal

Layout:
┌─────────────────────────────────┐
│ [Airline Logo - Large]          │
│ Flight XX1234                   │
├─────────────────────────────────┤
│ [InfoCard] Departure: 3:45 PM   │
│ [InfoCard] Gate: A12            │
│ [InfoCard] Seat: 14B            │
│                                 │
├─────────────────────────────────┤
│ [Check In - Large Critical CTA] │
│ Opens airline website/app       │
│                                 │
│ Close                           │
└─────────────────────────────────┘
```

---

#### 9. SignSubmitModal
**Used by:** Sign Form (1 action)

**Build:**
```
Component: SignSubmitModal

Layout:
┌─────────────────────────────────┐
│ Sign [Document Name]            │
├─────────────────────────────────┤
│ [Document Preview - Scrollable] │
│ (Show first page or thumbnail)  │
│                                 │
├─────────────────────────────────┤
│ Signature:                      │
│ [Canvas for Drawing]            │
│ OR                              │
│ [Typed Name Input]              │
│ Clear                           │
│                                 │
├─────────────────────────────────┤
│ [Sign & Submit - Critical]      │
│ Cancel                          │
└─────────────────────────────────┘
```

---

#### 10. ContactCallModal
**Used by:** Contact Driver, View Pickup Details (2 actions)

**Build:**
```
Component: ContactCallModal

Layout:
┌─────────────────────────────────┐
│ [ContactCard]                   │
│   Avatar + Name                 │
├─────────────────────────────────┤
│ Phone: (555) 123-4567           │
│ [Call Button - Large, Green]    │
│                                 │
│ [Additional Info - Optional]    │
│ Vehicle: Toyota Camry, Gray     │
│ ETA: 5 minutes                  │
│                                 │
│ Close                           │
└─────────────────────────────────┘
```

---

#### 11. SubscriptionManagementModal
**Used by:** Manage, Cancel, Upgrade Subscription (3 actions)

**Build:**
```
Component: SubscriptionManagementModal
Variants: Manage | Cancel | Upgrade

Layout:
┌─────────────────────────────────┐
│ [Service Logo]                  │
│ Current Plan: Premium           │
├─────────────────────────────────┤
│ [InfoCard] Billing: $9.99/month │
│ [InfoCard] Next bill: Jan 15    │
│ [InfoCard] Features: ...        │
│                                 │
├─────────────────────────────────┤
│ [Action Buttons]                │
│ Variant: Manage                 │
│   - Upgrade                     │
│   - Downgrade                   │
│   - Cancel                      │
│                                 │
│ Variant: Cancel                 │
│   - Cancel Subscription (Red)   │
│   - Keep Subscription           │
│                                 │
│ Variant: Upgrade                │
│   - Upgrade Now                 │
│   - Maybe Later                 │
└─────────────────────────────────┘
```

---

#### 12. ConfirmationInputModal
**Used by:** Copy Code, Provide Access Code, Simple prompts (5-10 actions)

**Build:**
```
Component: ConfirmationInputModal

Layout:
┌─────────────────────────────────┐
│ [Icon - Large]                  │
│ [Question/Prompt]               │
├─────────────────────────────────┤
│ [Single Input - Optional]       │
│ OR                              │
│ [Info Display - Optional]       │
│                                 │
├─────────────────────────────────┤
│ [Confirm Button]                │
│ Cancel                          │
└─────────────────────────────────┘
```

**Week 5 Total:** 6 specialized templates, all IN_APP modals complete!

---

### Week 6: Email Viewer
**Goal:** Build the email viewing experience

**Checklist:**
- [ ] Email Viewer organism (full screen)
- [ ] Header (back, avatar, subject, badges)
- [ ] Metadata bar (from, to, date, priority)
- [ ] Email body (scrollable, rich text)
- [ ] Extracted info cards (embedded in body)
- [ ] Action bar (bottom fixed)
- [ ] Create 5 email examples:
  - Critical priority (red badge)
  - High priority (yellow badge)
  - Standard email
  - Email with extracted cards
  - Email with attachments

**Deliverable:** Email viewer + 5 variants

---

### Week 7: Action Flows & Edge Cases
**Goal:** Document all 169 actions and their states

**Checklist:**
- [ ] Map each action to its modal template
- [ ] Create loading states (spinner overlays)
- [ ] Create error states (toast messages)
- [ ] Create success states (confirmation toasts)
- [ ] Create GO_TO feedback (103 actions)
  - Brief spinner on action card
  - Fade to external app

**Deliverable:** Complete state system

---

### Week 8: Polish & Handoff
**Goal:** Finalize and prepare for development

**Checklist:**
- [ ] Responsive layouts (iPhone 15, 15 Pro Max)
- [ ] Create interactive prototypes
  - Example: Inbox → Tap action → Modal → Complete → Toast
- [ ] Developer handoff documentation
  - Component specs
  - Spacing values
  - Typography scales
  - Color values
- [ ] Create design system style guide
- [ ] Test all interactions

**Deliverable:** Production-ready design system

---

## 🎨 Figma File Structure

### Recommended Organization

```
Pages:
├── 📚 Design System
│   ├── Foundation
│   │   ├── Colors (with corrected gradients!)
│   │   ├── Typography
│   │   ├── Spacing
│   │   ├── Shadows
│   │   └── Icons
│   └── Tokens Reference
│
├── ⚛️ Components
│   ├── Atoms
│   │   ├── Buttons (15 variants)
│   │   ├── Inputs (8 types)
│   │   ├── Badges (8 priority + 3 status)
│   │   ├── Progress (4 types)
│   │   └── Typography
│   ├── Molecules
│   │   ├── ModalHeader
│   │   ├── ModalFooter
│   │   ├── InputGroup
│   │   ├── InfoCard
│   │   ├── ActionCard
│   │   ├── ToastContainer
│   │   ├── ... (15 total)
│   │   └── EmailListItem
│   └── Organisms
│       ├── Modals (12 templates)
│       ├── EmailViewer
│       ├── ActionBar
│       └── Navigation
│
├── 📧 Email Viewer
│   ├── Email Template
│   ├── Critical Priority Example
│   ├── High Priority Example
│   ├── Standard Example
│   ├── With Extracted Cards
│   └── With Attachments
│
├── 🎭 Modal Library
│   ├── GenericActionModal (+ 3 examples)
│   ├── CommunicationModal (+ 2 examples)
│   ├── ViewContentModal (+ 3 examples)
│   ├── FinancialTransactionModal (+ 2 examples)
│   ├── ReviewRatingModal
│   ├── ShoppingCartModal
│   ├── TrackingModal
│   ├── CheckInModal
│   ├── SignSubmitModal
│   ├── ContactCallModal
│   ├── SubscriptionManagementModal (3 variants)
│   └── ConfirmationInputModal
│
├── 🔄 Action Flows
│   ├── GO_TO Actions (103 - just feedback)
│   ├── Quick Actions (35 - with undo toast)
│   ├── Modal Actions (66 - full flows)
│   └── Edge Cases (loading, error, success)
│
├── 📱 Screens
│   ├── Inbox (Mail mode)
│   ├── Inbox (Ads mode)
│   ├── Email Viewer
│   ├── Settings
│   └── Onboarding
│
└── 🎬 Prototypes
    ├── Complete Action Flow
    ├── Undo Flow
    ├── Error Handling
    └── Success Confirmation
```

---

## ✅ Quality Checklist

### Before Marking Complete

**Foundation:**
- [ ] Gradients are correct (Mail: #667eea→#764ba2, Ads: #16bbaa→#4fd19e)
- [ ] All color styles created in Figma
- [ ] All text styles created in Figma
- [ ] Spacing values match iOS (4, 8, 12, 16, 20, 24, 32px)
- [ ] Border radius values match iOS (4, 8, 12, 16, 20px)

**Atoms:**
- [ ] All 15 button variants work (5 gradients × 3 sizes)
- [ ] All 8 input types functional
- [ ] All 8 priority badges colored correctly
- [ ] Progress indicators animate (or have animation notes)

**Molecules:**
- [ ] ModalHeader reusable across all modals
- [ ] ModalFooter reusable across all modals
- [ ] Components use auto-layout (responsive)
- [ ] Components maintain constraints properly

**Modals:**
- [ ] All 12 modal templates built
- [ ] Each template tested with 2-3 examples
- [ ] Modals are responsive (adapt to content)
- [ ] Close buttons work (in prototype)

**Email Viewer:**
- [ ] Scrollable body
- [ ] Fixed header and action bar
- [ ] Extracted info cards integrate properly
- [ ] Responsive on iPhone 15 and 15 Pro Max

**Documentation:**
- [ ] Each component has description
- [ ] Usage examples provided
- [ ] Constraints documented
- [ ] Spacing rules clear

---

## 🚀 Quick Start (Day 1)

### Hour 1: Setup
1. Open Figma file: WuQicPi1wbHXqEcYCQcLfr
2. Navigate to 🎨 Design System Components page
3. Fix gradients:
   - Mail: Start #667eea, End #764ba2
   - Ads: Start #16bbaa, End #4fd19e

### Hour 2-4: First Buttons
1. Create GradientButton component
2. Add 5 gradient variants:
   - Mail (blue→purple)
   - Ads (teal→green)
   - Lifestyle (purple→pink)
   - Shop (green→emerald)
   - Urgent (orange→yellow)
3. Add 3 size variants per gradient:
   - Standard (56px height)
   - Compact (44px height)
   - Small (32px height)
4. Use auto-layout for padding
5. Add icon + text options

**By end of Day 1:** You have 15 button variants ready to use!

---

## 💡 Pro Tips

### Auto-Layout Everything
Use Figma's auto-layout for:
- All modals (so they resize with content)
- Button padding (consistent spacing)
- Input groups (labels + fields + errors)
- Cards (icon + text stacking)

### Component Variants
Use Figma variants for:
- Button styles (5 gradients)
- Button sizes (3 sizes)
- Priority badges (8 levels)
- Input states (default, focused, error)
- Subscription modal types (manage, cancel, upgrade)

### Naming Convention
```
Component/Type/Variant

Examples:
Button/Gradient/Mail/Standard
Button/Gradient/Ads/Compact
Badge/Priority/Critical
Modal/GenericAction/Calendar
```

### Layer Organization
```
Modal
├── Background (backdrop)
├── Container (card)
│   ├── Header
│   │   ├── Icon
│   │   ├── Title
│   │   └── Close
│   ├── Content
│   │   ├── Description
│   │   └── Fields
│   └── Footer
│       ├── Primary CTA
│       └── Cancel
```

---

## 📊 Progress Tracking

### Week 1 Checklist (Foundation)
- [ ] Gradients fixed
- [ ] 15 button variants
- [ ] 8 input types
- [ ] 8 priority badges
- [ ] 4 progress indicators
- [ ] Typography styles
- [ ] Icon library structure

**Progress:** ___/7 complete

### Week 2 Checklist (Molecules)
- [ ] ModalHeader
- [ ] ModalFooter
- [ ] InputGroup
- [ ] InfoCard
- [ ] RecipientField
- [ ] AmountDisplay
- [ ] TimelineStep
- [ ] RatingStars
- [ ] ProductCard
- [ ] ContactCard
- [ ] TemplateChip
- [ ] ActionCard
- [ ] ExtractedInfoCard
- [ ] ToastContainer
- [ ] EmailListItem

**Progress:** ___/15 complete

### Week 3-5 Checklist (Modals)
- [ ] GenericActionModal (+ 3 examples)
- [ ] CommunicationModal (+ 2 examples)
- [ ] ViewContentModal (+ 3 examples)
- [ ] FinancialTransactionModal (+ 2 examples)
- [ ] ReviewRatingModal
- [ ] ShoppingCartModal
- [ ] TrackingModal
- [ ] CheckInModal
- [ ] SignSubmitModal
- [ ] ContactCallModal
- [ ] SubscriptionManagementModal (3 variants)
- [ ] ConfirmationInputModal

**Progress:** ___/12 complete

### Week 6 Checklist (Email Viewer)
- [ ] Email Viewer template
- [ ] 5 email examples

**Progress:** ___/6 complete

### Week 7-8 Checklist (Polish)
- [ ] All 169 actions documented
- [ ] Edge cases (loading, error, success)
- [ ] Interactive prototypes
- [ ] Developer handoff specs
- [ ] Design system style guide

**Progress:** ___/5 complete

---

## 🎉 You're Ready!

**Everything you need to build Zero Inbox in Figma is now documented.**

**Start with:**
1. Fix gradients (5 min)
2. Build buttons (3 hours)
3. Build 3 core modals (Week 3)

**Result:** 80% of the UI in 3 weeks, with reusable components that make the remaining 20% fast.

**Questions?** Reference:
- `COMPONENT_CONSOLIDATION.md` - Full analysis
- `FIGMA_DESIGN_SPECIFICATION.md` - Original detailed specs
- `DESIGN_SYSTEM_AUDIT.md` - Figma vs iOS comparison

**Let's build! 🚀**
