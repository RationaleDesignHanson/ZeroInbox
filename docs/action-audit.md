# Zero Inbox Action & Modal System Audit

**Generated:** 2025-12-20
**Purpose:** Comprehensive inventory of all actions, modals, and their mappings for modal system unification

---

## Executive Summary

### System Statistics

- **Total Actions:** 306+
- **GO_TO Actions (External URLs):** ~240
- **IN_APP Actions (Modals):** ~66
- **Modal Component Files:** 46 SwiftUI views
- **JSON Modal Configs:** 20+ data-driven configs
- **Compound Actions:** 10 multi-step flows
- **Action Priority Levels:** 8 (critical → veryLow)
- **Action Modes:** mail, ads, both

### Architecture Pattern
**Hybrid Registry System:**
- Central `ActionRegistry.swift` with 306+ action definitions
- `ActionRouter.swift` for execution and modal presentation
- Mix of custom SwiftUI modals and JSON-driven generic modals
- `CompoundActionRegistry.swift` for multi-step flows

---

## 1. Action Type Definitions

### Core Action Model
**Location:** `Zero_ios_2/Zero/Models/EmailCard.swift:276-336`

```swift
struct EmailAction: Identifiable, Codable {
    let id: String
    let actionId: String          // e.g., "track_package", "pay_invoice"
    let displayName: String       // Human-readable name
    let actionType: ActionType    // GO_TO or IN_APP
    let isPrimary: Bool          // Primary action shown on card
    let priority: Int?           // Sorting priority
    let context: [String: String]? // Entity data (trackingNumber, etc.)
    let isCompound: Bool?        // Multi-step action flag
    let compoundSteps: [String]? // Step action IDs
}

enum ActionType: String, Codable {
    case goTo = "GO_TO"      // Opens external URL (Safari)
    case inApp = "IN_APP"    // Opens modal within app
}
```

### Action Configuration Model
**Location:** `Zero_ios_2/Zero/Services/ActionRegistry.swift:109-177`

```swift
struct ActionConfig {
    let actionId: String
    let displayName: String
    let actionType: ZeroActionType  // GO_TO or IN_APP
    let mode: ZeroMode              // mail, ads, or both
    let modalComponent: String?     // Modal component name
    let requiredContextKeys: [String]
    let optionalContextKeys: [String]
    let fallbackBehavior: FallbackBehavior
    let analyticsEvent: String
    let priority: ActionPriority    // critical(95) to veryLow(60)
    let description: String?
    let featureFlag: String?
    let requiredPermission: ActionPermission  // free, premium, beta, admin
    let availability: ActionAvailability
    let confirmationRequirement: ConfirmationRequirement
    let modalConfigJSON: String?    // JSON config filename
}
```

### Action Priority System
**Location:** `Zero_ios_2/Zero/Services/ActionRegistry.swift:183-213`

| Priority | Score | Use Cases |
|----------|-------|-----------|
| `critical` | 95 | Life-critical, legal, financial (pay invoice, flight check-in, jury summons) |
| `veryHigh` | 90 | Time-sensitive (job offers, package tracking, medical results) |
| `high` | 85 | Important (invoices, appointments, unsubscribe) |
| `mediumHigh` | 80 | Useful (scheduling, documents, reservations) |
| `medium` | 75 | Standard actions (shopping, events, sharing) |
| `mediumLow` | 70 | Helpful but not essential (reminders, notes) |
| `low` | 65 | Nice-to-have (save contact, copy code) |
| `veryLow` | 60 | Utility/fallbacks (view details, open app) |

---

## 2. All Action Definitions by Category

### 2.1 High-Fidelity Premium Actions (6 actions)
**Location:** `Zero_ios_2/Zero/Services/ActionRegistry.swift:355-460`

