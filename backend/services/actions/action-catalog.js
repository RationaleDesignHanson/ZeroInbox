/**
 * Action Catalog
 * Central registry of all possible actions users can take on emails
 */

const ActionCatalog = {
  // E-COMMERCE ACTIONS
  track_package: {
    actionId: 'track_package',
    displayName: 'Track Package',
    actionType: 'GO_TO',
    description: 'Track package delivery status',
    requiredEntities: ['trackingNumber', 'carrier'],
    validIntents: ['e-commerce.shipping.notification', 'e-commerce.delivery.completed', 'delivery.tracking.alert'],
    priority: 1,
    urlTemplate: '{carrierTrackingUrl}'
  },
  view_order: {
    actionId: 'view_order',
    displayName: 'View Order',
    actionType: 'GO_TO',
    description: 'View order details',
    requiredEntities: ['orderNumber'],
    validIntents: ['e-commerce.order.confirmation', 'e-commerce.shipping.notification', 'e-commerce.order.receipt'],
    priority: 2,
    urlTemplate: '{orderUrl}'
  },
  buy_again: {
    actionId: 'buy_again',
    displayName: 'Buy Again',
    actionType: 'GO_TO',
    description: 'Reorder the same items',
    requiredEntities: ['orderNumber'],
    validIntents: ['e-commerce.delivery.completed', 'e-commerce.order.receipt'],
    priority: 2,
    urlTemplate: '{reorderUrl}'
  },
  return_item: {
    actionId: 'return_item',
    displayName: 'Return Item',
    actionType: 'GO_TO',
    description: 'Initiate return process',
    requiredEntities: ['orderNumber'],
    validIntents: ['e-commerce.delivery.completed'],
    priority: 1,
    urlTemplate: '{returnUrl}'
  },

  // BILLING & PAYMENT ACTIONS
  pay_invoice: {
    actionId: 'pay_invoice',
    displayName: 'Pay Invoice',
    actionType: 'IN_APP',
    description: 'Pay outstanding invoice with IN_APP modal',
    requiredEntities: ['invoiceId', 'amount'],
    validIntents: ['billing.invoice.due'],
    priority: 1
  },
  download_receipt: {
    actionId: 'download_receipt',
    displayName: 'Download Receipt',
    actionType: 'GO_TO',
    description: 'Download payment receipt',
    requiredEntities: ['receiptUrl'],
    validIntents: ['billing.payment.received', 'e-commerce.order.receipt'],
    priority: 2,
    urlTemplate: '{receiptUrl}'
  },
  view_invoice: {
    actionId: 'view_invoice',
    displayName: 'View Invoice',
    actionType: 'GO_TO',
    description: 'View invoice details',
    requiredEntities: ['invoiceId'],
    validIntents: ['billing.invoice.due', 'billing.payment.received'],
    priority: 2,
    urlTemplate: '{invoiceUrl}'
  },
  set_payment_reminder: {
    actionId: 'set_payment_reminder',
    displayName: 'Set Reminder',
    actionType: 'IN_APP',
    description: 'Set reminder to pay invoice',
    requiredEntities: ['dueDate'],
    validIntents: ['billing.invoice.due'],
    priority: 3
  },
  manage_subscription: {
    actionId: 'manage_subscription',
    displayName: 'Manage Subscription',
    actionType: 'GO_TO',
    description: 'Manage subscription settings',
    requiredEntities: [],
    validIntents: ['billing.subscription.renewal'],
    priority: 2,
    urlTemplate: '{subscriptionUrl}'
  },
  cancel_subscription: {
    actionId: 'cancel_subscription',
    displayName: 'Cancel Subscription',
    actionType: 'IN_APP',
    description: 'Cancel unwanted subscription with AI assistance',
    requiredEntities: [],
    validIntents: ['billing.subscription.renewal'],
    priority: 1
  },
  unsubscribe: {
    actionId: 'unsubscribe',
    displayName: 'Unsubscribe',
    actionType: 'GO_TO',
    description: 'Unsubscribe from marketing emails and newsletters',
    requiredEntities: [],
    validIntents: [
      'marketing.promotion.flash-sale',
      'marketing.promotion.discount',
      'marketing.product.launch',
      'marketing.cart.abandonment',
      'marketing.home-decor.products',
      'marketing.content.lifestyle',
      'marketing.brand.storytelling',
      'e-commerce.order.receipt',
      'e-commerce.delivery.completed',
      'generic.newsletter.content',
      'content.newsletter.sports',
      'content.newsletter.gaming',
      'content.newsletter.entertainment',
      'content.newsletter.career',
      'content.newsletter.tech',
      'content.newsletter.finance',
      'content.newsletter.lifestyle',
      'social.content.recommendation'
    ],
    priority: 3,
    urlTemplate: '{unsubscribeUrl}'
  },
  update_payment: {
    actionId: 'update_payment',
    displayName: 'Update Payment',
    actionType: 'GO_TO',
    description: 'Update payment method',
    requiredEntities: [],
    validIntents: ['billing.subscription.renewal'],
    priority: 2,
    urlTemplate: '{paymentUrl}'
  },

  // MEETING & EVENT ACTIONS
  join_meeting: {
    actionId: 'join_meeting',
    displayName: 'Join Meeting',
    actionType: 'GO_TO',
    description: 'Join video meeting',
    requiredEntities: ['meetingUrl'],
    validIntents: ['event.meeting.invitation', 'event.meeting.reminder'],
    priority: 1,
    urlTemplate: '{meetingUrl}'
  },
  add_to_calendar: {
    actionId: 'add_to_calendar',
    displayName: 'Add to Calendar',
    actionType: 'IN_APP',
    description: 'Add event to calendar',
    requiredEntities: ['dateTime'],
    validIntents: [
      'event.meeting.invitation',
      'event.webinar.invitation',
      'education.permission.form',
      'healthcare.appointment.reminder',
      'healthcare.appointment.booking-request',
      'dining.reservation.confirmation',
      'civic.appointment.summons'
    ],
    priority: 2,
    usesNativeIOS: true
  },
  add_reminder: {
    actionId: 'add_reminder',
    displayName: 'Add Reminder',
    actionType: 'IN_APP',
    description: 'Add iOS reminder notification (default 15min before event)',
    requiredEntities: ['dateTime'],
    validIntents: [],
    priority: 3,
    usesNativeIOS: true
  },
  rsvp_yes: {
    actionId: 'rsvp_yes',
    displayName: 'Accept Invitation',
    actionType: 'IN_APP',
    description: 'Accept invitation',
    requiredEntities: [],
    validIntents: ['event.meeting.invitation', 'event.webinar.invitation'],
    priority: 1
  },
  rsvp_no: {
    actionId: 'rsvp_no',
    displayName: 'Decline Invitation',
    actionType: 'IN_APP',
    description: 'Decline invitation',
    requiredEntities: [],
    validIntents: ['event.meeting.invitation', 'event.webinar.invitation'],
    priority: 3
  },
  register_event: {
    actionId: 'register_event',
    displayName: 'Register',
    actionType: 'GO_TO',
    description: 'Register for event',
    requiredEntities: ['registrationLink'],
    validIntents: ['event.webinar.invitation'],
    priority: 1,
    urlTemplate: '{registrationLink}'
  },

  // ACCOUNT & SECURITY ACTIONS
  reset_password: {
    actionId: 'reset_password',
    displayName: 'Reset Password',
    actionType: 'GO_TO',
    description: 'Reset account password',
    requiredEntities: ['resetLink'],
    validIntents: ['account.password.reset'],
    priority: 1,
    urlTemplate: '{resetLink}'
  },
  verify_account: {
    actionId: 'verify_account',
    displayName: 'Verify Account',
    actionType: 'GO_TO',
    description: 'Verify email or account',
    requiredEntities: ['verificationLink'],
    validIntents: ['account.verification.required'],
    priority: 1,
    urlTemplate: '{verificationLink}'
  },
  verify_device: {
    actionId: 'verify_device',
    displayName: 'Verify Device',
    actionType: 'GO_TO',
    description: 'Verify new device login',
    requiredEntities: [],
    validIntents: ['account.security.alert'],
    priority: 1,
    urlTemplate: '{verificationUrl}'
  },
  review_security: {
    actionId: 'review_security',
    displayName: 'Review Security',
    actionType: 'GO_TO',
    description: 'Review security settings',
    requiredEntities: [],
    validIntents: ['account.security.alert', 'account.secret.exposed'],
    priority: 1,
    urlTemplate: '{securityUrl}'
  },
  revoke_secret: {
    actionId: 'revoke_secret',
    displayName: 'Revoke Secret',
    actionType: 'GO_TO',
    description: 'Revoke exposed API key or secret',
    requiredEntities: ['actionUrl'],
    validIntents: ['account.secret.exposed'],
    priority: 1,
    urlTemplate: '{actionUrl}'
  },

  // HEALTHCARE ACTIONS
  check_in_appointment: {
    actionId: 'check_in_appointment',
    displayName: 'Check In',
    actionType: 'GO_TO',
    description: 'Check in for appointment online',
    requiredEntities: ['checkInUrl'],
    validIntents: ['healthcare.appointment.reminder'],
    priority: 1,
    urlTemplate: '{checkInUrl}'
  },
  get_directions: {
    actionId: 'get_directions',
    displayName: 'Get Directions',
    actionType: 'GO_TO',
    description: 'Get directions to location',
    requiredEntities: ['location'],
    validIntents: ['healthcare.appointment.reminder', 'healthcare.prescription.ready', 'dining.reservation.confirmation'],
    priority: 2,
    urlTemplate: 'https://maps.google.com/?q={location}'
  },
  view_pickup_details: {
    actionId: 'view_pickup_details',
    displayName: 'View Pickup Details',
    actionType: 'IN_APP',
    description: 'View prescription pickup information',
    requiredEntities: ['rxNumber'],
    validIntents: ['healthcare.prescription.ready'],
    priority: 1
  },
  view_results: {
    actionId: 'view_results',
    displayName: 'View Results',
    actionType: 'GO_TO',
    description: 'View lab or test results',
    requiredEntities: ['resultsUrl'],
    validIntents: ['healthcare.results.available'],
    priority: 1,
    urlTemplate: '{resultsUrl}'
  },
  file_insurance_claim: {
    actionId: 'file_insurance_claim',
    displayName: 'File Insurance Claim',
    actionType: 'IN_APP',
    description: 'File insurance claim for medical bill reimbursement',
    requiredEntities: [],
    validIntents: ['healthcare.billing.superbill'],
    priority: 1
  },

  // DINING ACTIONS
  view_reservation: {
    actionId: 'view_reservation',
    displayName: 'View Reservation',
    actionType: 'GO_TO',
    description: 'View restaurant reservation details',
    requiredEntities: ['confirmationCode'],
    validIntents: ['dining.reservation.confirmation'],
    priority: 1,
    urlTemplate: '{reservationUrl}'
  },
  modify_reservation: {
    actionId: 'modify_reservation',
    displayName: 'Modify Reservation',
    actionType: 'GO_TO',
    description: 'Modify restaurant reservation',
    requiredEntities: ['confirmationCode'],
    validIntents: ['dining.reservation.confirmation'],
    priority: 2,
    urlTemplate: '{reservationUrl}'
  },

  // DELIVERY ACTIONS
  track_delivery: {
    actionId: 'track_delivery',
    displayName: 'Track Delivery',
    actionType: 'GO_TO',
    description: 'Track food delivery in real-time',
    requiredEntities: ['trackingUrl'],
    validIntents: ['delivery.food.tracking'],
    priority: 1,
    urlTemplate: '{trackingUrl}'
  },
  contact_driver: {
    actionId: 'contact_driver',
    displayName: 'Contact Driver',
    actionType: 'IN_APP',
    description: 'Contact delivery driver',
    requiredEntities: ['driver'],
    validIntents: ['delivery.food.tracking'],
    priority: 2
  },
  change_delivery_preferences: {
    actionId: 'change_delivery_preferences',
    displayName: 'Change Preferences',
    actionType: 'GO_TO',
    description: 'Update delivery time or location preferences',
    requiredEntities: [],
    validIntents: ['delivery.tracking.alert'],
    priority: 2,
    urlTemplate: '{preferencesUrl}'
  },
  provide_access_code: {
    actionId: 'provide_access_code',
    displayName: 'Provide Access Code',
    actionType: 'IN_APP',
    description: 'Provide building or gate access code for delivery',
    requiredEntities: ['trackingNumber'],
    validIntents: ['delivery.tracking.alert'],
    priority: 3
  },

  // EDUCATION ACTIONS
  view_assignment: {
    actionId: 'view_assignment',
    displayName: 'View Assignment',
    actionType: 'GO_TO',
    description: 'View assignment details',
    requiredEntities: ['assignmentUrl'],
    validIntents: ['education.assignment.due', 'education.grade.posted'],
    priority: 1,
    urlTemplate: '{assignmentUrl}'
  },
  check_grade: {
    actionId: 'check_grade',
    displayName: 'Check Grade',
    actionType: 'GO_TO',
    description: 'View grade details',
    requiredEntities: ['gradeUrl'],
    validIntents: ['education.grade.posted'],
    priority: 1,
    urlTemplate: '{gradeUrl}'
  },
  sign_form: {
    actionId: 'sign_form',
    displayName: 'Sign Form',
    actionType: 'IN_APP',
    description: 'Sign permission form digitally',
    requiredEntities: ['formName'],
    validIntents: ['education.permission.form'],
    priority: 1
  },
  pay_form_fee: {
    actionId: 'pay_form_fee',
    displayName: 'Pay Fee',
    actionType: 'IN_APP',
    description: 'Pay associated form fee',
    requiredEntities: ['amount'],
    validIntents: ['education.permission.form'],
    priority: 2
  },

  // CHILD/SCHOOL ACTIONS (LMS, Sports, Events)
  view_lms_message: {
    actionId: 'view_lms_message',
    displayName: 'View Message',
    actionType: 'GO_TO',
    description: 'View Canvas/Classroom message from teacher',
    requiredEntities: ['messageUrl'],
    validIntents: ['education.lms.message'],
    priority: 1,
    urlTemplate: '{messageUrl}'
  },
  reply_to_teacher: {
    actionId: 'reply_to_teacher',
    displayName: 'Reply to Teacher',
    actionType: 'GO_TO',
    description: 'Reply to teacher message',
    requiredEntities: ['teacher'],
    validIntents: ['education.lms.message', 'education.parent.teacher-communication'],
    priority: 2,
    urlTemplate: '{messageUrl}'
  },
  submit_assignment: {
    actionId: 'submit_assignment',
    displayName: 'Submit Assignment',
    actionType: 'GO_TO',
    description: 'Go to assignment submission page',
    requiredEntities: ['assignmentUrl'],
    validIntents: ['education.lms.assignment-posted', 'education.assignment.due'],
    priority: 1,
    urlTemplate: '{assignmentUrl}'
  },
  register_for_sports: {
    actionId: 'register_for_sports',
    displayName: 'Register',
    actionType: 'GO_TO',
    description: 'Register for youth sports or activity',
    requiredEntities: ['registrationUrl'],
    validIntents: ['youth.sports.registration'],
    priority: 1,
    urlTemplate: '{registrationUrl}'
  },
  view_game_schedule: {
    actionId: 'view_game_schedule',
    displayName: 'View Schedule',
    actionType: 'GO_TO',
    description: 'View game schedule',
    requiredEntities: [],
    validIntents: ['youth.sports.game-schedule'],
    priority: 1,
    urlTemplate: '{scheduleUrl}'
  },
  rsvp_game: {
    actionId: 'rsvp_game',
    displayName: 'RSVP to Game',
    actionType: 'GO_TO',
    description: 'RSVP for game attendance',
    requiredEntities: [],
    validIntents: ['youth.sports.game-schedule'],
    priority: 2,
    urlTemplate: '{rsvpUrl}'
  },
  view_practice_details: {
    actionId: 'view_practice_details',
    displayName: 'View Practice Info',
    actionType: 'IN_APP',
    description: 'View practice details',
    requiredEntities: ['sport', 'dateTime'],
    validIntents: ['youth.sports.practice-reminder'],
    priority: 1
  },
  accept_school_event: {
    actionId: 'accept_school_event',
    displayName: 'Accept Event',
    actionType: 'IN_APP',
    description: 'Accept school event invitation and add to calendar',
    requiredEntities: ['event', 'dateTime'],
    validIntents: ['education.event.invitation'],
    priority: 1,
    usesNativeIOS: true
  },
  rsvp_school_event: {
    actionId: 'rsvp_school_event',
    displayName: 'RSVP to Event',
    actionType: 'GO_TO',
    description: 'RSVP for school event',
    requiredEntities: [],
    validIntents: ['education.event.invitation'],
    priority: 2,
    urlTemplate: '{rsvpUrl}'
  },
  view_team_announcement: {
    actionId: 'view_team_announcement',
    displayName: 'View Announcement',
    actionType: 'IN_APP',
    description: 'View team announcement details',
    requiredEntities: ['sport', 'team'],
    validIntents: ['youth.sports.team-announcement'],
    priority: 1
  },

  // TRAVEL ACTIONS
  check_in_flight: {
    actionId: 'check_in_flight',
    displayName: 'Check In',
    actionType: 'IN_APP',
    description: 'Check in for flight with IN_APP modal',
    requiredEntities: ['flightNumber', 'airline'],
    validIntents: ['travel.flight.check-in'],
    priority: 1
  },
  view_itinerary: {
    actionId: 'view_itinerary',
    displayName: 'View Itinerary',
    actionType: 'GO_TO',
    description: 'View travel itinerary',
    requiredEntities: ['confirmationCode'],
    validIntents: ['travel.reservation.confirmation', 'travel.itinerary.update'],
    priority: 2,
    urlTemplate: '{itineraryUrl}'
  },
  add_to_wallet: {
    actionId: 'add_to_wallet',
    displayName: 'Add to Wallet',
    actionType: 'IN_APP',
    description: 'Add boarding pass to wallet',
    requiredEntities: ['confirmationCode'],
    validIntents: ['travel.flight.check-in'],
    priority: 2,
    usesNativeIOS: true
  },
  manage_booking: {
    actionId: 'manage_booking',
    displayName: 'Manage Booking',
    actionType: 'GO_TO',
    description: 'Manage reservation',
    requiredEntities: ['confirmationCode'],
    validIntents: ['travel.reservation.confirmation', 'travel.itinerary.update'],
    priority: 3,
    urlTemplate: '{bookingUrl}'
  },

  // REVIEW & FEEDBACK ACTIONS
  write_review: {
    actionId: 'write_review',
    displayName: 'Write Review',
    actionType: 'IN_APP',
    description: 'Write product review with IN_APP modal',
    requiredEntities: ['productName'],
    validIntents: ['feedback.review.request'],
    priority: 1
  },
  rate_product: {
    actionId: 'rate_product',
    displayName: 'Rate Product',
    actionType: 'IN_APP',
    description: 'Quick star rating',
    requiredEntities: ['productName'],
    validIntents: ['feedback.review.request'],
    priority: 2
  },
  take_survey: {
    actionId: 'take_survey',
    displayName: 'Take Survey',
    actionType: 'GO_TO',
    description: 'Complete survey',
    requiredEntities: ['surveyLink'],
    validIntents: ['feedback.survey.invitation'],
    priority: 1,
    urlTemplate: '{surveyLink}'
  },

  // SHOPPING & DEALS ACTIONS
  claim_deal: {
    actionId: 'claim_deal',
    displayName: 'Claim Deal',
    actionType: 'GO_TO',
    description: 'Claim promotional offer',
    requiredEntities: [],
    validIntents: ['marketing.promotion.flash-sale', 'marketing.promotion.discount', 'marketing.product.launch'],
    priority: 1,
    urlTemplate: '{dealUrl}'
  },
  copy_promo_code: {
    actionId: 'copy_promo_code',
    displayName: 'Copy Code',
    actionType: 'IN_APP',
    description: 'Copy promo code',
    requiredEntities: ['promoCode'],
    validIntents: ['marketing.promotion.flash-sale', 'marketing.promotion.discount', 'marketing.cart.abandonment'],
    priority: 2
  },
  view_product: {
    actionId: 'view_product',
    displayName: 'View Product',
    actionType: 'GO_TO',
    description: 'View product details',
    requiredEntities: ['productUrl'],
    validIntents: ['marketing.product.launch'],
    priority: 1,
    urlTemplate: '{productUrl}'
  },
  automated_add_to_cart: {
    actionId: 'automated_add_to_cart',
    displayName: 'Add to Cart & Checkout',
    actionType: 'IN_APP',
    description: 'AI agent adds item to cart and opens checkout',
    requiredEntities: ['productUrl', 'productName'],
    validIntents: [
      'marketing.promotion.flash-sale',
      'marketing.promotion.discount',
      'marketing.product.launch',
      'e-commerce.restock.alert',
      'shopping.product.future-sale',
      'e-commerce.price.drop'
    ],
    priority: 1,
    usesNativeIOS: false,
    usesSteelAgent: true
  },
  complete_cart: {
    actionId: 'complete_cart',
    displayName: 'Complete Order',
    actionType: 'GO_TO',
    description: 'Complete cart checkout',
    requiredEntities: ['cartUrl'],
    validIntents: ['marketing.cart.abandonment'],
    priority: 1,
    urlTemplate: '{cartUrl}'
  },
  schedule_purchase: {
    actionId: 'schedule_purchase',
    displayName: 'Buy on {saleDateShort}',
    actionType: 'IN_APP',
    description: 'Schedule automated purchase for future sale date',
    requiredEntities: ['saleDate', 'productUrl'],
    validIntents: ['shopping.product.future-sale'],
    priority: 1
  },
  set_reminder: {
    actionId: 'set_reminder',
    displayName: 'Remind me on {saleDateShort}',
    actionType: 'IN_APP',
    description: 'Set reminder for future sale date',
    requiredEntities: ['saleDate'],
    validIntents: ['shopping.product.future-sale'],
    priority: 2
  },
  redeem_rewards: {
    actionId: 'redeem_rewards',
    displayName: 'Redeem Rewards',
    actionType: 'GO_TO',
    description: 'Redeem loyalty points or rewards',
    requiredEntities: [],
    validIntents: ['marketing.loyalty.reward'],
    priority: 1,
    urlTemplate: '{rewardUrl}'
  },
  view_announcement: {
    actionId: 'view_announcement',
    displayName: 'View Announcement',
    actionType: 'GO_TO',
    description: 'View brand announcement details',
    requiredEntities: [],
    validIntents: ['marketing.brand.announcement'],
    priority: 1,
    urlTemplate: '{announcementUrl}'
  },

  // SUPPORT ACTIONS
  view_ticket: {
    actionId: 'view_ticket',
    displayName: 'View Ticket',
    actionType: 'GO_TO',
    description: 'View support ticket',
    requiredEntities: ['ticketUrl'],
    validIntents: ['support.ticket.confirmation', 'support.ticket.update'],
    priority: 1,
    urlTemplate: '{ticketUrl}'
  },
  reply_to_ticket: {
    actionId: 'reply_to_ticket',
    displayName: 'Reply',
    actionType: 'IN_APP',
    description: 'Reply to support ticket',
    requiredEntities: ['ticketId'],
    validIntents: ['support.ticket.update'],
    priority: 2
  },
  contact_support: {
    actionId: 'contact_support',
    displayName: 'Contact Support',
    actionType: 'GO_TO',
    description: 'Contact customer support',
    requiredEntities: [],
    validIntents: ['e-commerce.shipping.notification', 'e-commerce.delivery.completed'],
    priority: 4,
    urlTemplate: '{supportUrl}'
  },

  // PROJECT ACTIONS
  view_task: {
    actionId: 'view_task',
    displayName: 'View Task',
    actionType: 'GO_TO',
    description: 'View task details',
    requiredEntities: ['taskUrl'],
    validIntents: ['project.task.assigned'],
    priority: 1,
    urlTemplate: '{taskUrl}'
  },
  view_incident: {
    actionId: 'view_incident',
    displayName: 'View Incident',
    actionType: 'GO_TO',
    description: 'View incident details',
    requiredEntities: ['incidentUrl'],
    validIntents: ['project.incident.alert'],
    priority: 1,
    urlTemplate: '{incidentUrl}'
  },

  // NEW HEALTHCARE ACTIONS (for 6 new intents)
  book_appointment: {
    actionId: 'book_appointment',
    displayName: 'Book Appointment',
    actionType: 'GO_TO',
    description: 'Schedule or book a new appointment',
    requiredEntities: [],
    validIntents: ['healthcare.appointment.booking-request'],
    priority: 1,
    urlTemplate: '{schedulingUrl}'
  },
  confirm_appointment: {
    actionId: 'confirm_appointment',
    displayName: 'Confirm Appointment',
    actionType: 'GO_TO',
    description: 'Confirm medical appointment',
    requiredEntities: [],
    validIntents: ['healthcare.appointment.confirmation', 'healthcare.appointment.reminder'],
    priority: 1,
    urlTemplate: '{confirmationUrl}'
  },
  reschedule_appointment: {
    actionId: 'reschedule_appointment',
    displayName: 'Reschedule',
    actionType: 'GO_TO',
    description: 'Reschedule appointment',
    requiredEntities: [],
    validIntents: ['healthcare.appointment.cancellation', 'healthcare.appointment.confirmation'],
    priority: 1,
    urlTemplate: '{rescheduleUrl}'
  },
  download_results: {
    actionId: 'download_results',
    displayName: 'Download Results',
    actionType: 'GO_TO',
    description: 'Download medical test results',
    requiredEntities: ['resultsUrl'],
    validIntents: ['healthcare.results.available'],
    priority: 1,
    urlTemplate: '{resultsUrl}'
  },
  pickup_prescription: {
    actionId: 'pickup_prescription',
    displayName: 'Pickup Details',
    actionType: 'IN_APP',
    description: 'View prescription pickup information',
    requiredEntities: ['medication'],
    validIntents: ['healthcare.prescription.ready'],
    priority: 1
  },
  view_referral: {
    actionId: 'view_referral',
    displayName: 'View Referral',
    actionType: 'GO_TO',
    description: 'View specialist referral details',
    requiredEntities: [],
    validIntents: ['healthcare.referral.request'],
    priority: 1,
    urlTemplate: '{referralUrl}'
  },
  schedule_test: {
    actionId: 'schedule_test',
    displayName: 'Schedule Test',
    actionType: 'GO_TO',
    description: 'Schedule medical test or lab work',
    requiredEntities: [],
    validIntents: ['healthcare.test.order', 'healthcare.follow-up.reminder'],
    priority: 1,
    urlTemplate: '{schedulingUrl}'
  },
  view_claim_status: {
    actionId: 'view_claim_status',
    displayName: 'View Claim',
    actionType: 'GO_TO',
    description: 'View insurance claim status',
    requiredEntities: ['claimNumber'],
    validIntents: ['healthcare.insurance.claim'],
    priority: 1,
    urlTemplate: '{claimUrl}'
  },

  // NEW FINANCE ACTIONS (for 8 new intents)
  view_statement: {
    actionId: 'view_statement',
    displayName: 'View Statement',
    actionType: 'GO_TO',
    description: 'View financial statement',
    requiredEntities: ['accountId'],
    validIntents: ['finance.statement.ready'],
    priority: 1,
    urlTemplate: '{statementUrl}'
  },
  update_payment_method: {
    actionId: 'update_payment_method',
    displayName: 'Update Payment',
    actionType: 'GO_TO',
    description: 'Update payment method',
    requiredEntities: [],
    validIntents: ['finance.payment.failed', 'finance.payment.reminder', 'billing.subscription.renewal', 'account.payment.expiration'],
    priority: 1,
    urlTemplate: '{paymentUrl}'
  },
  download_tax_document: {
    actionId: 'download_tax_document',
    displayName: 'Download Tax Form',
    actionType: 'GO_TO',
    description: 'Download tax document',
    requiredEntities: ['taxYear'],
    validIntents: ['finance.tax.document'],
    priority: 1,
    urlTemplate: '{downloadUrl}'
  },
  dispute_transaction: {
    actionId: 'dispute_transaction',
    displayName: 'Dispute Transaction',
    actionType: 'GO_TO',
    description: 'Report fraudulent transaction',
    requiredEntities: [],
    validIntents: ['finance.fraud.alert'],
    priority: 1,
    urlTemplate: '{verificationUrl}'
  },
  view_credit_report: {
    actionId: 'view_credit_report',
    displayName: 'View Credit Report',
    actionType: 'GO_TO',
    description: 'View credit score and report',
    requiredEntities: [],
    validIntents: ['finance.credit.alert'],
    priority: 1,
    urlTemplate: '{reportUrl}'
  },
  schedule_payment: {
    actionId: 'schedule_payment',
    displayName: 'Schedule Payment',
    actionType: 'IN_APP',
    description: 'Schedule automatic payment',
    requiredEntities: ['amountDue', 'dueDate'],
    validIntents: ['finance.payment.reminder', 'billing.invoice.due'],
    priority: 2
  },
  view_portfolio: {
    actionId: 'view_portfolio',
    displayName: 'View Portfolio',
    actionType: 'GO_TO',
    description: 'View investment portfolio',
    requiredEntities: ['accountId'],
    validIntents: ['finance.investment.performance'],
    priority: 1,
    urlTemplate: '{portfolioUrl}'
  },
  verify_transaction: {
    actionId: 'verify_transaction',
    displayName: 'Verify Transaction',
    actionType: 'GO_TO',
    description: 'Verify suspicious transaction',
    requiredEntities: [],
    validIntents: ['finance.fraud.alert'],
    priority: 1,
    urlTemplate: '{verificationUrl}'
  },

  // NEW E-COMMERCE ACTIONS (for 7 new intents)
  track_return: {
    actionId: 'track_return',
    displayName: 'Track Return',
    actionType: 'GO_TO',
    description: 'Track return shipment status',
    requiredEntities: ['orderNumber'],
    validIntents: ['e-commerce.return.label', 'e-commerce.refund.processing'],
    priority: 1,
    urlTemplate: '{returnUrl}'
  },
  print_return_label: {
    actionId: 'print_return_label',
    displayName: 'Print Label',
    actionType: 'GO_TO',
    description: 'Print return shipping label',
    requiredEntities: ['orderNumber'],
    validIntents: ['e-commerce.return.label'],
    priority: 1,
    urlTemplate: '{labelUrl}'
  },
  view_refund_status: {
    actionId: 'view_refund_status',
    displayName: 'View Refund',
    actionType: 'GO_TO',
    description: 'View refund processing status',
    requiredEntities: ['refundAmount'],
    validIntents: ['e-commerce.refund.processing', 'finance.refund.processed'],
    priority: 1,
    urlTemplate: '{refundUrl}'
  },
  reorder_item: {
    actionId: 'reorder_item',
    displayName: 'Reorder',
    actionType: 'GO_TO',
    description: 'Reorder out-of-stock item',
    requiredEntities: ['productName'],
    validIntents: ['e-commerce.restock.alert', 'e-commerce.backorder.notification'],
    priority: 1,
    urlTemplate: '{productUrl}'
  },
  set_price_alert: {
    actionId: 'set_price_alert',
    displayName: 'Set Price Alert',
    actionType: 'IN_APP',
    description: 'Get notified of price changes',
    requiredEntities: ['productName'],
    validIntents: ['e-commerce.price.drop'],
    priority: 2
  },
  view_warranty: {
    actionId: 'view_warranty',
    displayName: 'View Warranty',
    actionType: 'GO_TO',
    description: 'View warranty details',
    requiredEntities: ['productName'],
    validIntents: ['e-commerce.warranty.expiring'],
    priority: 1,
    urlTemplate: '{extensionUrl}'
  },
  notify_restock: {
    actionId: 'notify_restock',
    displayName: 'Notify When Back',
    actionType: 'IN_APP',
    description: 'Get notified when item restocks',
    requiredEntities: ['productName'],
    validIntents: ['e-commerce.backorder.notification'],
    priority: 2
  },

  // NEW UTILITY & INFRASTRUCTURE ACTIONS
  view_outage_details: {
    actionId: 'view_outage_details',
    displayName: 'View Outage Info',
    actionType: 'GO_TO',
    description: 'View power outage details and affected areas',
    requiredEntities: [],
    validIntents: ['utility.service.alert'],
    priority: 1,
    urlTemplate: '{outageUrl}'
  },
  prepare_for_outage: {
    actionId: 'prepare_for_outage',
    displayName: 'View Preparation Tips',
    actionType: 'IN_APP',
    description: 'View tips to prepare for power outage',
    requiredEntities: [],
    validIntents: ['utility.service.alert'],
    priority: 2
  },
  set_outage_reminder: {
    actionId: 'set_outage_reminder',
    displayName: 'Set Reminder',
    actionType: 'IN_APP',
    description: 'Remind before planned outage',
    requiredEntities: ['outageStart'],
    validIntents: ['utility.service.alert'],
    priority: 3
  },

  // NEW E-COMMERCE DELIVERY SCHEDULING ACTIONS
  schedule_delivery_time: {
    actionId: 'schedule_delivery_time',
    displayName: 'Schedule Delivery',
    actionType: 'GO_TO',
    description: 'Choose delivery time window',
    requiredEntities: [],
    validIntents: ['e-commerce.delivery.schedule'],
    priority: 1,
    urlTemplate: '{schedulingUrl}'
  },

  // NEW REAL ESTATE ACTIONS
  view_property_listings: {
    actionId: 'view_property_listings',
    displayName: 'View Homes',
    actionType: 'GO_TO',
    description: 'View recommended property listings',
    requiredEntities: [],
    validIntents: ['real-estate.recommendation.listing'],
    priority: 1,
    urlTemplate: '{listingsUrl}'
  },
  save_properties: {
    actionId: 'save_properties',
    displayName: 'Save Favorites',
    actionType: 'GO_TO',
    description: 'Save properties to favorites',
    requiredEntities: [],
    validIntents: ['real-estate.recommendation.listing'],
    priority: 2,
    urlTemplate: '{listingsUrl}'
  },
  schedule_showing: {
    actionId: 'schedule_showing',
    displayName: 'Schedule Tour',
    actionType: 'GO_TO',
    description: 'Schedule property showing',
    requiredEntities: [],
    validIntents: ['real-estate.recommendation.listing'],
    priority: 2,
    urlTemplate: '{schedulingUrl}'
  },

  // NEW COMMUNITY & SOCIAL ACTIONS
  read_community_post: {
    actionId: 'read_community_post',
    displayName: 'Read Post',
    actionType: 'GO_TO',
    description: 'Read community post',
    requiredEntities: [],
    validIntents: ['community.post.notification'],
    priority: 1,
    urlTemplate: '{postUrl}'
  },
  view_post_comments: {
    actionId: 'view_post_comments',
    displayName: 'View Comments',
    actionType: 'GO_TO',
    description: 'Read post comments and discussion',
    requiredEntities: [],
    validIntents: ['community.post.notification'],
    priority: 2,
    urlTemplate: '{postUrl}'
  },
  reply_to_post: {
    actionId: 'reply_to_post',
    displayName: 'Reply',
    actionType: 'GO_TO',
    description: 'Reply to community post',
    requiredEntities: [],
    validIntents: ['community.post.notification'],
    priority: 3,
    urlTemplate: '{postUrl}'
  },

  // NEW EDUCATION ACTIVITY ACTIONS
  view_activity_details: {
    actionId: 'view_activity_details',
    displayName: 'View Activity',
    actionType: 'GO_TO',
    description: 'View educational activity details',
    requiredEntities: [],
    validIntents: ['education.activity.announcement'],
    priority: 1,
    urlTemplate: '{activityUrl}'
  },
  book_activity_tickets: {
    actionId: 'book_activity_tickets',
    displayName: 'Book Tickets',
    actionType: 'GO_TO',
    description: 'Book tickets for activity',
    requiredEntities: [],
    validIntents: ['education.activity.announcement'],
    priority: 2,
    urlTemplate: '{registrationUrl}'
  },
  add_activity_to_calendar: {
    actionId: 'add_activity_to_calendar',
    displayName: 'Add to Calendar',
    actionType: 'IN_APP',
    description: 'Add activity to calendar',
    requiredEntities: ['date'],
    validIntents: ['education.activity.announcement'],
    priority: 3,
    usesNativeIOS: true
  },

  // NEW CIVIC ACTIONS (for 6 new intents)
  register_to_vote: {
    actionId: 'register_to_vote',
    displayName: 'Register to Vote',
    actionType: 'GO_TO',
    description: 'Complete voter registration',
    requiredEntities: ['deadline'],
    validIntents: ['civic.voting.registration'],
    priority: 1,
    urlTemplate: '{registrationUrl}'
  },
  renew_license: {
    actionId: 'renew_license',
    displayName: 'Renew License',
    actionType: 'GO_TO',
    description: 'Renew driver license or ID',
    requiredEntities: ['expirationDate'],
    validIntents: ['civic.license.renewal'],
    priority: 1,
    urlTemplate: '{renewalUrl}'
  },
  pay_property_tax: {
    actionId: 'pay_property_tax',
    displayName: 'Pay Property Tax',
    actionType: 'GO_TO',
    description: 'Pay property tax bill',
    requiredEntities: ['amountDue'],
    validIntents: ['civic.tax.assessment'],
    priority: 1,
    urlTemplate: '{paymentUrl}'
  },
  apply_for_permit: {
    actionId: 'apply_for_permit',
    displayName: 'Apply for Permit',
    actionType: 'GO_TO',
    description: 'Apply for government permit',
    requiredEntities: ['permitType'],
    validIntents: ['civic.permit.application'],
    priority: 1,
    urlTemplate: '{applicationUrl}'
  },
  view_ballot: {
    actionId: 'view_ballot',
    displayName: 'View Ballot',
    actionType: 'GO_TO',
    description: 'View sample ballot and voting guide',
    requiredEntities: ['electionDate'],
    validIntents: ['civic.ballot.information'],
    priority: 1,
    urlTemplate: '{guideUrl}'
  },
  confirm_court_appearance: {
    actionId: 'confirm_court_appearance',
    displayName: 'Confirm Appearance',
    actionType: 'GO_TO',
    description: 'Confirm court appearance or jury duty',
    requiredEntities: ['dateTime'],
    validIntents: ['civic.court.notice', 'civic.appointment.summons'],
    priority: 1,
    urlTemplate: '{confirmationUrl}'
  },

  // NEW SUBSCRIPTION ACTIONS (for 5 new intents)
  upgrade_subscription: {
    actionId: 'upgrade_subscription',
    displayName: 'Upgrade Now',
    actionType: 'GO_TO',
    description: 'Upgrade subscription plan',
    requiredEntities: ['serviceName'],
    validIntents: ['subscription.upgrade.offer', 'subscription.trial.ending', 'subscription.usage.limit'],
    priority: 1,
    urlTemplate: '{upgradeUrl}'
  },
  cancel_subscription_service: {
    actionId: 'cancel_subscription_service',
    displayName: 'Cancel Service',
    actionType: 'GO_TO',
    description: 'Cancel subscription service',
    requiredEntities: ['serviceName'],
    validIntents: ['subscription.cancellation.confirmation', 'billing.subscription.renewal'],
    priority: 2,
    urlTemplate: '{cancellationUrl}'
  },
  view_usage: {
    actionId: 'view_usage',
    displayName: 'View Usage',
    actionType: 'GO_TO',
    description: 'View subscription usage details',
    requiredEntities: ['serviceName'],
    validIntents: ['subscription.usage.limit'],
    priority: 1,
    urlTemplate: '{usageUrl}'
  },
  extend_trial: {
    actionId: 'extend_trial',
    displayName: 'Extend Trial',
    actionType: 'GO_TO',
    description: 'Extend free trial period',
    requiredEntities: ['serviceName'],
    validIntents: ['subscription.trial.ending'],
    priority: 2,
    urlTemplate: '{extensionUrl}'
  },
  view_benefits: {
    actionId: 'view_benefits',
    displayName: 'View Benefits',
    actionType: 'IN_APP',
    description: 'View subscription benefits and rewards',
    requiredEntities: ['serviceName'],
    validIntents: ['subscription.anniversary'],
    priority: 1
  },

  // COMMUNICATION ACTIONS
  reply_to_thread: {
    actionId: 'reply_to_thread',
    displayName: 'Reply',
    actionType: 'IN_APP',
    description: 'Reply to email thread',
    requiredEntities: [],
    validIntents: ['communication.thread.reply', 'communication.professional.inquiry'],
    priority: 1
  },
  schedule_meeting: {
    actionId: 'schedule_meeting',
    displayName: 'Schedule Meeting',
    actionType: 'GO_TO',
    description: 'Schedule a meeting with sender',
    requiredEntities: [],
    validIntents: ['communication.introduction.connect', 'communication.professional.inquiry'],
    priority: 2,
    urlTemplate: '{calendarUrl}'
  },
  view_introduction: {
    actionId: 'view_introduction',
    displayName: 'View Introduction',
    actionType: 'IN_APP',
    description: 'View introduction details',
    requiredEntities: ['introducedPerson'],
    validIntents: ['communication.introduction.connect'],
    priority: 1
  },
  add_to_notes: {
    actionId: 'add_to_notes',
    displayName: 'Add to Notes',
    actionType: 'IN_APP',
    description: 'Save email content to iOS Notes app',
    requiredEntities: [],
    validIntents: ['communication.personal.self-note'],
    priority: 1,
    usesNativeIOS: true
  },

  // CAREER & RECRUITING ACTIONS
  schedule_interview: {
    actionId: 'schedule_interview',
    displayName: 'Schedule Interview',
    actionType: 'GO_TO',
    description: 'Schedule interview time',
    requiredEntities: ['company', 'position'],
    validIntents: ['career.interview.invitation'],
    priority: 1,
    urlTemplate: '{interviewUrl}'
  },
  accept_offer: {
    actionId: 'accept_offer',
    displayName: 'Accept Offer',
    actionType: 'GO_TO',
    description: 'Accept job offer',
    requiredEntities: ['company', 'position'],
    validIntents: ['career.job.offer'],
    priority: 1,
    urlTemplate: '{offerUrl}'
  },
  view_job_details: {
    actionId: 'view_job_details',
    displayName: 'View Job Details',
    actionType: 'GO_TO',
    description: 'View detailed job description',
    requiredEntities: [],
    validIntents: ['career.recruiter.outreach', 'career.job.offer', 'career.interview.invitation'],
    priority: 2,
    urlTemplate: '{jobUrl}'
  },
  check_application_status: {
    actionId: 'check_application_status',
    displayName: 'Check Status',
    actionType: 'GO_TO',
    description: 'Check application status',
    requiredEntities: ['company', 'position'],
    validIntents: ['career.application.status', 'career.rejection.notice'],
    priority: 1,
    urlTemplate: '{applicationUrl}'
  },
  view_onboarding_info: {
    actionId: 'view_onboarding_info',
    displayName: 'View Onboarding Info',
    actionType: 'IN_APP',
    description: 'View new hire onboarding information',
    requiredEntities: [],
    validIntents: ['career.onboarding.information'],
    priority: 1
  },

  // PROFESSIONAL SERVICES ACTIONS
  view_mortgage_details: {
    actionId: 'view_mortgage_details',
    displayName: 'View Mortgage Details',
    actionType: 'IN_APP',
    description: 'View mortgage or refinancing details',
    requiredEntities: [],
    validIntents: ['finance.mortgage.communication'],
    priority: 1
  },
  pay_utility_bill: {
    actionId: 'pay_utility_bill',
    displayName: 'Pay Bill',
    actionType: 'GO_TO',
    description: 'Pay utility bill online',
    requiredEntities: [],
    validIntents: ['finance.utility.bill'],
    priority: 1,
    urlTemplate: '{billUrl}'
  },
  view_legal_document: {
    actionId: 'view_legal_document',
    displayName: 'View Document',
    actionType: 'IN_APP',
    description: 'View legal document details',
    requiredEntities: [],
    validIntents: ['legal.document.communication'],
    priority: 1
  },
  schedule_inspection: {
    actionId: 'schedule_inspection',
    displayName: 'Schedule Inspection',
    actionType: 'GO_TO',
    description: 'Schedule real estate inspection',
    requiredEntities: [],
    validIntents: ['real-estate.service.communication'],
    priority: 1,
    urlTemplate: '{schedulingUrl}'
  },

  // SOCIAL & PLATFORM ACTIONS
  view_social_message: {
    actionId: 'view_social_message',
    displayName: 'View Message',
    actionType: 'GO_TO',
    description: 'View social platform message',
    requiredEntities: [],
    validIntents: ['social.notification.message'],
    priority: 1,
    urlTemplate: '{messageUrl}'
  },
  view_activity: {
    actionId: 'view_activity',
    displayName: 'View Activity',
    actionType: 'GO_TO',
    description: 'View fitness activity that received kudos',
    requiredEntities: [],
    validIntents: ['social.notification.kudos'],
    priority: 1,
    urlTemplate: '{activityUrl}'
  },
  reply_thanks: {
    actionId: 'reply_thanks',
    displayName: 'Say Thanks',
    actionType: 'IN_APP',
    description: 'Send quick thank you reply',
    requiredEntities: ['sender'],
    validIntents: ['social.notification.kudos'],
    priority: 2
  },
  share_achievement: {
    actionId: 'share_achievement',
    displayName: 'Share Activity',
    actionType: 'GO_TO',
    description: 'Share fitness achievement on social media',
    requiredEntities: [],
    validIntents: ['social.notification.kudos'],
    priority: 3,
    urlTemplate: '{activityUrl}'
  },
  verify_social_account: {
    actionId: 'verify_social_account',
    displayName: 'Verify Account',
    actionType: 'GO_TO',
    description: 'Verify social platform account',
    requiredEntities: ['platform'],
    validIntents: ['social.verification.required'],
    priority: 1,
    urlTemplate: '{verificationLink}'
  },
  accept_social_invitation: {
    actionId: 'accept_social_invitation',
    displayName: 'Accept Invitation',
    actionType: 'GO_TO',
    description: 'Accept social platform invitation',
    requiredEntities: [],
    validIntents: ['social.invitation.request'],
    priority: 1,
    urlTemplate: '{invitationLink}'
  },

  // THREAD FINDER ACTIONS - For link-heavy emails with extracted content
  view_extracted_content: {
    actionId: 'view_extracted_content',
    displayName: 'View Extracted Content',
    actionType: 'IN_APP',
    description: 'View automatically extracted data from link (Thread Finder)',
    requiredEntities: ['extractedContent'],
    validIntents: [
      'education.lms.link-only',
      'education.school-portal.link-only',
      'youth.sports.link-only'
    ],
    priority: 1
  },
  open_original_link: {
    actionId: 'open_original_link',
    displayName: 'Open Original Link',
    actionType: 'GO_TO',
    description: 'Open the original link in browser',
    requiredEntities: ['link'],
    validIntents: [
      'education.lms.link-only',
      'education.school-portal.link-only',
      'youth.sports.link-only'
    ],
    priority: 2,
    urlTemplate: '{link}'
  },
  schedule_extraction_retry: {
    actionId: 'schedule_extraction_retry',
    displayName: 'Retry Extraction',
    actionType: 'IN_APP',
    description: 'Retry automatic data extraction (Thread Finder)',
    requiredEntities: ['link'],
    validIntents: [
      'education.lms.link-only',
      'education.school-portal.link-only',
      'youth.sports.link-only'
    ],
    priority: 3
  },
  download_attachment: {
    actionId: 'download_attachment',
    displayName: 'Download Attachment',
    actionType: 'GO_TO',
    description: 'Download assignment attachment (PDF, worksheet, rubric)',
    requiredEntities: ['extractedContent'],
    optionalEntities: ['attachmentIndex'],
    validIntents: [
      'education.lms.link-only',
      'education.school-portal.link-only',
      'youth.sports.link-only'
    ],
    priority: 2,
    urlTemplate: '{extractedContent.attachments[0]}'
  },

  // GENERIC ACTIONS
  open_link: {
    actionId: 'open_link',
    displayName: 'Open Link',
    actionType: 'GO_TO',
    description: 'Open URL in browser',
    requiredEntities: ['url'],
    validIntents: [], // Available for all intents
    priority: 4
  },
  view_newsletter_summary: {
    actionId: 'view_newsletter_summary',
    displayName: 'View Summary',
    actionType: 'IN_APP',
    description: 'View AI-generated newsletter summary with key links',
    requiredEntities: [],
    validIntents: [
      'generic.newsletter.content',
      'content.newsletter.sports',
      'content.newsletter.gaming',
      'content.newsletter.entertainment',
      'content.newsletter.career',
      'content.newsletter.tech',
      'content.newsletter.finance',
      'content.newsletter.lifestyle'
    ],
    priority: 1
  },
  quick_reply: {
    actionId: 'quick_reply',
    displayName: 'Quick Reply',
    actionType: 'IN_APP',
    description: 'Send quick reply',
    requiredEntities: [],
    validIntents: [], // Available for all intents
    priority: 5
  },
  save_for_later: {
    actionId: 'save_for_later',
    displayName: 'Save for Later',
    actionType: 'IN_APP',
    description: 'Archive for later review',
    requiredEntities: [],
    validIntents: [], // Available for all intents
    priority: 5  // Fixed from 6 to match iOS contract (1-5 range)
  },
  view_details: {
    actionId: 'view_details',
    displayName: 'View Details',
    actionType: 'IN_APP',
    description: 'View full email details',
    requiredEntities: [],
    validIntents: [], // Available for all intents
    priority: 5  // Fixed from 7 to match iOS contract (1-5 range)
  }
};

