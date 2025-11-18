# Action Testing Checklist
**Version:** 1.0
**Last Updated:** 2025-11-17
**Purpose:** Ensure all 45+ actions are properly integrated before public TestFlight beta

---

## Testing Categories

### 🎯 High Priority (Test First - Critical Path)
Actions users will encounter most frequently

- [ ] **track_package** - Track shipping package
- [ ] **pay_invoice** - Pay invoice or bill
- [ ] **check_in_flight** - Check in for flight
- [ ] **quick_reply** - Send quick reply to email
- [ ] **add_to_calendar** - Add event to calendar
- [ ] **view_newsletter_summary** - View AI newsletter summary (Premium)
- [ ] **shop_now** - Open shopping link
- [ ] **claim_deal** - Add to cart via Steel.dev automation (Premium)
- [ ] **view_details** - View full email details
- [ ] **cancel_subscription** - Cancel subscription

---

## 📦 Package & Delivery Actions (MAIL Mode)

### Track Package
- [ ] Modal opens with tracking number
- [ ] Steel.dev integration initiates
- [ ] Error handling if tracking fails
- [ ] Success feedback shown

### View Pickup Details
- [ ] Pickup location displayed
- [ ] Map integration works
- [ ] Contact info shown

### Contact Driver
- [ ] Phone number extracted
- [ ] SMS/call options available
- [ ] Fallback if no contact info

---

## 💰 Financial Actions (MAIL Mode)

### Pay Invoice
- [ ] Invoice amount displayed
- [ ] Payment URL opens in Safari
- [ ] Security warning if needed
- [ ] Confirmation after action

### Set Payment Reminder
- [ ] Reminder date selector works
- [ ] Integrates with iOS Reminders
- [ ] Notification permission handling

---

## ✈️ Travel Actions (MAIL Mode)

### Check In Flight
- [ ] Flight details extracted
- [ ] Opens airline website/app
- [ ] Boarding pass accessible
- [ ] Wallet integration offered

### View Reservation
- [ ] Reservation details shown
- [ ] Add to calendar option
- [ ] Contact hotel/airline options

---

## 📝 Form & Document Actions (MAIL Mode)

### Sign Form (Premium)
- [ ] Form preview loads
- [ ] Signature capture works
- [ ] Send signed form option
- [ ] PDF generation successful

### View Document
- [ ] PDF viewer opens
- [ ] Zoom/pan controls work
- [ ] Download option available
- [ ] Share functionality

### View Spreadsheet
- [ ] Spreadsheet preview loads
- [ ] Basic data visible
- [ ] Opens in Numbers/Excel option

---

## 📅 Calendar & Meeting Actions (MAIL Mode)

### Add to Calendar
- [ ] Event details pre-filled
- [ ] Date/time parsing correct
- [ ] Location extracted
- [ ] Meeting URL included
- [ ] Saves to iOS Calendar

### Schedule Meeting
- [ ] Meeting creation modal
- [ ] Attendee extraction
- [ ] Time suggestion works
- [ ] Email composer fallback

### Accept School Event
- [ ] Event details shown
- [ ] Adds to calendar
- [ ] RSVP confirmation sent

---

## 🔔 Reminder & Task Actions (MAIL Mode)

### Add Reminder
- [ ] Reminder creation modal
- [ ] Due date selector
- [ ] Notes field works
- [ ] Saves to iOS Reminders
- [ ] Permission handling

### Set Reminder (Sale Date)
- [ ] Sale date extracted correctly
- [ ] Reminder set for correct date
- [ ] Notification scheduling works

---

## 🎓 Education Actions (MAIL Mode)

### View Assignment
- [ ] Assignment URL opens
- [ ] Canvas/Schoology integration
- [ ] Due date highlighted

### Check Grade
- [ ] Grade portal opens
- [ ] Authentication handled
- [ ] Deep link to specific grade

### View LMS
- [ ] Learning platform opens
- [ ] Session maintained
- [ ] Course navigation works

---

## 🏥 Healthcare Actions (MAIL Mode)

### View Results (Critical)
- [ ] Lab results page opens
- [ ] Security verification
- [ ] Download option available

### View Prescription
- [ ] Prescription details shown
- [ ] Pharmacy info included
- [ ] Refill option available

### Schedule Appointment
- [ ] Booking page opens
- [ ] Available times shown
- [ ] Confirmation received

### Check In Appointment
- [ ] Check-in form opens
- [ ] Pre-filled patient info
- [ ] Confirmation displayed

### Pickup Prescription
- [ ] Pharmacy location shown
- [ ] Pickup hours displayed
- [ ] Map/directions available

---

## ⚖️ Legal & Government Actions (MAIL Mode - Critical)

### View Jury Summons
- [ ] Summons details displayed
- [ ] Respond option available
- [ ] Add to calendar offered
- [ ] Exemption request option

### View Tax Notice
- [ ] Tax document opens
- [ ] Payment instructions clear
- [ ] Due date highlighted
- [ ] Download for records

### View Voter Info
- [ ] Polling location shown
- [ ] Voter registration status
- [ ] Sample ballot available
- [ ] Add to calendar option

---