| Action ID | Display Name | Priority | Permission | Modal Component | JSON Config | Context Keys |
|-----------|--------------|----------|------------|-----------------|-------------|--------------|
| `track_package` | Track Package | veryHigh (90) | Premium | TrackPackageModal | track_package.json | trackingNumber, carrier, url, expectedDelivery |
| `pay_invoice` | Pay Invoice | critical (95) | Premium | PayInvoiceModal | pay_invoice.json | invoiceId, amount, merchant, dueDate |
| `check_in_flight` | Check In | critical (95) | Premium | CheckInFlightModal | check_in_flight.json | flightNumber, airline, departureTime |
| `write_review` | Write Review | low (65) | Free | WriteReviewModal | write_review.json | productName, reviewLink, orderDate |
| `contact_driver` | Contact Driver | high (85) | Free | ContactDriverModal | contact_driver.json | driverName, phone, vehicleInfo |
| `view_pickup_details` | View Pickup Details | mediumHigh (80) | Free | PickupDetailsModal | view_pickup_details.json | pickupLocation, scheduledTime, instructions |

### 2.2 Mail Mode IN_APP Actions (26 actions)
**Location:** `Zero_ios_2/Zero/Services/ActionRegistry.swift:464-633`

| Action ID | Display Name | Priority | Permission | Modal Component | JSON Config |
|-----------|--------------|----------|------------|-----------------|-------------|
| `sign_form` | Sign Form | critical (95) | Premium | SignFormModal | - |
| `quick_reply` | Quick Reply | high (85) | Free | QuickReplyModal | quick_reply.json |
| `add_to_calendar` | Add to Calendar | mediumHigh (80) | Free | AddToCalendarModal | add_to_calendar.json |
| `schedule_meeting` | Schedule Meeting | medium (75) | Free | ScheduleMeetingModal | schedule_meeting.json |
| `add_reminder` | Add Reminder | mediumLow (70) | Free | AddReminderModal | add_reminder.json |
| `view_assignment` | View Assignment | high (85) | Free | GO_TO | - |
| `check_grade` | Check Grade | mediumHigh (80) | Free | GO_TO | - |
| `view_results` | View Results | veryHigh (90) | Free | GO_TO | - |
| `schedule_appointment` | Schedule Appointment | high (85) | Free | GO_TO | - |
| `view_jury_summons` | View Jury Summons | critical (95) | Free | GO_TO | - |
| `view_tax_notice` | View Tax Notice | critical (95) | Free | GO_TO | - |
| `view_document` | View Document | medium (75) | Free | DocumentViewerModal | - |
| `view_spreadsheet` | View Spreadsheet | medium (75) | Free | SpreadsheetViewerModal | - |
| `download_attachment` | Download Attachment | mediumLow (70) | Free | AttachmentPreviewModal | - |
| `save_contact_native` | Save Contact | mediumLow (70) | Free | SaveContactModal | save_contact.json |
| `send_message` | Send Message | medium (75) | Free | SendMessageModal | send_message.json |
| `add_to_notes` | Add to Notes | veryHigh (90) | Free | AddToNotesModal | - |
| `reply_to_thread` | Reply | veryHigh (90) | Free | QuickReplyModal | - |
| `rsvp_yes` | Accept Invitation | veryHigh (90) | Free | RSVPModal | rsvp.json |
| `rsvp_no` | Decline Invitation | medium (75) | Free | RSVPModal | rsvp.json |
| `view_reservation` | View Reservation | medium (75) | Free | ReservationModal | - |
| `snooze` | Snooze | medium (75) | Free | SnoozeModal | snooze.json |
| `share` | Share | low (65) | Free | ShareModal | share.json |
| `open_app` | Open App | mediumLow (70) | Free | OpenAppModal | - |
| `view_itinerary` | View Itinerary | mediumHigh (80) | Free | ViewItineraryModal | - |
| `review_security` | Review Security | critical (95) | Free | ReviewSecurityModal | - |

### 2.3 Ads Mode IN_APP Actions (11 actions)
**Location:** `Zero_ios_2/Zero/Services/ActionRegistry.swift:637-672`