/**
 * Get action definition by ID
 * @param {string} actionId - The unique action identifier (e.g., 'track_package')
 * @returns {Object|null} Action object with metadata, or null if not found
 * @property {string} actionId - Unique identifier
 * @property {string} displayName - Human-readable action name
 * @property {string} actionType - Either 'GO_TO' or 'IN_APP'
 * @property {string} description - Action description
 * @property {Array<string>} requiredEntities - Required entity names
 * @property {Array<string>} validIntents - Intent IDs this action applies to
 * @property {number} priority - Action priority (lower = higher priority)
 * @example
 * const action = getAction('track_package');
 * // Returns: { actionId: 'track_package', displayName: 'Track Package', actionType: 'GO_TO', ... }
 */
function getAction(actionId) {
  if (!actionId || typeof actionId !== 'string') {
    return null;
  }
  return ActionCatalog[actionId] || null;
}

/**
 * Get all actions valid for a specific intent
 * @param {string} intentId - Intent identifier (e.g., 'e-commerce.shipping.notification')
 * @returns {Array<Object>} Array of action objects, sorted by priority
 * @example
 * const actions = getActionsForIntent('e-commerce.shipping.notification');
 * // Returns: [{ actionId: 'track_package', ... }, { actionId: 'view_order', ... }]
 */