## 💼 Work & Productivity Actions (MAIL Mode)

### View Task
- [ ] Task details shown
- [ ] Project management tool opens
- [ ] Status update option

### View Incident
- [ ] Incident report displays
- [ ] Severity indicator shown
- [ ] Response options available

### View Ticket
- [ ] Support ticket opens
- [ ] History visible
- [ ] Reply option available

### Route to CRM
- [ ] Lead extraction successful
- [ ] CRM integration works
- [ ] Confirmation shown

### Write Review
- [ ] Review form opens
- [ ] Star rating works
- [ ] Text input functional
- [ ] Submit successful

---

## 🛍️ Shopping Actions (ADS Mode)

### Shop Now
- [ ] Product page opens in Safari
- [ ] URL correct
- [ ] Session maintained

### Claim Deal (Premium)
- [ ] Steel.dev automation starts
- [ ] Product added to cart
- [ ] Checkout initiated
- [ ] Error handling robust

### Browse Shopping
- [ ] Product gallery loads
- [ ] Filtering works
- [ ] Price comparison shown
- [ ] Wishlist integration

### Schedule Purchase (Premium)
- [ ] Product details saved
- [ ] Future date selector
- [ ] Reminder creation
- [ ] Price tracking option

---

## 📰 Newsletter Actions (ADS Mode)

### View Newsletter Summary (Premium)
- [ ] AI summary generates
- [ ] Key topics highlighted
- [ ] Important links extracted
- [ ] 4-6 sentence summary (new requirement!)
- [ ] Fallback if 401 error
- [ ] Error message helpful

### Cancel Subscription
- [ ] Unsubscribe link opens
- [ ] One-click unsubscribe option
- [ ] Confirmation modal
- [ ] Success feedback

---

## 📱 Native iOS Integration Actions (BOTH Modes)

### Add to Wallet
- [ ] Pass preview shown
- [ ] Adds to Apple Wallet
- [ ] Pass updates work
- [ ] Notifications enabled

### Save Contact (Native)
- [ ] Contact card preview
- [ ] Pre-filled from sender
- [ ] Additional fields editable
- [ ] Saves to iOS Contacts
- [ ] Permission handling

### Send Message
- [ ] Phone number extracted
- [ ] Messages app opens
- [ ] Pre-filled message (if any)
- [ ] Fallback if no Messages

### Open App
- [ ] Deep link constructed correctly
- [ ] External app launches
- [ ] Fallback if app not installed
- [ ] Return to Zero works

---

## 🔧 Utility & Fallback Actions (BOTH Modes)

### View Details (Fallback)
- [ ] Full email content loads
- [ ] HTML rendering works
- [ ] Plain text fallback
- [ ] Attachments shown
- [ ] Thread display (if applicable)

### Save for Later
- [ ] Folder selection works
- [ ] Reminder option available
- [ ] Email moved correctly
- [ ] Undo option shown

---

## Testing Methodology

### Per-Action Testing Steps

1. **Trigger Action**
   - Swipe right on test email card
   - Tap primary action button
   - Select from action menu

2. **Verify Modal/UI**
   - Modal opens smoothly
   - All fields populated correctly
   - No layout issues
   - Haptic feedback appropriate

3. **Execute Action**
   - Complete the action flow
   - Verify external app/webpage opens (if GO_TO)
   - Check permissions are handled
   - Test error scenarios

4. **Verify Completion**
   - Success message displayed
   - Card dismissed/archived appropriately
   - Analytics event fired
   - No crashes or errors

5. **Edge Cases**
   - Missing context data
   - Network errors
   - Permission denials
   - Timeout scenarios

---

## Priority Testing Order

### Phase 1: Critical Path (30 minutes)
Test the 10 most common actions to ensure core functionality works

### Phase 2: Mode-Specific (45 minutes)
Test all MAIL actions, then all ADS actions

### Phase 3: Premium Features (20 minutes)
Test premium-only actions (sign_form, claim_deal, view_newsletter_summary, schedule_purchase)

### Phase 4: Edge Cases (30 minutes)
Test fallback behaviors, error handling, permission flows

---

## Known Issues to Watch For

- [ ] 401 errors if not logged in (re-login required after JWT token fix)
- [ ] Newsletter summaries should be 4-6 sentences (recently fixed)
- [ ] Primary action should be "View Website" for newsletters, not "Quick Reply" (backend fix applied)
- [ ] Full email reader should not crash on nil htmlBody (iOS fix applied)

---

## Success Criteria

**Before Public TestFlight:**
- [ ] All High Priority actions tested (10 actions)
- [ ] No crashes in modal flows
- [ ] GO_TO actions open correct URLs
- [ ] IN_APP modals render properly
- [ ] Permission prompts work correctly
- [ ] Error messages are user-friendly
- [ ] Analytics events firing

**Nice to Have:**
- [ ] All 45 actions manually tested
- [ ] Premium features verified
- [ ] Edge cases covered
- [ ] Accessibility tested with VoiceOver

---

## Testing Notes

**Date:** _______________
**Tester:** _______________
**Build Version:** _______________

**Blockers Found:**
-
-

**Issues Found:**
-
-

**Actions Requiring Fixes:**
-
-