| Action ID | Display Name | Priority | Permission | Modal Component | JSON Config |
|-----------|--------------|----------|------------|-----------------|-------------|
| `browse_shopping` | Browse Shopping | medium (75) | Free | BrowseShoppingModal | browse_shopping.json |
| `schedule_purchase` | Buy on {saleDateShort} | mediumHigh (80) | Premium | ScheduledPurchaseModal | scheduled_purchase.json |
| `view_newsletter_summary` | View Summary | mediumLow (70) | Premium | NewsletterSummaryModal | newsletter_summary.json |
| `unsubscribe` | Unsubscribe | high (85) | Premium | UnsubscribeModal | - |
| `shop_now` | Shop Now | medium (75) | Free | GO_TO | - |
| `view_offer` | View Offer | medium (75) | Free | GO_TO | - |
| `claim_deal` | Claim Deal | high (85) | Free | GO_TO | - |
| `cancel_subscription` | Cancel Subscription | high (85) | Free | CancelSubscriptionModal | cancel_subscription.json |
| `copy_promo_code` | Copy Code | high (85) | Free | (inline) | - |
| `set_price_alert` | Set Price Alert | high (85) | Free | ShoppingAutomationModal | - |
| `automated_add_to_cart` | Add to Cart & Checkout | veryHigh (90) | Free | ShoppingAutomationModal | - |

### 2.4 Shared Actions (Both Modes) (23 actions)
**Location:** `Zero_ios_2/Zero/Services/ActionRegistry.swift:676-862`

| Action ID | Display Name | Priority | Permission | Modal Component | JSON Config |
|-----------|--------------|----------|------------|-----------------|-------------|
| `add_to_wallet` | Add to Wallet | high (85) | Free | AddToWalletModal | add_to_wallet.json |
| `provide_access_code` | Provide Access Code | medium (75) | Free | ProvideAccessCodeModal | provide_access_code.json |
| `schedule_delivery_time` | Schedule Delivery Time | mediumHigh (80) | Free | ScheduleDeliveryTimeModal | - |
| `update_payment` | Update Payment | critical (95) | Free | UpdatePaymentModal | - |
| `schedule_payment` | Schedule Payment | high (85) | Free | PayInvoiceModal | - |
| `view_activity_details` | View Activity Details | medium (75) | Free | ViewActivityDetailsModal | - |
| `view_activity` | View Activity | medium (75) | Free | ViewActivityModal | - |
| `read_community_post` | Read Community Post | low (65) | Free | ReadCommunityPostModal | - |
| `view_post_comments` | View Post Comments | low (65) | Free | ViewPostCommentsModal | - |
| `save_properties` | Save Properties | mediumHigh (80) | Free | SavePropertiesModal | - |
| `prepare_for_outage` | Prepare for Outage | veryHigh (90) | Free | PrepareForOutageModal | - |
| `view_outage_details` | View Outage Details | high (85) | Free | ViewOutageDetailsModal | - |
| `account_verification` | Verify Account | critical (95) | Free | AccountVerificationModal | - |
| `view_details` | View Details | low (65) | Free | ViewDetailsModal | - |
| ... (9 more GO_TO actions) | ... | ... | ... | GO_TO | - |

### 2.5 GO_TO Actions (External URLs) (240+ actions)
**Location:** `Zero_ios_2/Zero/Services/ActionRegistry.swift:866-986`

Actions organized by domain:
- **Account Actions (25):** reset_password, verify_account, update_profile, change_email, enable_2fa, review_security_alert, close_account, download_data, etc.
- **Billing Actions (18):** view_invoice, update_payment_method, download_receipt, view_statement, dispute_charge, etc.
- **Career Actions (22):** accept_job_offer, schedule_interview, check_application_status, submit_documents, etc.
- **Shopping Actions (35):** view_order, track_shipment, return_item, modify_order, view_warranty, etc.
- **Travel Actions (28):** manage_booking, check_in_online, view_itinerary, change_flight, add_baggage, etc.
- **Healthcare Actions (18):** book_appointment, view_test_results, request_prescription_refill, etc.
- **Financial Actions (24):** view_bank_statement, dispute_transaction, download_tax_forms, activate_card, etc.
- **Utility Actions (15):** report_outage, schedule_service, view_usage, pay_bill, etc.
- **Real Estate Actions (12):** schedule_showing, submit_application, view_lease, pay_rent, etc.
- **Social Actions (8):** accept_friend_request, view_event, join_group, etc.
- **Subscription Actions (12):** manage_subscription, update_preferences, cancel_trial, etc.
- **Civic Actions (8):** view_jury_notice, pay_parking_ticket, register_to_vote, etc.
- **Miscellaneous (15):** open_link, view_webpage, download_file, etc.