function getActionsForIntent(intentId) {
  return Object.values(ActionCatalog)
    .filter(action => 
      action.validIntents.includes(intentId) || 
      action.validIntents.length === 0 // Generic actions
    )
    .sort((a, b) => a.priority - b.priority);
}

/**
 * Check if an action can be executed with given entities
 * @param {Object} action - Action object from catalog
 * @param {Object} entities - Extracted entities from email
 * @returns {boolean} True if all required entities are available
 * @example
 * const action = getAction('track_package');
 * const entities = { trackingNumber: '1Z999...', carrier: 'UPS' };
 * const canExecute = canExecuteAction(action, entities); // true
 */
function canExecuteAction(action, entities) {
  if (!action || !action.requiredEntities || action.requiredEntities.length === 0) {
    return true;
  }
  
  return action.requiredEntities.every(entityName => 
    entities[entityName] !== undefined && entities[entityName] !== null
  );
}

/**
 * Get all action IDs from catalog
 * @returns {Array<string>} Array of all action identifiers
 * @example
 * const allActions = getAllActionIds();
 * // Returns: ['track_package', 'view_order', 'pay_invoice', ...]
 */
function getAllActionIds() {
  return Object.keys(ActionCatalog);
}

module.exports = {
  ActionCatalog,
  getAction,
  getActionsForIntent,
  canExecuteAction,
  getAllActionIds
};