---

## 3. Compound Actions (Multi-Step Flows)

**Location:** `Zero_ios_2/Zero/Services/CompoundActionRegistry.swift:53-186`

### Compound Action Model

```swift
struct CompoundActionDefinition {
    let actionId: String
    let displayName: String
    let steps: [String]              // Ordered step IDs
    let endBehavior: CompoundEndBehavior
    let requiresResponse: Bool       // Email composer needed?
    let isPremium: Bool
    let description: String
}
```

### All Compound Actions (10 total)

| Action ID | Display Name | Steps | End Behavior | Premium | Requires Email |
|-----------|--------------|-------|--------------|---------|----------------|
| `sign_form_with_payment` | Sign Form & Pay Fee | sign_form → pay_form_fee → email | Email composer | Yes | Yes |
| `sign_form_with_calendar` | Sign Form & Add to Calendar | sign_form → add_to_calendar → email | Email composer | Yes | Yes |
| `sign_and_send` | Sign & Send | sign_form → email | Email composer | No | Yes |
| `track_with_calendar` | Track with Calendar Reminder | track_package → add_to_calendar | Return to app | Yes | No |
| `schedule_purchase_with_reminder` | Schedule Purchase | schedule_purchase → add_to_calendar | Return to app | Yes | No |
| `pay_invoice_with_confirmation` | Pay Invoice | pay_invoice → email | Email composer | Yes | Yes |
| `check_in_with_wallet` | Check In & Add to Wallet | check_in_flight → add_to_wallet | Return to app | Yes | No |
| `calendar_with_reminder` | Calendar with Reminder | add_to_calendar → add_reminder | Return to app | No | No |
| `cancel_with_confirmation` | Cancel Subscription | cancel_subscription → email | Email composer | No | Yes |
| `[generic_placeholder]` | Under Development | (varies) | Show development UI | - | - |

**Modal Component:** `Zero_ios_2/Zero/Views/CompoundActionFlow.swift` (920 lines)

---

## 4. Modal Component Files (46 files)

**Location:** `Zero_ios_2/Zero/Views/ActionModules/`

### Complete Modal File Inventory

| # | File Name | Lines | Action ID(s) | JSON Config | Notes |
|---|-----------|-------|--------------|-------------|-------|
| 1 | `TrackPackageModal.swift` | ~250 | track_package | track_package.json | Premium, custom UI |
| 2 | `PayInvoiceModal.swift` | ~280 | pay_invoice | pay_invoice.json | Premium, payment flow |
| 3 | `CheckInFlightModal.swift` | ~220 | check_in_flight | check_in_flight.json | Premium, boarding pass |
| 4 | `SignFormModal.swift` | ~320 | sign_form | - | Premium, signature capture |
| 5 | `WriteReviewModal.swift` | ~180 | write_review | write_review.json | Star rating UI |
| 6 | `ContactDriverModal.swift` | ~160 | contact_driver | contact_driver.json | Call/SMS actions |
| 7 | `PickupDetailsModal.swift` | ~190 | view_pickup_details | view_pickup_details.json | Map integration |
| 8 | `QuickReplyModal.swift` | ~240 | quick_reply | quick_reply.json | Email composer |
| 9 | `AddToCalendarModal.swift` | ~200 | add_to_calendar | add_to_calendar.json | EventKit integration |
| 10 | `ScheduleMeetingModal.swift` | ~210 | schedule_meeting | schedule_meeting.json | Calendar UI |
| 11 | `AddReminderModal.swift` | ~150 | add_reminder | add_reminder.json | Reminder UI |
| 12 | `RSVPModal.swift` | ~170 | rsvp_yes, rsvp_no | rsvp.json | Accept/Decline |
| 13 | `SaveContactModal.swift` | ~180 | save_contact_native | save_contact.json | ContactUI integration |
| 14 | `SendMessageModal.swift` | ~160 | send_message | send_message.json | MessageUI |
| 15 | `AddToNotesModal.swift` | ~140 | add_to_notes | - | Notes integration |
| 16 | `SnoozeModal.swift` | ~190 | snooze | snooze.json | Time picker |
| 17 | `ShareModal.swift` | ~150 | share | share.json | Share sheet |
| 18 | `AddToWalletModal.swift` | ~170 | add_to_wallet | add_to_wallet.json | PassKit integration |
| 19 | `BrowseShoppingModal.swift` | ~220 | browse_shopping | browse_shopping.json | Product grid |
| 20 | `ScheduledPurchaseModal.swift` | ~200 | schedule_purchase | scheduled_purchase.json | Sale countdown |
| 21 | `NewsletterSummaryModal.swift` | ~180 | view_newsletter_summary | newsletter_summary.json | AI summary |
| 22 | `UnsubscribeModal.swift` | ~160 | unsubscribe | - | Confirmation UI |
| 23 | `CancelSubscriptionModal.swift` | ~170 | cancel_subscription | cancel_subscription.json | Cancellation flow |
| 24 | `ShoppingAutomationModal.swift` | ~250 | set_price_alert, automated_add_to_cart | - | Price tracking |
| 25 | `ProvideAccessCodeModal.swift` | ~140 | provide_access_code | provide_access_code.json | Code entry |
| 26 | `ScheduleDeliveryTimeModal.swift` | ~180 | schedule_delivery_time | - | Time slot picker |
| 27 | `UpdatePaymentModal.swift` | ~220 | update_payment | - | Payment form |
| 28 | `ViewActivityDetailsModal.swift` | ~160 | view_activity_details | - | Activity log |
| 29 | `ViewActivityModal.swift` | ~150 | view_activity | - | Activity summary |
| 30 | `ReadCommunityPostModal.swift` | ~190 | read_community_post | - | Post viewer |
| 31 | `ViewPostCommentsModal.swift` | ~180 | view_post_comments | - | Comments thread |
| 32 | `SavePropertiesModal.swift` | ~170 | save_properties | - | Property list |
| 33 | `PrepareForOutageModal.swift` | ~160 | prepare_for_outage | - | Checklist |
| 34 | `ViewOutageDetailsModal.swift` | ~150 | view_outage_details | - | Outage map |
| 35 | `AccountVerificationModal.swift` | ~180 | account_verification | - | Verification flow |
| 36 | `ViewDetailsModal.swift` | ~120 | view_details | - | Generic details |
| 37 | `DocumentViewerModal.swift` | ~240 | view_document | - | PDF viewer |
| 38 | `SpreadsheetViewerModal.swift` | ~220 | view_spreadsheet | - | Excel viewer |
| 39 | `AttachmentPreviewModal.swift` | ~200 | download_attachment | - | File preview |
| 40 | `AttachmentViewerModal.swift` | ~190 | (multiple) | - | Generic attachment |
| 41 | `DocumentPreviewModal.swift` | ~180 | (multiple) | - | Document preview |
| 42 | `ReservationModal.swift` | ~170 | view_reservation | - | Reservation card |
| 43 | `OpenAppModal.swift` | ~130 | open_app | - | Deep link handler |
| 44 | `ViewItineraryModal.swift` | ~200 | view_itinerary | - | Travel itinerary |
| 45 | `ReviewSecurityModal.swift` | ~190 | review_security | - | Security alert |
| 46 | `ShoppingPurchaseModal.swift` | ~180 | (deprecated?) | - | May be orphaned |

**Total Modal Code:** ~11,000 lines across 46 files

---

## 5. Action-to-Modal Mapping

### 5.1 Actions with Custom SwiftUI Modals (26 actions)

| Action ID | Modal Component | Mapped in Router? | JSON Config Exists? |
|-----------|-----------------|-------------------|---------------------|
| track_package | TrackPackageModal | ✅ Yes | ✅ Yes |
| pay_invoice | PayInvoiceModal | ✅ Yes | ✅ Yes |
| check_in_flight | CheckInFlightModal | ✅ Yes | ✅ Yes |
| sign_form | SignFormModal | ✅ Yes | ❌ No |
| write_review | WriteReviewModal | ✅ Yes | ✅ Yes |
| contact_driver | ContactDriverModal | ✅ Yes | ✅ Yes |
| view_pickup_details | PickupDetailsModal | ✅ Yes | ✅ Yes |
| quick_reply | QuickReplyModal | ✅ Yes | ✅ Yes |
| add_to_calendar | AddToCalendarModal | ✅ Yes | ✅ Yes |
| schedule_meeting | ScheduleMeetingModal | ✅ Yes | ✅ Yes |
| add_reminder | AddReminderModal | ✅ Yes | ✅ Yes |
| rsvp_yes, rsvp_no | RSVPModal | ✅ Yes | ✅ Yes |
| save_contact_native | SaveContactModal | ✅ Yes | ✅ Yes |
| send_message | SendMessageModal | ✅ Yes | ✅ Yes |
| add_to_notes | AddToNotesModal | ✅ Yes | ❌ No |
| snooze | SnoozeModal | ✅ Yes | ✅ Yes |
| share | ShareModal | ✅ Yes | ✅ Yes |
| add_to_wallet | AddToWalletModal | ✅ Yes | ✅ Yes |
| browse_shopping | BrowseShoppingModal | ✅ Yes | ✅ Yes |
| schedule_purchase | ScheduledPurchaseModal | ✅ Yes | ✅ Yes |
| view_newsletter_summary | NewsletterSummaryModal | ✅ Yes | ✅ Yes |
| unsubscribe | UnsubscribeModal | ✅ Yes | ❌ No |
| cancel_subscription | CancelSubscriptionModal | ✅ Yes | ✅ Yes |
| set_price_alert | ShoppingAutomationModal | ✅ Yes | ❌ No |
| automated_add_to_cart | ShoppingAutomationModal | ✅ Yes | ❌ No |
| provide_access_code | ProvideAccessCodeModal | ✅ Yes | ✅ Yes |

### 5.2 Actions Using JSON-Driven Generic Modals (20 actions)

These actions are primarily rendered through the generic modal system:

| Action ID | JSON Config | Custom Component Exists? |
|-----------|-------------|--------------------------|
| track_package | track_package.json | ✅ (hybrid) |
| pay_invoice | pay_invoice.json | ✅ (hybrid) |
| check_in_flight | check_in_flight.json | ✅ (hybrid) |
| write_review | write_review.json | ✅ (hybrid) |
| contact_driver | contact_driver.json | ✅ (hybrid) |
| view_pickup_details | view_pickup_details.json | ✅ (hybrid) |
| add_to_calendar | add_to_calendar.json | ✅ (hybrid) |
| quick_reply | quick_reply.json | ✅ (hybrid) |
| schedule_meeting | schedule_meeting.json | ✅ (hybrid) |
| save_contact | save_contact.json | ✅ (hybrid) |
| send_message | send_message.json | ✅ (hybrid) |
| browse_shopping | browse_shopping.json | ✅ (hybrid) |
| scheduled_purchase | scheduled_purchase.json | ✅ (hybrid) |
| newsletter_summary | newsletter_summary.json | ✅ (hybrid) |
| cancel_subscription | cancel_subscription.json | ✅ (hybrid) |
| provide_access_code | provide_access_code.json | ✅ (hybrid) |
| add_reminder | add_reminder.json | ✅ (hybrid) |
| rsvp | rsvp.json | ✅ (hybrid) |
| share | share.json | ✅ (hybrid) |
| snooze | snooze.json | ✅ (hybrid) |
| demo_form | demo_form.json | ❌ (JSON-only) |

### 5.3 Actions Without Modal Implementation (20 actions)

These IN_APP actions lack proper modal implementations:

| Action ID | Expected Modal | Current Behavior | Priority |
|-----------|----------------|------------------|----------|
| schedule_delivery_time | ScheduleDeliveryTimeModal | Exists but may be incomplete | High |
| update_payment | UpdatePaymentModal | Exists but may be incomplete | Critical |
| schedule_payment | (reuses PayInvoiceModal) | Shared modal | High |
| view_activity_details | ViewActivityDetailsModal | Exists | Medium |
| view_activity | ViewActivityModal | Exists | Medium |
| read_community_post | ReadCommunityPostModal | Exists | Low |
| view_post_comments | ViewPostCommentsModal | Exists | Low |
| save_properties | SavePropertiesModal | Exists | Medium |
| prepare_for_outage | PrepareForOutageModal | Exists | High |
| view_outage_details | ViewOutageDetailsModal | Exists | High |
| account_verification | AccountVerificationModal | Exists | Critical |
| view_details | ViewDetailsModal | Generic fallback | Low |
| view_document | DocumentViewerModal | Exists | Medium |
| view_spreadsheet | SpreadsheetViewerModal | Exists | Medium |
| download_attachment | AttachmentPreviewModal | Exists | Medium |
| view_reservation | ReservationModal | Exists | Medium |
| open_app | OpenAppModal | Exists | Low |
| view_itinerary | ViewItineraryModal | Exists | Medium |
| review_security | ReviewSecurityModal | Exists | Critical |
| reply_to_thread | (reuses QuickReplyModal) | Shared modal | High |

### 5.4 Potentially Orphaned Modal Files (1 file)

| File Name | Last Known Action | Status |
|-----------|-------------------|--------|
| ShoppingPurchaseModal.swift | Unknown | May be deprecated, not found in router mapping |

---

## 6. JSON Modal Configurations (20+ files)

**Location:** `Zero_ios_2/Zero/Config/ModalConfigs/`

### Modal Config Structure

```swift
struct ModalConfig: Codable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: IconConfig?
    let sections: [ModalSection]
    let primaryButton: ButtonConfig
    let secondaryButton: ButtonConfig?
    let layout: ModalLayout  // standard, form, detail, timeline
}
```

### All JSON Modal Configs

| Config File | Action ID | Sections | Fields | Interactive? | Status |
|-------------|-----------|----------|--------|--------------|--------|
| track_package.json | track_package | 3 | 8 | No | ✅ Complete |
| pay_invoice.json | pay_invoice | 2 | 6 | No | ✅ Complete |
| check_in_flight.json | check_in_flight | 2 | 7 | No | ✅ Complete |
| write_review.json | write_review | 2 | 5 | No | ✅ Complete |
| contact_driver.json | contact_driver | 1 | 4 | No | ✅ Complete |
| view_pickup_details.json | view_pickup_details | 2 | 6 | No | ✅ Complete |
| add_to_calendar.json | add_to_calendar | 1 | 5 | Yes | 🚧 Phase 2 |
| schedule_meeting.json | schedule_meeting | 2 | 6 | Yes | 🚧 Phase 2 |
| quick_reply.json | quick_reply | 1 | 3 | Yes | 🚧 Phase 2 |
| send_message.json | send_message | 1 | 3 | Yes | 🚧 Phase 2 |
| save_contact.json | save_contact_native | 2 | 7 | Yes | 🚧 Phase 2 |
| add_to_wallet.json | add_to_wallet | 1 | 4 | No | ✅ Complete |
| browse_shopping.json | browse_shopping | 1 | 3 | Yes | 🚧 Phase 2 |
| scheduled_purchase.json | schedule_purchase | 2 | 5 | Yes | 🚧 Phase 2 |
| newsletter_summary.json | view_newsletter_summary | 2 | 4 | No | ✅ Complete |
| cancel_subscription.json | cancel_subscription | 1 | 4 | Yes | 🚧 Phase 2 |
| provide_access_code.json | provide_access_code | 1 | 3 | Yes | 🚧 Phase 2 |
| add_reminder.json | add_reminder | 1 | 4 | Yes | 🚧 Phase 2 |
| rsvp.json | rsvp_yes, rsvp_no | 2 | 5 | Yes | 🚧 Phase 2 |
| share.json | share | 1 | 3 | No | ✅ Complete |
| snooze.json | snooze | 1 | 2 | Yes | 🚧 Phase 2 |
| demo_form.json | (demo only) | 3 | 12 | Yes | ✅ Demo |

**Note:** Interactive configs use Phase 2 field types (textInput, datePicker, etc.) currently under development

---

## 7. Action Routing & Presentation

### ActionRouter Modal Building
**Location:** `Zero_ios_2/Zero/Services/ActionRouter.swift:354-534`

```swift
private func buildModalForAction(_ action: EmailAction, card: EmailCard) -> ActionModal {
    // 1. Check for JSON modal configuration first (v2.3)
    if let modalConfigJSON = actionConfig.modalConfigJSON {
        if let genericModal = loadGenericModal(...) {
            return .generic(config: modalConfig, context: context, card: card)
        }
    }

    // 2. Fall back to hardcoded modal mapping
    switch modalComponent {
        case "TrackPackageModal":
            return .trackPackage(card: card, trackingNumber: ..., ...)
        case "PayInvoiceModal":
            return .payInvoice(card: card, invoiceId: ..., ...)
        // ... 40+ more cases
    }
}
```

### ActionModal Enum
**Location:** `Zero_ios_2/Zero/Services/ActionRouter.swift:761-863`

Total: 46 modal cases matching the 46 modal files (approximately)

### Modal Presentation Pattern
**Location:** `Zero_ios_2/Zero/Views/MainFeedView.swift`

```swift
.sheet(item: $viewState.selectedCardForActionModal) { card in
    getActionModalView(for: card)
}
```

---

## 8. Supporting Infrastructure

### Action Context System
**Location:** `Zero_ios_2/Zero/Core/ActionSystem/ActionContext.swift`

- Type-safe wrapper around `[String: Any]` dictionary
- 50+ typed accessors for common context keys
- Validation support for required keys
- Integration with EmailCard data

### Service Call Executor
**Location:** `Zero_ios_2/Zero/Core/ActionSystem/ServiceCallExecutor.swift`

Supports 7 services:
- ActionRegistry
- AIService
- NotificationService
- EmailService
- CalendarService
- ReminderService
- ContactService

### Compound Action Flow
**Location:** `Zero_ios_2/Zero/Views/CompoundActionFlow.swift` (920 lines)

- Wizard-style multi-step modal
- Progress tracking
- Step validation
- Configurable end behaviors
- "Under development" UI for unimplemented features

### Action Modal Coordinator (Unused)
**Location:** `Zero_ios_2/Zero/Coordinators/ActionModalCoordinator.swift`

Infrastructure exists but not actively used. Routing currently handled in:
- `Zero_ios_2/Zero/Views/ContentView.swift` (1,340 lines of routing logic)

---

## 9. Summary Statistics

### Action Distribution
- **GO_TO Actions:** 240 (78.4%)
- **IN_APP Actions:** 66 (21.6%)
  - With custom modals: 26
  - With JSON configs: 20
  - Without implementation: 20

### Modal Implementation Status
- **Total Modal Files:** 46
- **Actively Mapped:** ~45
- **Potentially Orphaned:** 1
- **JSON Configs:** 20+
- **Hybrid (Both):** ~18

### Permission Distribution (IN_APP actions)
- **Free:** ~54 actions (82%)
- **Premium:** ~12 actions (18%)
- **Beta:** 0 actions
- **Admin:** 0 actions

### Priority Distribution (IN_APP actions)
- **Critical (95):** 6 actions
- **Very High (90):** 8 actions
- **High (85):** 12 actions
- **Medium High (80):** 9 actions
- **Medium (75):** 18 actions
- **Medium Low (70):** 8 actions
- **Low (65):** 4 actions
- **Very Low (60):** 1 action

---

## Next Steps

This audit serves as the foundation for:

1. **Phase 2:** Gap analysis to identify inconsistencies and missing implementations
2. **Phase 3:** Component strategy to unify modal patterns
3. **Phase 4:** Test harness for QA validation
4. **Phase 5:** Iterative implementation of unified modal system

---

**Document Generated:** 2025-12-20
**Source Code Locations:**
- `Zero_ios_2/Zero/Services/ActionRegistry.swift` (1,310 lines)
- `Zero_ios_2/Zero/Services/ActionRouter.swift` (889 lines)
- `Zero_ios_2/Zero/Services/CompoundActionRegistry.swift` (186 lines)
- `Zero_ios_2/Zero/Views/ActionModules/` (46 files, ~11,000 lines)
- `Zero_ios_2/Zero/Config/ModalConfigs/` (20+ JSON files)
- `Zero_ios_2/Zero/Core/ActionSystem/` (3 files, ~900 lines)
